public class GroupNoteController {
	public static String groupNoteQueryString =
		'SELECT Id, Meeting__c, Meeting_Name__c, Name, Status__c, OwnerId, Attendance_Tracking__c,' +
		' Did_Group_Meet__c, Brief_Narrative_Summary__c, Attending_Staffmembers__c,' +
		' Staff_Attended__c, Reason_Group_Did_Not_Meet__c, Patient_Specific_Concerns_and_Follow_up__c,' +
		' Finalized_Datetime__c,Finalized_By__c, Finalized_By__r.Name, Finalized_By_Professional_Name__c,' +
		' Meeting__r.Start_Date_Time__c,' +
		' Meeting__r.Group_Membership__c, Meeting__r.Group_Membership__r.Name, Meeting__r.Group_Membership__r.Attendance_Tracking__c,' +
		' Meeting__r.Patient_Account__c, Meeting__r.Patient_Account__r.Name, Meeting__r.Patient_Account__r.Patient_Contact__r.LastName,' +
		' TYPEOF Owner' +
		' WHEN User THEN Id, Name, Professional_Name__c' +
		' END';

	public static String groupAttendanceQueryString = 'SELECT Id, Name,Patient__r.Name, Patient__r.Patient_Contact__r.LastName,' + ' Patient__c, Attended__c, Role__c';
	public static String participantQueryString = 'SELECT Id, Contact__c, Contact__r.LastName, Contact__r.Distinguished_Name__c,' + ' Contact__r.AccountId, Group__c, Group__r.Name';

	static GroupNoteWrapper queryGroupNote(Id meetingId, Boolean queryParticipants, Boolean queryAttendance) {
		GroupNoteWrapper returnGroupNoteWrapper = new GroupNoteWrapper();
		returnGroupNoteWrapper.theNote = new Group_Note__c(Meeting__c = meetingId);

		if (meetingId != null) {
			String queryString = groupNoteQueryString;
			if (queryAttendance) {
				queryString += ',(' + groupAttendanceQueryString + ' FROM Group_Attendance__r )';
			}
			queryString += ' FROM Group_Note__c WHERE Meeting__c = \'' + meetingId + '\'';

			List<Group_Note__c> groupNotes = (List<Group_Note__c>) Database.query(queryString);
			if (!groupNotes.isEmpty()) {
				returnGroupNoteWrapper.theNote = groupNotes[0];
				returnGroupNoteWrapper.groupName = groupNotes[0].Meeting__r.Group_Membership__r.Name;
				returnGroupNoteWrapper.meetingDateTimeString = groupNotes[0].Meeting__r.Start_Date_Time__c.format('E M/d/yy hh:mm a');
			} else {
				//no existing group note
				Meeting__c theMeeting = [SELECT Id, Group_Membership__c, Group_Membership__r.Name, Start_Date_Time__c FROM Meeting__c WHERE Id = :meetingId];
				returnGroupNoteWrapper.groupName = (theMeeting.Group_Membership__c != null) ? theMeeting.Group_Membership__r.Name : '[n/a]';
				returnGroupNoteWrapper.meetingDateTimeString = theMeeting.Start_Date_Time__c.format('E M/d/yy hh:mm a');
			}

			if (queryParticipants) {
				queryString = participantQueryString + ' FROM Participant__c' + ' WHERE Meeting__c = :meetingId' + ' ORDER BY Contact__r.LastName ASC NULLS LAST';
			}
			returnGroupNoteWrapper.participants = (List<Participant__c>) Database.query(queryString);
		}

		return returnGroupNoteWrapper;
	}

	@AuraEnabled
	public static User getUser() {
		return [SELECT Id, Name, Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()];
	}

	@AuraEnabled
	@testVisible
	public static GroupNoteWrapper getGroupNote(String recordId) {
		Id meetingId = recordId; //assume we received a record Id first
		List<Group_Note__c> groupNotes = [SELECT Id, Meeting__c FROM Group_Note__c WHERE Id = :recordId LIMIT 1];
		if (
			groupNotes.size() > 0 //if this is a group Note Id
		) {
			meetingId = groupNotes[0].Meeting__c;
		}
		return getMeetingGroupNote(meetingId);
	}

	// @AuraEnabled
	// public
	@testVisible
	static GroupNoteWrapper getMeetingGroupNote(String meetingId) {
		GroupNoteWrapper returnWrapper = new GroupNoteWrapper();

		if (String.isNotBlank(meetingId)) {
			returnWrapper = queryGroupNote(meetingId, true, true);

			if (returnWrapper.theNote != null) {
				returnWrapper.lstGroupAttendance = new List<GroupAttendanceWrapper>();

				if (returnWrapper.theNote.Status__c != 'Finalized') {
					//group and patient participants
					Set<Id> groupIds = new Set<Id>();
					Set<Id> patientIds = new Set<Id>();
					Map<Id, GroupAttendanceWrapper> patientId2GroupAttendanceWrapperMap = new Map<Id, GroupAttendanceWrapper>();

					groupIds.add(returnWrapper.theNote.Meeting__r.Group_Membership__c);
					for (Participant__c parti : returnWrapper.participants) {
						if (parti.Contact__c != null) {
							patientIds.add(parti.Contact__r.AccountId);
							GroupAttendanceWrapper newWrap = new GroupAttendanceWrapper(parti);
							patientId2GroupAttendanceWrapperMap.put(parti.Contact__r.AccountId, newWrap);
						}
						groupIds.add(parti.Group__c);
					}

					//members for these groups
					Map<Id, Patient_Group_Member__c> patientId2groupMemberMap = new Map<Id, Patient_Group_Member__c>();
					List<Patient_Group_Member__c> patientGroupMembers = [SELECT Id, Group_Name__c, Patient__c, Patient__r.LastName, Patient__r.FirstName, Patient__r.Distinguished_Name__c, Patient__r.AccountId, Role__c FROM Patient_Group_Member__c WHERE Group_Name__c IN :groupIds AND (Planned_End_Date__c >= :System.today() OR Planned_End_Date__c = NULL) ORDER BY Start_Date__c ASC];

					for (Patient_Group_Member__c patientGroupMember : patientGroupMembers) {
						patientId2groupMemberMap.put(patientGroupMember.Patient__r.AccountId, patientGroupMember);
						patientIds.add(patientGroupMember.Patient__r.AccountId);
					}

					Map<Id, GroupAttendanceWrapper> gattWrappersMap = new Map<Id, GroupAttendanceWrapper>();
					//existing attendance
					for (Group_Attendance__c gatt : returnWrapper.theNote.Group_Attendance__r) {
						patientIds.remove(gatt.Patient__c);
						gattWrappersMap.put(gatt.Patient__c, new GroupAttendanceWrapper(gatt));
						//returnWrapper.lstGroupAttendance.add(new GroupAttendanceWrapper(gatt));
					}

					//any patients missing
					if (!patientIds.isEmpty()) {
						Map<Id, Account> patientMap = new Map<Id, Account>([SELECT Id, Name, Patient_Contact__c, Patient_Contact__r.LastName FROM Account WHERE Id IN :patientIds]);

						//add new attendance for missing patients
						for (Id patientId : patientIds) {
							GroupAttendanceWrapper newWrap = new GroupAttendanceWrapper(patientMap.get(patientId), patientId2groupMemberMap.get(patientId));
							//returnWrapper.lstGroupAttendance.add(newWrap);
							gattWrappersMap.put(patientId, newWrap);
						}
					}

					for (Account patientAcc : [SELECT Id FROM Account WHERE Id IN :gattWrappersMap.keySet() ORDER BY Patient_Contact__r.LastName ASC, Patient_Contact__r.FirstName ASC]) {
						returnWrapper.lstGroupAttendance.add(gattWrappersMap.get(patientAcc.Id));
					}
				} else {
					for (Group_Attendance__c ga : returnWrapper.theNote.Group_Attendance__r) {
						// if (ga.Attended__c)
						// {
						returnWrapper.lstGroupAttendance.add(new GroupAttendanceWrapper(ga));
						// }
					}
				}
			}
		}

		return returnWrapper;
	}

	@AuraEnabled
	public static Group_Note__c updateGroupNote(string objGroupNoteJson, string lstGroupAttendanceJson) {
		set<id> groupAttendanceToDeleteIds = new Set<id>();
		set<id> queryPatientIds = new Set<id>();
		set<id> upsertedPatientIds = new Set<id>();

		Group_Note__c objGroupNote = (Group_Note__c) JSON.deserialize(objGroupNoteJson, Group_Note__c.class);
		Group_Attendance__c[] lstGroupAttendance = (Group_Attendance__c[]) JSON.deserialize(lstGroupAttendanceJson, Group_Attendance__c[].class);

		upsert objGroupNote;
		Map<Id, Id> mapPatientIdtoGAId = new Map<Id, Id>();
		Group_Note__c objGroupNoteNew = [
			SELECT
				Id,
				Name,
				Staff_Attended__c,
				Attendance_Tracking__c,
				Reason_Group_Did_Not_Meet__c,
				Patient_Specific_Concerns_and_Follow_up__c,
				OwnerId,
				TYPEOF Owner
					WHEN User THEN Id, Name, Professional_Name__c
				END,
				Finalized_Datetime__c,
				Finalized_By__c,
				Finalized_By__r.Name,
				Finalized_By_Professional_Name__c,
				Did_Group_Meet__c,
				Brief_Narrative_Summary__c,
				Attending_Staffmembers__c,
				Status__c,
				Meeting__c,
				Meeting__r.Group_Membership__c,
				(SELECT Id, Name, Patient__r.Name, Patient__r.Patient_Contact__r.LastName, Patient__c, Attended__c, Role__c, Patient__r.Patient_LastName__c FROM Group_Attendance__r ORDER BY Patient__r.Name ASC NULLS LAST)
			FROM Group_Note__c
			WHERE Id = :objGroupNote.Id
		];

		for (Group_Attendance__c objGA : objGroupNoteNew.Group_Attendance__r) {
			mapPatientIdtoGAId.put(objGA.Patient__c, objGA.Id);
			queryPatientIds.add(objGA.Patient__c);
		}

		// if(String.isNotBlank(String.ValueOf(objGroupNoteNew.Meeting__c)))
		// {
		// attTracking = [SELECT Id, Attendance_Tracking__c
		//                 FROM Group__c
		//                 WHERE Id =: objGroupNoteNew.Meeting__r.Group_Membership__c][0].Attendance_Tracking__c;

		// }

		String attTracking = objGroupNoteNew.Attendance_Tracking__c;
		set<id> paramPatientIds = new Set<id>();

		List<Group_Attendance__c> lstGroupAttendanceNew = new List<Group_Attendance__c>();
		for (Group_Attendance__c ga : lstGroupAttendance) {
			paramPatientIds.add(ga.Patient__c);
			if (ga.Group_Note__c == null) {
				ga.Group_Note__c = objGroupNote.Id;
				if (mapPatientIdtoGAId.containsKey(ga.Patient__c)) {
					ga.id = mapPatientIdtoGAId.get(ga.Patient__c);
				}
			}
			if (attTracking == 'Track Attendance') {
				// if(ga.Attended__c){
				lstGroupAttendanceNew.add(ga);
				// }
			}
		}
		// Boolean includeAttendedOnly = (objGroupNoteNew.Status__c = 'Finalized' ? true : false);
		// for (Group_Attendance__c ga : objGroupNoteNew.Group_Attendance__r)
		// {
		//     if ((includeAttendedOnly && ga.Attended__c) || !includeAttendedOnly)
		//     {
		//         lstGroupAttendanceNew.add(ga);
		//     }
		// }

		// if(attTracking != 'Do not Track Attendance'){
		upsert lstGroupAttendanceNew;
		// for( Group_Attendance__c ga : lstGroupAttendanceNew ){
		//     upsertedPatientIds.add(ga.Patient__c);
		// }
		// }
		objGroupNoteNew = [
			SELECT
				Id,
				Meeting__c,
				Meeting__r.Group_Membership__c,
				Name,
				Staff_Attended__c,
				Reason_Group_Did_Not_Meet__c,
				Patient_Specific_Concerns_and_Follow_up__c,
				OwnerId,
				TYPEOF Owner
					WHEN User THEN Id, Name
				END,
				Finalized_Datetime__c,
				Finalized_By__c,
				Finalized_By__r.Name,
				Did_Group_Meet__c,
				Brief_Narrative_Summary__c,
				Attending_Staffmembers__c,
				Status__c,
				(SELECT Id, Name, Patient__r.Name, Patient__r.Patient_Contact__r.LastName, Patient__c, Attended__c, Role__c, Patient__r.Patient_LastName__c FROM Group_Attendance__r ORDER BY Patient__r.Name ASC NULLS LAST)
			FROM Group_Note__c
			WHERE Id = :objGroupNote.Id
		];

		// lstGroupAttendanceNew = new List<Group_Attendance__c>();
		// objGroupNoteNew.lstGroupAttendance = new List<GroupAttendanceWrapper>();
		// Boolean includeAttendedOnly = (objGroupNoteNew.Status__c == 'Finalized' ? true : false);
		// for (Group_Attendance__c ga : objGroupNoteNew.Group_Attendance__r)
		// {
		//     if(!upsertedPatientIds.contains(ga.Patient__c))
		//     {
		//         groupAttendanceToDeleteIds.add(ga.Id);
		//     } else if ((includeAttendedOnly && ga.Attended__c) || !includeAttendedOnly)
		//     {
		//         lstGroupAttendanceNew.add(ga);
		//         objGroupNoteNew.lstGroupAttendance.add(new GroupAttendanceWrapper(ga));
		//     }
		// }

		// objGroupNoteNew.lstGroupAttendance = lstGroupAttendanceNew;
		// for(Group_Attendance__c ga : objGroupNoteNew.Group_Attendance__r){
		//     //groupAttendanceToDeleteIds
		//     if(!upsertedPatientIds.contains(ga.Patient__c)){
		//         groupAttendanceToDeleteIds.add(ga.Id);
		//     }
		// }

		if (groupAttendanceToDeleteIds.size() > 0) {
			database.delete(new List<id>(groupAttendanceToDeleteIds));
		}

		return objGroupNoteNew;
	}

	@AuraEnabled
	public static Group_Note__c finalizeGroupNoteApex(String objGroupNoteString, string lstGroupAttendanceString) {
		Group_Note__c objGroupNote = (Group_Note__c) JSON.deserialize(objGroupNoteString, Group_Note__c.class);
		objGroupNote.Finalized_by__c = Userinfo.getUserId();
		objGroupNote.Finalized_By_Professional_Name__c = [SELECT Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()].Professional_Name__c;
		objGroupNote.Finalized_Datetime__c = System.now();
		objGroupNote.Status__c = 'Finalized';

		return updateGroupNote(JSON.serialize(objGroupNote), lstGroupAttendanceString);
		// upsert objGroupNote;
		// return objGroupNote;
	}

	@AuraEnabled
	public static String getAttendanceTracking(String groupMembershipId) {
		String trackingId = '';
		if (!String.isBlank(groupMembershipId)) {
			trackingId = [SELECT Id, Attendance_Tracking__c FROM Group__c WHERE id = :groupMembershipId][0].Attendance_Tracking__c;
		}
		return trackingId;
	}

	public class GroupNoteWrapper {
		@AuraEnabled
		public Group_Note__c theNote;
		@AuraEnabled
		public String groupName;
		@AuraEnabled
		public String meetingDateTimeString;

		@AuraEnabled
		public List<GroupAttendanceWrapper> lstGroupAttendance = new List<GroupAttendanceWrapper>();

		public List<Participant__c> participants = new List<Participant__c>();

		public GroupNoteWrapper() {
		}
	}

	public class GroupAttendanceWrapper {
		@AuraEnabled
		public Group_Attendance__c gatt;
		@AuraEnabled
		public String fullName;
		@AuraEnabled
		public String lastName;
		@AuraEnabled
		public String Id;

		public GroupAttendanceWrapper() {
		}

		//based on just patient participant
		public GroupAttendanceWrapper(Participant__c parti) {
			Group_Attendance__c newGatt = new Group_Attendance__c(Patient__c = parti.Contact__r.AccountId, Attended__c = false, Role__c = 'No Role');
			this.gatt = newGatt;

			this.lastName = parti.Contact__r.LastName;
			this.fullName = parti.Contact__r.Distinguished_Name__c;
		}
		//existing group attendance from database
		public GroupAttendanceWrapper(Group_Attendance__c gatt) {
			this.gatt = gatt;
			this.lastName = gatt.Patient__r.Patient_Contact__r.LastName;
			this.fullName = gatt.Patient__r.Name;
		}
		//based on group membership only, no patient participant or group attendance exists
		public GroupAttendanceWrapper(Account patient, Patient_Group_Member__c groupMember) {
			Group_Attendance__c newGatt = new Group_Attendance__c(Patient__c = patient.Id, Attended__c = false);

			if (groupMember != null) {
				newGatt.Role__c = groupMember.Role__c;
			}

			this.gatt = newGatt;

			this.lastName = patient.Patient_Contact__r.LastName;
			this.fullName = patient.Name;
		}
	}
}
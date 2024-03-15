public class EditMeetingCtl {
	public static Map<String, Schema.RecordTypeInfo> recordTypeInfoByNameMap = Schema.SObjectType.Participant__c.getRecordTypeInfosByName();

	@TestVisible
	static Map<String, String> recurrenceType2SuccessMessage = new Map<String, String>{ 'single-delete' => 'The meeting has been removed from all schedules.', 'series-delete' => 'These meetings have been removed from all schedules.', 'single-save' => 'The meeting has been updated.', 'series-save' => 'The meeting details were saved; please refresh in a few minutes to see them.' };

	@AuraEnabled
	public static Response saveMeeting(String meeting) {
		String recurrenceSelected = 'single';
		Response response = new Response();
		Savepoint sp = Database.setSavepoint();
		try {
			MeetingRequest meetingRequest = (MeetingRequest) JSON.deserialize(meeting, MeetingRequest.class);
			recurrenceSelected = meetingRequest.recurrenceSelected;

			Meeting__c updatedMeeting;
			if (meetingRequest.meetingId == null) {
				updatedMeeting = saveMeetingRequest(meetingRequest, false);
			} else {
				updatedMeeting = saveMeetingRequest(meetingRequest, true);
			}
		} catch (Exception ex) {
			Database.rollback(sp);

			response.responseType = 'error';
			response.title = 'Error';
			response.message = ex.getMessage() + ': ' + ex.getStackTraceString();
			return response;
		}

		response.responseType = 'success';
		response.title = 'Success';
		response.message = recurrenceType2SuccessMessage.get(recurrenceSelected + '-save');
		//response.mtg = updatedMeeting;
		return response;
	}

	@AuraEnabled
	public static MeetingResponse loadMeeting_Ctl(String recordId) {
		return loadMeeting_Ctl(recordId, '');
	}

	@AuraEnabled
	public static MeetingResponse loadMeeting_Ctl(String recordId, String patientId) {
		List<ParticipantGroup> participantGroupList = new List<ParticipantGroup>();
		List<ParticipantResponse> userParticipantList = new List<ParticipantResponse>();
		List<ParticipantResponse> contactParticipantList = new List<ParticipantResponse>();
		List<ParticipantResponse> groupParticipantList = new List<ParticipantResponse>();

		Meeting__c mtg = new Meeting__c();
		Map<String, String> selectedOwnerMap = new Map<String, String>();
		Map<String, String> selectedPatientMap = new Map<String, String>();
		selectedOwnerMap.put('value', Userinfo.getUserId());
		selectedOwnerMap.put('label', Userinfo.getName());
		if (!String.isBlank(recordId)) {
			mtg = queryMeeting(recordId, true);
			selectedOwnerMap.put('value', mtg.OwnerId);
			selectedOwnerMap.put('label', mtg.Owner.Name);

			for (Participant__c participant : mtg.Participants__r) {
				ParticipantResponse participantResponse = new ParticipantResponse();
				if (participant.RecordTypeId == recordTypeInfoByNameMap.get('User Participant').getRecordTypeId()) {
					participantResponse.label = participant.User__r.Name;
					participantResponse.name = participant.User__r.Id;
					userParticipantList.add(participantResponse);
				}

				if (participant.RecordTypeId == recordTypeInfoByNameMap.get('Contact Participant').getRecordTypeId()) {
					participantResponse.label = participant.Contact__r.Name;
					participantResponse.name = participant.Contact__r.Id;
					contactParticipantList.add(participantResponse);
				}

				if (participant.RecordTypeId == recordTypeInfoByNameMap.get('Group Participant').getRecordTypeId()) {
					participantResponse.label = participant.Group__r.Name;
					participantResponse.name = participant.Group__r.Id;
					groupParticipantList.add(participantResponse);
				}
			}
		} else if (!String.isBlank(patientId)) {
			List<Account> patients = [SELECT Id, Name FROM Account WHERE Id = :patientId];
			if (!patients.isEmpty()) {
				selectedPatientMap.put('value', patients[0].Id);
				selectedPatientMap.put('label', patients[0].Name);
				mtg.Patient_Account__c = patients[0].Id;
				mtg.Meeting_Focus__c = 'Patient';
			}
		}

		ParticipantGroup userParticipantGroup = new ParticipantGroup();
		userParticipantGroup.groupType = 'User';
		userParticipantGroup.participants = userParticipantList;
		participantGroupList.add(userParticipantGroup);

		ParticipantGroup contactParticipantGroup = new ParticipantGroup();
		contactParticipantGroup.groupType = 'Contact';
		contactParticipantGroup.participants = contactParticipantList;
		participantGroupList.add(contactParticipantGroup);

		ParticipantGroup groupParticipantGroup = new ParticipantGroup();
		groupParticipantGroup.groupType = 'Group';
		groupParticipantGroup.participants = groupParticipantList;
		participantGroupList.add(groupParticipantGroup);

		MeetingResponse meetingResponse = new MeetingResponse();
		meetingResponse.mtg = mtg;
		meetingResponse.participantGroupList = participantGroupList;

		meetingResponse.meetingTypeMap = getMeetingTypes(mtg.Meeting_Focus__c, mtg.Meeting_Type__c);
		meetingResponse.selectedOwner = selectedOwnerMap;
		meetingResponse.selectedPatient = selectedPatientMap;
		if (mtg.Recurrence__c != null) {
			meetingResponse.recurrenceRecord = queryRecurrence(mtg.Recurrence__c);
		}

		Boolean isOwner = mtg.OwnerId == UserInfo.getUserId();
		Boolean hasScheduleManagerPermission = FeatureManagement.checkPermission('ScheduleManager');

		meetingResponse.canEdit = isOwner || hasScheduleManagerPermission;
		return meetingResponse;
	}

	@AuraEnabled
	public static Response deleteMeeting(String meetingId, String recurrenceType) {
		system.assertNotEquals(null, recurrenceType, 'Did not receive value for recurrenceType in deleteMeeting call');
		String deleteResult = Scheduling.deleteMeeting((Id) meetingId, recurrenceType);

		Response response = new Response();

		response.responseType = 'error';
		response.title = 'Error';
		response.message = deleteResult;

		if (deleteResult == 'success') {
			response.responseType = 'success';
			response.title = 'Meeting Deleted';
			response.message = recurrenceType2SuccessMessage.get(recurrenceType + '-delete');
		}

		return response;
	}

	private static Meeting__c queryMeeting(Id mtgId, Boolean includeParticipants) {
		String meetingQueryString =
			'SELECT Id, Start_Date_Time__c, End_Date_Time__c, Subject__c, OwnerId, Owner.Id, Owner.Name,' +
			' Room_Resource__c, Room_Resource__r.Id, Room_Resource__r.Name, Description__c, Recurrence__c, Patient_Account__c, Patient_Account__r.Name,' +
			' Group_Membership__c, Group_Membership__r.Name, Meeting_Focus__c, Patient_Attendance__c,' +
			' Meeting_Type__c, Patient_Meeting_Type__c, Patient_Group_Meeting_Type__c, Staff_Group_Meeting_Type__c, Other_Meeting_Type__c,' +
			' All_Day_Meeting__c, All_Day_Date__c, Monthly_Note__c, Monthly_Note_Finalized__c, Videoconference_Link__c';
		if (includeParticipants) {
			meetingQueryString += ', (SELECT Id, User__r.Id, User__r.Name, Contact__r.Id, Contact__r.Name, Group__r.Id, Group__r.Name, RecordTypeId' + ' FROM Participants__r)';
		}
		meetingQueryString += ' FROM Meeting__c' + ' WHERE Id = \'' + mtgId + '\'';

		return Database.query(meetingQueryString);
	}

	private static Recurrence__c queryRecurrence(Id recurrenceId) {
		String recurrenceQueryString = RecurringMeetings.recurrenceQueryString;
		// String recurrenceQueryString = 'SELECT Id, Recurrence_Pattern__c, Recur_every__c, Weekdays__c, Start_Date__c, End_By__c, End_Type__c,'
		// 		+ ' Number_of_Occurrences__c, Daily_Option__c, Monthly_Day_Number__c, Yearly_Month__c, Yearly_Day_Number__c,'
		//         + ' Excluded_Dates__c, Month_Number__c, Monthly_Day_of_Week__c, Monthly_Day_of_Week_Ordinal__c, Monthly_Day_Type__c';
		recurrenceQueryString += ' WHERE Id = \'' + recurrenceId + '\'';

		return Database.query(recurrenceQueryString);
	}

	private static Meeting__c saveMeetingRequest(MeetingRequest meetingRequest, Boolean isUpdate) {
		Recurrence__c recurrence = null;
		if (meetingRequest.recurrence != null) {
			//recurrence = new Recurrence__c();
			recurrence = meetingRequest.recurrenceRecord;
			// if(meetingRequest.recurrence.recurrenceId != null)
			// {
			// 	recurrence.Id = meetingRequest.recurrence.recurrenceId;
			// }

			if (meetingRequest.recurrenceSelected == 'series' || String.isEmpty(meetingRequest.recurrenceSelected)) {
				//recurrence.OwnerId = meetingRequest.recurrence.ownerId;
				recurrence.Recurrence_Pattern__c = meetingRequest.recurrence.recurrencePattern;
				recurrence.Recur_every__c = meetingRequest.recurrence.recurEvery;
				recurrence.Weekdays__c = meetingRequest.recurrence.weekdays;
				recurrence.All_Day_Meeting__C = (meetingRequest.recurrence.allDayMeeting == null ? false : meetingRequest.recurrence.allDayMeeting);
				recurrence.All_Day_Date__C = meetingRequest.recurrence.allDayDate;
				recurrence.Start_Date__c = meetingRequest.recurrence.startDate;
				recurrence.End_By__c = meetingRequest.recurrence.endDate;
				recurrence.End_Type__c = meetingRequest.recurrence.endType;
				recurrence.Number_of_Occurrences__c = meetingRequest.recurrence.numberOfOccurrences;
				recurrence.Daily_Option__c = meetingRequest.recurrence.dailyOption;
				recurrence.Monthly_Day_Number__c = meetingRequest.recurrence.monthlyDayNumber;
				recurrence.Yearly_Month__c = meetingRequest.recurrence.yearlyMonth;
				recurrence.Yearly_Day_Number__c = meetingRequest.recurrence.yearlyDayNumber;
			}

			//added 190723 JN
			if (recurrence.Start_Date__c == null) {
				recurrence.Start_Date__c = meetingRequest.mtg.Start_Date_Time__c.dateGMT();
			}
			upsert recurrence;
		}

		// Meeting__c meeting = new Meeting__c();
		// if(isUpdate)
		// {
		// 	meeting.Id = meetingRequest.meetingId;
		// }
		// meeting.Start_Date_Time__c = meetingRequest.startDateTime;
		// meeting.End_Date_Time__c = meetingRequest.endDateTime;
		// meeting.Subject__c = meetingRequest.subject;
		// meeting.OwnerId = meetingRequest.staffOwnerId;
		// meeting.Room_Resource__c = meetingRequest.schedulingResourceId;
		// meeting.Description__c = meetingRequest.description;
		Meeting__c meeting = meetingRequest.mtg;

		if (meetingRequest.recurrence != null && meetingRequest.recurrence.recurrenceId == null && recurrence != null) {
			meeting.Recurrence__c = recurrence.Id;
		}

		if (meeting.Meeting_Focus__c == 'Patient') {
			meeting.Group_Membership__c = null;
		} else if (meeting.Meeting_Focus__c == 'Other') {
			meeting.Group_Membership__c = null;
			meeting.Patient_Account__c = null;
		} else if (meeting.Meeting_Focus__c == 'Staff Group') {
			// do nothing
		} else {
			meeting.Patient_Account__c = null;
		}

		if (meetingRequest.roomResource != null) {
			meeting.Room_Resource__c = meetingRequest.roomResource;
		}

		//TODO
		// if (meeting.Meeting_Type__c == '--None--')
		// {
		// 	meeting.Meeting_Type__c = null;
		// }
		upsert meeting;

		if (recurrence != null && recurrence.Id != null && recurrence.Original_Meeting__c == null) {
			recurrence.Original_Meeting__c = meeting.Id;
			update recurrence;
		}

		if (isUpdate) {
			List<Participant__c> deleteParticipantList = [SELECT Id FROM Participant__c WHERE Meeting__r.Id = :meetingRequest.meetingId];
			try {
				Database.delete(deleteParticipantList);
			} catch (Exception ex) {
				ProcessLogging.addProcessLog('Edit Meeting', ex.getStackTraceString(), ex.getMessage());
				throw ex;
			}
		}

		List<Participant__c> insertParticipantList = new List<Participant__c>();
		if (meetingRequest.participantsList != null && !meetingRequest.participantsList.isEmpty()) {
			for (Participants participants : meetingRequest.participantsList) {
				if (participants.objectType == 'User') {
					for (Id participantId : participants.idSet) {
						Participant__c participant = new Participant__c();
						participant.recordTypeId = recordTypeInfoByNameMap.get('User Participant').getRecordTypeId();
						participant.Meeting__c = meeting.Id;
						participant.User__c = participantId;
						insertParticipantList.add(participant);
					}
				}

				if (participants.objectType == 'Contact') {
					for (Id participantId : participants.idSet) {
						Participant__c participant = new Participant__c();
						participant.recordTypeId = recordTypeInfoByNameMap.get('Contact Participant').getRecordTypeId();
						participant.Meeting__c = meeting.Id;
						participant.Contact__c = participantId;
						insertParticipantList.add(participant);
					}
				}

				if (participants.objectType == 'Group__c') {
					for (Id participantId : participants.idSet) {
						Participant__c participant = new Participant__c();
						participant.recordTypeId = recordTypeInfoByNameMap.get('Group Participant').getRecordTypeId();
						participant.Meeting__c = meeting.Id;
						participant.Group__c = participantId;
						insertParticipantList.add(participant);
					}
				}
			}
		}
		Database.insert(insertParticipantList);

		if (recurrence != null && recurrence.Id != null) {
			if (meetingRequest.recurrenceSelected == 'series' || String.isEmpty(meetingRequest.recurrenceSelected)) {
				String queryString = RecurringMeetings.recurrenceQueryString + ' WHERE Id = ' + '\'' + recurrence.Id + '\'';
				/*
				List<Recurrence__c> recurrences = Database.query(queryString);
				RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
				options.scheduleAfterToday = true;
				options.isMeetingUpdateOnly = meetingRequest.isMeetingUpdateOnly;
				RecurringMeetings.createRecurringMeetings(recurrences, options);
				*/
				RecurringMeetings.recurrenceQueryString = queryString;
				RecurringMeetingsBatch.runBatch();
			}
		}

		if (meetingRequest.recurrenceId != null && recurrence == null && isUpdate && meetingRequest.isMeetingUpdateOnly && meetingRequest.recurrenceSelected == 'series') {
			recurrence = new Recurrence__c();
			recurrence.Id = meetingRequest.recurrenceId;
			recurrence.Original_Meeting__c = meetingRequest.meetingId;
			upsert recurrence;

			RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
			options.scheduleAfterToday = true;
			options.isMeetingUpdateOnly = meetingRequest.isMeetingUpdateOnly;
			options.recurrenceId = meetingRequest.recurrenceId;

			RecurringMeetings.createRecurringMeetings(options);
		}

		return meeting;
	}

	private static Map<String, List<MeetingType>> getMeetingTypes(String selectedMeetingFocus, String selectedMeetingType) {
		Map<String, String> focus2MeetingTypeFieldMap = new Map<String, String>{ 'Patient' => 'Patient_Meeting_Type__c', 'Patient Group' => 'Patient_Group_Meeting_Type__c', 'Staff Group' => 'Staff_Group_Meeting_Type__c', 'Other' => 'Other_Meeting_Type__c' };

		DescribeSObjectResult objDef = Schema.getGlobalDescribe().get('Meeting__c').getDescribe();
		Map<String, SObjectField> fieldMap = objDef.fields.getMap();

		Map<String, List<MeetingType>> meetingTypeMap = new Map<String, List<MeetingType>>();
		for (String meetingFocus : focus2MeetingTypeFieldMap.keySet()) {
			String fieldName = focus2MeetingTypeFieldMap.get(meetingFocus);
			DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();

			List<MeetingType> meetingTypes = new List<MeetingType>{ new MeetingType((selectedMeetingType == null)) };
			//List<String> pickListValuesList= new List<String>();
			List<Schema.PicklistEntry> ples = fieldMap.get(fieldName).getDescribe().getPicklistValues();
			for (Schema.PicklistEntry pickListVal : ples) {
				Boolean isSelected = (selectedMeetingFocus == meetingFocus && selectedMeetingType == pickListVal.getValue());
				meetingTypes.add(new MeetingType(pickListVal, isSelected));
			}
			meetingTypeMap.put(fieldName, meetingTypes);
		}

		return meetingTypeMap;
	}

	@AuraEnabled
	public static List<Scheduling_Resource__c> getAvailableSchedulingResourcesForMeetingTimes(Id currentResourceId, Datetime newMeetingStartDateTime, Datetime newMeetingEndDateTime) {
		return Scheduling.getAvailableSchedulingResourcesForMeetingTimes(currentResourceId, newMeetingStartDateTime, newMeetingEndDateTime);
	}

	//received serialized from Aura in saveMeeting
	public class MeetingRequest {
		public String meetingId;
		public Meeting__c mtg;
		public Recurrence__c recurrenceRecord;
		public Datetime startDateTime;
		public Datetime endDateTime;
		public String subject;
		public String staffOwnerId;
		public String schedulingResourceId;
		public String description;
		public List<Participants> participantsList;
		public Recurrence recurrence;
		public Boolean isMeetingUpdateOnly;
		public String recurrenceSelected;
		public String recurrenceId;
		public String roomResource;
	}

	public class Participants {
		public String objectType;
		public Set<Id> idSet;
	}

	public class Recurrence {
		public String recurrenceId;
		public Recurrence__c recurrenceRecord;
		public String ownerId;
		public String recurrencePattern;
		public Integer recurEvery;
		public String weekdays;
		public Boolean allDayMeeting;
		public Date allDayDate;
		public Date startDate;
		public Date endDate;
		public String endType;
		public Integer numberOfOccurrences;
		public String dailyOption;
		public Integer monthlyDayNumber;
		public String yearlyMonth;
		public Integer yearlyDayNumber;
	}

	//returned to saveMeeting and deleteMeeting
	public class Response {
		@AuraEnabled
		public Meeting__c mtg;

		@AuraEnabled
		public String responseType { get; set; }
		@AuraEnabled
		public String title { get; set; }
		@AuraEnabled
		public String message { get; set; }
	}

	//returned to call to loadMeeting_Ctl()
	public class MeetingResponse {
		@AuraEnabled
		public Meeting__c mtg;
		@AuraEnabled
		public Map<String, String> selectedOwner;
		@AuraEnabled
		public Map<String, String> selectedPatient;
		@AuraEnabled
		public Recurrence__c recurrenceRecord;
		@AuraEnabled
		public List<ParticipantGroup> participantGroupList;
		@AuraEnabled
		public List<MeetingType> meetingTypes;
		@AuraEnabled
		public Map<String, List<MeetingType>> meetingTypeMap;
		@AuraEnabled
		public Boolean canEdit;
	}

	public class ParticipantGroup {
		@AuraEnabled
		public String groupType;
		@AuraEnabled
		public List<ParticipantResponse> participants;
	}

	public class ParticipantResponse {
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String name;
	}

	public class MeetingType {
		@AuraEnabled
		public String label = '';
		@AuraEnabled
		public String value = '';
		@AuraEnabled
		public Boolean selected = false;

		public MeetingType(Boolean isSelected) {
			this.selected = isSelected;
			this.label = '--None--';
			this.value = '';
		}
		public MeetingType(Schema.PicklistEntry pickListVal, Boolean isSelected) {
			this.label = pickListVal.getLabel();
			this.value = pickListVal.getValue();
			this.selected = isSelected;
		}
	}
}
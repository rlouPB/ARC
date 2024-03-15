public class CallSearch {
	private static String name, gender, city, state, phone, ARCUser = '';

	static String baseNoteQryStr = 'SELECT Id, Account__c, Account__r.Name, Contact__c, Contact__r.Name, OwnerId, Owner.Name, Patient_Name__c, Caller_Name__c, Call_Date_Time__c,' + ' Subject__c, LastModifiedDate, Calling_Number__c, Call_Status__c, RecordType.Name,' + ' Auto_Saved__c, Service_Type__c,' + ' Caller_Affect_and_Presentation__c, Rich_Text_Notes__c' + ' FROM Basic_Note__c';
	//get Notes for a specific Patient

	@AuraEnabled
	public static String getPatientNotes(Map<String, String> searchOptionsMap, String recordId) {
		DateTime startDT, endDT;

		List<Basic_Note__c> notes = new List<Basic_Note__c>();

		List<SearchByCallWrapper> noteWrappers = new List<SearchByCallWrapper>();

		String noteQryStr = baseNoteQryStr;

		noteQryStr += ' WHERE Account__c = :recordId';

		Map<Id, Related_Contact__c> contactIdToRelatedContact = new Map<Id, Related_Contact__c>();
		for (Related_Contact__c rc : [SELECT Id, Role__c, Long_Role__c, Contact_Name__c, Contact_Role_Name__c, Contact__c FROM Related_Contact__c WHERE Account__c = :recordId]) {
			//if multiple RCs for a contact, concatenate their Long Roles into the Role field and keep as one RC
			Related_Contact__c rcFromMap = contactIdToRelatedContact.get(rc.Contact__c);
			if (rcFromMap != null) {
				rc.Role__c += ', ' + rcFromMap.Long_Role__c;
			}
			contactIdToRelatedContact.put(rc.Contact__c, rc);
		}

		if (String.isNotBlank(searchOptionsMap.get('startDate'))) {
			startDT = DateTime.newInstance(Date.valueOf(searchOptionsMap.get('startDate')), Time.newInstance(0, 0, 0, 0));
			noteQryStr += ' AND Call_Date_Time__c >= :startDT';
		}

		if (String.isNotBlank(searchOptionsMap.get('endDate'))) {
			endDT = DateTime.newInstance(Date.valueOf(searchOptionsMap.get('endDate')), Time.newInstance(23, 59, 59, 0));
			noteQryStr += ' AND Call_Date_Time__c <= :endDT';
		}

		//added 180917 JN include Archived Notes in list, but not deleted
		//noteQryStr += ' AND IsDeleted = FALSE ALL ROWS';

		notes = Database.query(noteQryStr);

		if (!notes.isEmpty()) {
			for (Basic_Note__c note : notes) {
				Related_Contact__c relcon;

				if (note.Contact__c != null) {
					relcon = contactIdToRelatedContact.get(note.Contact__c);
				}

				SearchByCallWrapper searchByCallWrapper = new SearchByCallWrapper();

				searchByCallWrapper.callerId = note.Contact__c;
				// searchByCallWrapper.callerName = note.Contact__r.Name;
				searchByCallWrapper.callerName = note.Caller_Name__c;
				//searchByCallWrapper.role = 'No Relation';
				searchByCallWrapper.contactUrl = '/' + note.Contact__c;
				searchByCallWrapper.noteRecordtypeName = note.RecordType.Name;

				if (relcon != null) {
					searchByCallWrapper.callerId = relcon.Contact__c;
					//searchByCallWrapper.callerName = relcon.Contact_Name__c;
					searchByCallWrapper.callerName = relcon.Contact_Role_Name__c;
					searchByCallWrapper.role = relcon.Role__c;
					searchByCallWrapper.contactUrl = '/' + relcon.Contact__c;
				}
				//else if (note.Caller_Name__c != NULL) {
				//    searchByCallWrapper.callerName = note.Caller_Name__c;
				//}

				searchByCallWrapper.accountId = note.Account__c;
				searchByCallWrapper.accountName = note.Account__r.Name;
				searchByCallWrapper.patientUrl = '/' + note.Account__c;

				searchByCallWrapper.callDateTime = '';
				if (note.Call_Date_Time__c != null) {
					searchByCallWrapper.callDateTime = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('MMM d, YYYY hh:mm a'));
					searchByCallWrapper.callDateTime_short = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('M/d/YY h:mm a'));
					searchByCallWrapper.callDate_short = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('M/d/YY'));
					searchByCallWrapper.callTime_short = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('h:mm a'));
					searchByCallWrapper.callDateTime_dt = note.Call_Date_Time__c;
				}
				searchByCallWrapper.callingPhoneNumber = note.Calling_Number__c;
				searchByCallWrapper.ARCUserId = note.OwnerId;
				searchByCallWrapper.ARCUserName = note.Owner.Name;
				searchByCallWrapper.callStatus = note.Call_Status__c;
				searchByCallWrapper.noteId = note.Id;

				searchByCallWrapper.callerAffect = note.Caller_Affect_and_Presentation__c;
				//searchByCallWrapper.callNotes = note.Text_Narrative_Notes__c;
				searchByCallWrapper.richCallNotes = note.Rich_Text_Notes__c;
				searchByCallWrapper.isAutosaved = note.Auto_Saved__c;

				if (String.isNotBlank(note.Subject__c)) {
					searchByCallWrapper.callSubject = note.Subject__c;
				} else {
					searchByCallWrapper.callSubject = '';
				}
				noteWrappers.add(searchByCallWrapper);
			}
		}

		return JSON.serialize(noteWrappers);
	}

	//get Notes for any Patients
	@AuraEnabled
	public static String searchByCall(String searchOptions, String recordId) {
		String queryStr = '';
		Account patientAcc = new Account();

		Set<Id> whoIdSet = new Set<Id>();
		Set<Id> whatIdSet = new Set<Id>();

		Set<Id> conListIdSet = new Set<Id>();
		List<SearchByCallWrapper> searchByCallWrapperList = new List<SearchByCallWrapper>();
		List<Related_Contact__c> relatedConList = new List<Related_Contact__c>();
		List<Basic_Note__c> noteList = new List<Basic_Note__c>();
		//Map<Id, String> relConMap = new Map<Id, String>();
		Map<String, String> relKey2RoleMap = new Map<String, String>();
		Map<String, String> searchOptionsMap = (Map<String, String>) JSON.deserialize(searchOptions, Map<String, String>.class);

		String noteQryStr = baseNoteQryStr;
		noteQryStr += ' WHERE ';

		String otherConditions = 'Recordtype.Name LIKE \'Admissions%\' AND ';

		Boolean isCaller = (searchOptionsMap.get('searchFor') == 'patient') ? false : true;
		DateTime startDT;
		DateTime endDT;
		Boolean isIncludeNonStarterCalls = false;

		if (String.isNotBlank(searchOptionsMap.get('name'))) {
			name = '%' + searchOptionsMap.get('name') + '%';
			String searchForName = (isCaller) ? 'Caller_Name__c' : 'Patient_Name__c';
			String searchForWhoName = (isCaller) ? 'Contact__r.Name' : 'Account__r.Name';
			otherConditions = otherConditions + '(' + searchForName + ' LIKE :name ' + 'OR ' + searchForWhoName + ' LIKE :name ) ' + 'AND ';
		}

		if (String.isNotBlank(searchOptionsMap.get('gender'))) {
			gender = searchOptionsMap.get('gender');
			String searchForgender = (isCaller) ? 'Caller_Gender__c' : 'Patient_Gender__c';
			otherConditions = otherConditions + searchForgender + ' =:gender AND ';
		}

		if (String.isNotBlank(searchOptionsMap.get('state'))) {
			state = searchOptionsMap.get('state');
			otherConditions = otherConditions + ' Patient_State__c  =:state AND ';
		}

		if (String.isNotBlank(searchOptionsMap.get('city'))) {
			city = searchOptionsMap.get('city');
			otherConditions = otherConditions + ' Patient_City__c  =:city AND ';
		}

		if (String.isNotBlank(searchOptionsMap.get('phone'))) {
			phone = searchOptionsMap.get('phone');
			otherConditions = otherConditions + ' Calling_Number__c  =:phone AND ';
		}

		if (String.isNotBlank(searchOptionsMap.get('isIncludeNonStarterCalls'))) {
			isIncludeNonStarterCalls = Boolean.valueOf(searchOptionsMap.get('isIncludeNonStarterCalls'));
		}

		if (String.isNotBlank(searchOptionsMap.get('startDate')) && String.isNotBlank(searchOptionsMap.get('endDate'))) {
			startDT = DateTime.newInstance(Date.valueOf(searchOptionsMap.get('startDate')), Time.newInstance(0, 0, 0, 0));
			endDT = DateTime.newInstance(Date.valueOf(searchOptionsMap.get('endDate')), Time.newInstance(23, 59, 59, 0));

			otherConditions += '(Call_Date_Time__c >= :startDT AND Call_Date_Time__c <= :endDT) AND ';
		}

		if (isIncludeNonStarterCalls == false) {
			otherConditions += ' Call_Type__c != \'Non-Starter\' AND ';
		}

		if (!String.isBlank(recordId)) {
			otherConditions += 'Account__c = :recordId AND ';
		}
		if (String.isNotBlank(searchOptionsMap.get('ARCUser'))) {
			ARCUser = searchOptionsMap.get('ARCUser');
			otherConditions += 'OwnerId = :ARCUser  ';
		}

		if (otherConditions.endsWith('AND ')) {
			otherConditions = otherConditions.substring(0, otherConditions.length() - 4);
		}

		if (otherConditions == '' && noteQryStr.endsWith('WHERE ')) {
			noteQryStr = noteQryStr.substring(0, noteQryStr.length() - 6);
		}

		//otherConditions += ' ORDER by LastModifiedDate DESC LIMIT 1000';
		otherConditions += ' ORDER by Call_Date_Time__c DESC NULLS FIRST, LastModifiedDate DESC' + ' LIMIT 1000';

		noteQryStr += otherConditions;

		//added 180917 JN include Archived Notes in list, but not deleted
		//noteQryStr += ' ALL ROWS';

		noteList = Database.query(noteQryStr);

		for (Basic_Note__c ts : noteList) {
			if (ts.Contact__c != null) {
				whoIdSet.add(ts.Contact__c);
			}
			if (ts.Account__c != null) {
				whatIdSet.add(ts.Account__c);
			}
		}
		queryStr = 'SELECT Id, Role__c, Long_Role__c, Contact__c, Account__c' + ' FROM Related_Contact__c' + ' WHERE Contact__c In :whoIdSet' + ' AND Account__c in :whatIdSet' + ' AND (RecordType.developerName = \'Patient\'' + ' OR RecordType.developerName = \'Personal\'' + ' OR RecordType.developerName = \'Professional\')';

		relatedConList = Database.query(queryStr);

		for (Related_Contact__c rc : relatedConList) {
			//relConMap.put(rc.Contact__c ,rc.Role__c);
			String rcKey = getRcKey(rc);
			String currentRole = relKey2RoleMap.get(rcKey);
			if (currentRole == null) {
				currentRole = '';
			} else {
				currentRole += ', ';
			}
			currentRole += rc.Long_Role__c;
			relKey2RoleMap.put(rcKey, currentRole);
		}

		if (!noteList.isEmpty()) {
			for (Basic_Note__c note : noteList) {
				if (searchOptionsMap.get('searchFor') == 'patient') {
					String role = relKey2RoleMap.get(getRcKey(note));
					SearchByCallWrapper searchByCallWrapper = new SearchByCallWrapper();
					if (String.isNotBlank(note.Account__c) && isAccountId(note.Account__c)) {
						searchByCallWrapper.accountId = note.Account__c;
						searchByCallWrapper.patientUrl = '/' + note.Account__c;
						searchByCallWrapper.accountName = note.Account__r.Name;
					} else {
						searchByCallWrapper.accountName = note.Patient_Name__c;
					}
					if (String.isNotBlank(note.Contact__c) && isContactId(note.Contact__c)) {
						searchByCallWrapper.callerName = note.Contact__r.Name;
					} else {
						searchByCallWrapper.callerName = note.Caller_Name__c;
					}

					if (String.isNotBlank(note.Contact__c)) {
						searchByCallWrapper.callerId = note.Contact__c;
						//searchByCallWrapper.callerName = note.Caller_Name__c;//note.Who.Name;
						if (String.isNotBlank(role)) {
							searchByCallWrapper.role = role;
							searchByCallWrapper.callerName += ' (' + role + ')';
						}
					}

					searchByCallWrapper.callDateTime = '';
					// if(note.Call_Date_Time__c != null){
					//     searchByCallWrapper.callDateTime =  String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('MMM d, YYYY h:mm a'));
					//     searchByCallWrapper.callDateTime_dt =  note.Call_Date_Time__c;
					// }
					if (note.Call_Date_Time__c != null) {
						searchByCallWrapper.callDateTime = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('MMM d, YYYY hh:mm a'));
						searchByCallWrapper.callDateTime_dt = note.Call_Date_Time__c;
						searchByCallWrapper.callDateTime_short = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('M/d/YY h:mm a'));
						searchByCallWrapper.callDate_short = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('M/d/YY'));
						searchByCallWrapper.callTime_short = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('h:mm a'));
					}
					searchByCallWrapper.callingPhoneNumber = note.Calling_Number__c;
					searchByCallWrapper.ARCUserId = note.OwnerId;
					searchByCallWrapper.ARCUserName = note.Owner.Name;
					searchByCallWrapper.callerAffect = note.Caller_Affect_and_Presentation__c;
					//searchByCallWrapper.callNotes = note.Text_Narrative_Notes__c;
					searchByCallWrapper.richCallNotes = note.Rich_Text_Notes__c;
					searchByCallWrapper.callStatus = note.Call_Status__c;
					searchByCallWrapper.noteId = note.Id;
					searchByCallWrapper.isAutosaved = note.Auto_Saved__c;
					searchByCallWrapper.noteRecordtypeName = note.RecordType.Name;

					if (String.isNotBlank(note.Subject__c)) {
						searchByCallWrapper.callSubject = note.Subject__c;
					} else {
						searchByCallWrapper.callSubject = '';
					}
					searchByCallWrapperList.add(searchByCallWrapper);
				} else if (searchOptionsMap.get('searchFor') == 'caller') {
					//String role = relConMap.get(note.WhoId);
					String role = relKey2RoleMap.get(getRcKey(note));

					SearchByCallWrapper searchByCallWrapper = new SearchByCallWrapper();

					if (String.isNotBlank(note.Contact__c)) {
						searchByCallWrapper.callerName = note.Contact__r.Name;
					} else {
						searchByCallWrapper.callerName = note.Caller_Name__c;
					}
					if (String.isNotBlank(role)) {
						searchByCallWrapper.callerName += ' (' + role + ')';
					}

					if (String.isNotBlank(note.Account__c) && isAccountId(note.Account__c)) {
						searchByCallWrapper.accountId = note.Account__c;
						searchByCallWrapper.accountName = note.Account__r.Name;
						searchByCallWrapper.patientUrl = '/' + note.Account__c;
					} else {
						searchByCallWrapper.accountName = note.Patient_Name__c;
					}
					searchByCallWrapper.noteId = note.Id;
					searchByCallWrapper.callerId = note.Contact__c;
					searchByCallWrapper.contactUrl = '/' + note.Contact__c;
					searchByCallWrapper.role = role;

					searchByCallWrapper.callDateTime = '';
					if (note.Call_Date_Time__c != null) {
						searchByCallWrapper.callDateTime = String.valueOf(Datetime.valueOf(note.Call_Date_Time__c).format('MMM d, YYYY hh:mm a'));
						searchByCallWrapper.callDateTime_dt = note.Call_Date_Time__c;
					}
					searchByCallWrapper.callingPhoneNumber = note.Calling_Number__c;
					searchByCallWrapper.ARCUserId = note.OwnerId;
					searchByCallWrapper.ARCUserName = note.Owner.Name;
					searchByCallWrapper.callerAffect = note.Caller_Affect_and_Presentation__c;
					searchByCallWrapper.richCallNotes = note.Rich_Text_Notes__c;
					searchByCallWrapper.isAutosaved = note.Auto_Saved__c;

					searchByCallWrapper.callStatus = note.Call_Status__c;
					if (String.isNotBlank(note.Subject__c)) {
						searchByCallWrapper.callSubject = note.Subject__c;
					} else {
						searchByCallWrapper.callSubject = '';
					}
					//}
					searchByCallWrapperList.add(searchByCallWrapper);
				}
			}
		}

		return JSON.serialize(searchByCallWrapperList);
	}

	//key for making sure we have the right Related Contact for this Patient Account and Contact
	static String getRcKey(Related_Contact__c rc) {
		return (String) rc.Account__c + (String) rc.Contact__c;
	}
	static String getRcKey(Basic_Note__c t) {
		return (String) t.Account__c + (String) t.Contact__c;
	}
	static Boolean isAccountId(String possibleAccountId) {
		Boolean isAccount = false;
		if (possibleAccountId != null) {
			if (possibleAccountId.startsWith('001'))
				isAccount = true;
		}
		return isAccount;
	}
	static Boolean isContactId(String possibleContactId) {
		Boolean isContact = false;
		if (possibleContactId != null) {
			if (possibleContactId.startsWith('003'))
				isContact = true;
		}
		return isContact;
	}

	public class SearchByCallWrapper {
		public String callerId;
		public String callerName;
		public String contactUrl;
		public String accountId;
		public String accountName;
		public String patientUrl;

		public String callDateTime; //          Aug 6, 1998 10:31 AM
		public String callDate_short; //          8/6/98 10:31AM
		public String callTime_short; //          10:31 AM
		public String callDateTime_short; //    8/6/98 10:31AM
		public DateTime callDateTime_dt; //actual datetime value used for sorting

		public String callingPhoneNumber;
		public System.Address patientAddress;
		public String role;
		public String ARCUserId;
		public String ARCUserName;
		public String callSubject;
		public String callStatus;
		public String noteId;
		public String contactName;
		public String noteRecordtypeName;

		public Boolean isAutosaved;
		public String callerAffect;
		public String callNotes;
		public String richCallNotes;
	}
}
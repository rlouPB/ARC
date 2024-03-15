public class AdvancedSearchViewComponentController {
	private static String name, gender, city, state, phone, ARCUser = '';

	@AuraEnabled
	public static String contactSearch(String searchOptions, String recordId) {
		String queryStr = '';
		Account patientAcc = new Account();
		List<Contact> conList = new List<Contact>();
		Set<Id> conIdSet = new Set<Id>();
		List<ContactSearchWrapper> contactSearchWrapperList = new List<ContactSearchWrapper>();
		Map<String, String> searchOptionsMap = (Map<String, String>) JSON.deserialize(searchOptions, Map<String, String>.class);

		if (String.isNotBlank(recordId)) {
			patientAcc = [SELECT Id, Name, (SELECT Id, Contact__c FROM Related_Contacts__r WHERE RecordType.developerName = 'Personal' OR RecordType.developerName = 'Professional'), (SELECT Id, Subject, Call_Date_Time__c, LastModifiedDate FROM Tasks ORDER BY LastModifiedDate DESC LIMIT 1) FROM Account WHERE Id = :recordId];

			if (!patientAcc.Related_Contacts__r.isEmpty() && patientAcc.Related_Contacts__r != null) {
				for (Related_Contact__c relatedContact : patientAcc.Related_Contacts__r) {
					conIdSet.add(relatedContact.Contact__c);
				}
			}
		}

		if (String.isBlank(searchOptionsMap.get('searchFor'))) {
			searchOptionsMap.put('searchFor', 'patient');
		}

		queryStr = 'SELECT Id, Name, AccountId, Account.Name, (SELECT Id, Subject, Call_Date_Time__c, LastModifiedDate FROM Tasks ORDER by LastModifiedDate DESC LIMIT 1) ';

		if (searchOptionsMap.get('searchFor') == 'patient') {
			queryStr += ' FROM Contact WHERE RecordType.developerName = \'Patient\'';
		} else if (searchOptionsMap.get('searchFor') == 'relatedContact') {
			queryStr += ' ,(SELECT Id, Role__c FROM Related_Contacts__r LIMIT 1) FROM Contact WHERE Id IN :conIdSet AND (RecordType.developerName = \'Personal\' OR RecordType.developerName = \'Professional\') ';
		}

		queryStr = formWhereQueryString(searchOptionsMap, queryStr);

		conList = Database.query(queryStr);

		for (contact con : conList) {
			ContactSearchWrapper conSearchWrapper = new ContactSearchWrapper();

			if (searchOptionsMap.get('searchFor') == 'patient') {
				Task task = new Task();

				if (!con.tasks.isEmpty() && con.tasks != null) {
					task = con.tasks;
				}

				conSearchWrapper.id = con.id;
				conSearchWrapper.name = con.Name;
				conSearchWrapper.accountId = con.accountId;
				conSearchWrapper.accountName = con.account.Name;
				conSearchWrapper.patientUrl = '/' + con.accountId;
				if (String.isNotBlank(task.Id)) {
					conSearchWrapper.patientTaskId = task.Id;
					conSearchWrapper.patientTaskUrl = '/' + task.Id;

					if (String.isNotBlank(task.Subject)) {
						if (task.Call_Date_Time__c != null) {
							conSearchWrapper.patientTaskSubject = task.Subject + ' - ' + task.Call_Date_Time__c.format('MM/dd/YYYY hh:mm a');
						} else {
							conSearchWrapper.patientTaskSubject = task.Subject;
						}
					} else {
						if (task.Call_Date_Time__c != null) {
							conSearchWrapper.patientTaskSubject = '[No Subject]' + ' - ' + task.Call_Date_Time__c.format('MM/dd/YYYY hh:mm a');
						} else {
							conSearchWrapper.patientTaskSubject = '[No Subject]';
						}
					}
				}
			} else if (searchOptionsMap.get('searchFor') == 'relatedContact') {
				Task task = new Task();
				Task patientTask = new Task();
				Related_Contact__c relatedContact = new Related_Contact__c();

				if (!con.Related_Contacts__r.isEmpty() && con.Related_Contacts__r != null) {
					relatedContact = con.Related_Contacts__r;
				}

				if (!con.tasks.isEmpty() && con.tasks != null) {
					task = con.tasks;
				}

				if (!patientAcc.tasks.isEmpty() && patientAcc.tasks != null) {
					patientTask = patientAcc.tasks;
				}

				conSearchWrapper.id = con.id;
				conSearchWrapper.name = con.Name;
				conSearchWrapper.contactUrl = '/' + con.id;
				conSearchWrapper.accountId = patientAcc.Id;
				conSearchWrapper.accountName = patientAcc.Name;
				conSearchWrapper.patientUrl = '/' + patientAcc.Id;
				conSearchWrapper.role = relatedContact.Role__c;

				if (String.isNotBlank(patientTask.Id)) {
					conSearchWrapper.patientTaskId = patientTask.Id;
					conSearchWrapper.patientTaskUrl = '/' + patientTask.Id;

					if (String.isNotBlank(patientTask.Subject)) {
						if (patientTask.Call_Date_Time__c != null) {
							conSearchWrapper.patientTaskSubject = patientTask.Subject + ' - ' + patientTask.Call_Date_Time__c.format('MM/dd/YYYY hh:mm a');
						} else {
							conSearchWrapper.patientTaskSubject = patientTask.Subject;
						}
					} else {
						if (patientTask.Call_Date_Time__c != null) {
							conSearchWrapper.patientTaskSubject = '[No Subject]' + ' - ' + patientTask.Call_Date_Time__c.format('MM/dd/YYYY hh:mm a');
						} else {
							conSearchWrapper.patientTaskSubject = '[No Subject]';
						}
					}
				}

				if (String.isNotBlank(task.Id)) {
					conSearchWrapper.contactTaskId = task.Id;
					conSearchWrapper.contactTaskUrl = '/' + task.Id;

					if (String.isNotBlank(task.Subject)) {
						if (task.Call_Date_Time__c != null) {
							conSearchWrapper.contactTaskSubject = task.Subject + ' - ' + task.Call_Date_Time__c.format('MM/dd/YYYY hh:mm a');
						} else {
							conSearchWrapper.contactTaskSubject = task.Subject;
						}
					} else {
						if (task.Call_Date_Time__c != null) {
							conSearchWrapper.contactTaskSubject = '[No Subject]' + ' - ' + task.Call_Date_Time__c.format('MM/dd/YYYY hh:mm a');
						} else {
							conSearchWrapper.contactTaskSubject = '[No Subject]';
						}
					}
				}
			}
			contactSearchWrapperList.add(conSearchWrapper);
		}

		return JSON.serialize(contactSearchWrapperList);
	}

	@AuraEnabled
	public static String searchByCall(String searchOptions, String recordId) {
		String queryStr = '';
		Account patientAcc = new Account();
		Set<Id> conIdSet = new Set<Id>();
		Set<Id> conListIdSet = new Set<Id>();
		List<SearchByCallWrapper> searchByCallWrapperList = new List<SearchByCallWrapper>();
		List<Contact> conList = new List<Contact>();
		List<Task> taskList = new List<Task>();
		Map<Id, Contact> conMap = new Map<Id, Contact>();
		Map<String, String> searchOptionsMap = (Map<String, String>) JSON.deserialize(searchOptions, Map<String, String>.class);

		if (String.isNotBlank(recordId)) {
			patientAcc = [SELECT Id, Name, (SELECT Id, MailingAddress FROM contacts LIMIT 1), (SELECT Id, Contact__c FROM Related_Contacts__r WHERE RecordType.developerName = 'Personal' OR RecordType.developerName = 'Professional'), (SELECT Id, Subject, LastModifiedDate FROM Tasks ORDER BY LastModifiedDate DESC LIMIT 1) FROM Account WHERE Id = :recordId];

			if (!patientAcc.Related_Contacts__r.isEmpty() && patientAcc.Related_Contacts__r != null) {
				for (Related_Contact__c relatedContact : patientAcc.Related_Contacts__r) {
					conIdSet.add(relatedContact.Contact__c);
				}
			}
		}

		queryStr = 'SELECT Id, Name, AccountId, Account.Name, MailingAddress ';

		if (searchOptionsMap.get('searchFor') == 'patient') {
			queryStr += ' FROM Contact WHERE RecordType.developerName = \'Patient\'';
		} else if (searchOptionsMap.get('searchFor') == 'caller') {
			queryStr += ' , (SELECT Id, Role__c FROM Related_Contacts__r LIMIT 1) FROM Contact ';

			if (String.isNotBlank(recordId)) {
				queryStr += 'WHERE Id IN :conIdSet AND (RecordType.developerName = \'Personal\' OR RecordType.developerName = \'Professional\') ';
			} else {
				queryStr += 'WHERE (RecordType.developerName = \'Personal\' OR RecordType.developerName = \'Professional\') ';
			}
		}

		queryStr = formWhereQueryString(searchOptionsMap, queryStr);
		conList = Database.query(queryStr);

		if (!conList.isEmpty()) {
			for (Contact con : conList) {
				conListIdSet.add(con.Id);
				conMap.put(con.Id, con);
			}
		}

		if (!conListIdSet.isEmpty()) {
			String taskQryStr = ' SELECT Id, OwnerId, Owner.Name, Subject, LastModifiedDate, Call_Date_Time__c, Calling_Number__c, Call_Status__c, Patient_Note__r.Text_Narrative_Notes__c,WhoId FROM Task WHERE WhoId IN :conListIdSet ', otherWhereClause = '';
			DateTime startDT;
			DateTime endDT;
			Boolean isIncludeNonStarterCalls = false;

			if (String.isNotBlank(searchOptionsMap.get('isIncludeNonStarterCalls'))) {
				isIncludeNonStarterCalls = Boolean.valueOf(searchOptionsMap.get('isIncludeNonStarterCalls'));
			}

			if (String.isNotBlank(searchOptionsMap.get('startDate')) && String.isNotBlank(searchOptionsMap.get('endDate'))) {
				startDT = DateTime.newInstance(Date.valueOf(searchOptionsMap.get('startDate')), Time.newInstance(0, 0, 0, 0));
				endDT = DateTime.newInstance(Date.valueOf(searchOptionsMap.get('endDate')), Time.newInstance(23, 59, 59, 0));
				otherWhereClause += 'AND (Call_Date_Time__c >= :startDT AND Call_Date_Time__c <= :endDT) ';
			}

			if (isIncludeNonStarterCalls == false) {
				otherWhereClause += 'AND Call_Type__c != \'Non-Starter\' ';
			}

			if (!String.isBlank(recordId)) {
				otherWhereClause += 'AND WhatId = :recordId ';
			}
			if (String.isNotBlank(searchOptionsMap.get('ARCUser'))) {
				ARCUser = searchOptionsMap.get('ARCUser');
				otherWhereClause += ' AND OwnerId = :ARCUser ';
			}

			otherWhereClause += 'ORDER by LastModifiedDate DESC LIMIT 20';
			taskQryStr += otherWhereClause;
			taskList = Database.query(taskQryStr);
		}

		if (!taskList.isEmpty()) {
			for (task task : taskList) {
				if (searchOptionsMap.get('searchFor') == 'patient') {
					Contact con = conMap.get(task.WhoId);
					SearchByCallWrapper searchByCallWrapper = new SearchByCallWrapper();

					if (String.isNotBlank(con.Id)) {
						searchByCallWrapper.callerId = con.Id;
						searchByCallWrapper.callerName = con.name;
						searchByCallWrapper.accountId = con.accountId;
						searchByCallWrapper.accountName = con.account.Name;
						searchByCallWrapper.patientUrl = '/' + con.accountId;
						searchByCallWrapper.patientAddress = con.MailingAddress;
					}
					searchByCallWrapper.callDateTime = '';
					if (task.Call_Date_Time__c != null) {
						searchByCallWrapper.callDateTime = String.valueOf(Datetime.valueOf(task.Call_Date_Time__c).format('MMMM dd, YYYY hh:mm a'));
					}
					searchByCallWrapper.callingPhoneNumber = task.Calling_Number__c;
					searchByCallWrapper.ARCUserId = task.OwnerId;
					searchByCallWrapper.ARCUserName = task.Owner.Name;
					searchByCallWrapper.callNotes = task.Patient_Note__r.Text_Narrative_Notes__c;
					searchByCallWrapper.callStatus = task.Call_Status__c;
					searchByCallWrapper.taskId = task.Id;

					if (String.isNotBlank(task.Subject)) {
						searchByCallWrapper.callSubject = task.Subject;
					} else {
						searchByCallWrapper.callSubject = '[No Subject]';
					}
					searchByCallWrapperList.add(searchByCallWrapper);
				} else if (searchOptionsMap.get('searchFor') == 'caller') {
					Contact con = conMap.get(task.WhoId);
					Related_Contact__c relatedCon = new Related_Contact__c();
					Contact patientCon = new Contact();

					if (!con.Related_Contacts__r.isEmpty() && con.Related_Contacts__r != null) {
						relatedCon = con.Related_Contacts__r;
					}

					if (!patientAcc.contacts.isEmpty() && patientAcc.contacts != null) {
						patientCon = patientAcc.contacts;
					}

					SearchByCallWrapper searchByCallWrapper = new SearchByCallWrapper();

					if (String.isNotBlank(patientAcc.Id)) {
						searchByCallWrapper.accountId = patientAcc.Id;
						searchByCallWrapper.accountName = patientAcc.Name;
						searchByCallWrapper.patientUrl = '/' + patientAcc.Id;
					}
					searchByCallWrapper.taskId = task.Id;
					searchByCallWrapper.callerId = con.id;
					searchByCallWrapper.callerName = con.Name;
					searchByCallWrapper.contactUrl = '/' + con.id;
					searchByCallWrapper.patientAddress = patientCon.MailingAddress;
					searchByCallWrapper.role = relatedCon.Role__c;

					if (String.isNotBlank(task.Id)) {
						searchByCallWrapper.callDateTime = '';
						if (task.Call_Date_Time__c != null) {
							searchByCallWrapper.callDateTime = String.valueOf(Datetime.valueOf(task.Call_Date_Time__c).format('MMMM dd, YYYY hh:mm a'));
						}
						searchByCallWrapper.callingPhoneNumber = task.Calling_Number__c;
						searchByCallWrapper.ARCUserId = task.OwnerId;
						searchByCallWrapper.ARCUserName = task.Owner.Name;
						searchByCallWrapper.callNotes = task.Patient_Note__r.Text_Narrative_Notes__c;
						searchByCallWrapper.callStatus = task.Call_Status__c;
						if (String.isNotBlank(task.Subject)) {
							searchByCallWrapper.callSubject = task.Subject;
						} else {
							searchByCallWrapper.callSubject = '[No Subject]';
						}
					}
					searchByCallWrapperList.add(searchByCallWrapper);
				}
			}
		}

		return JSON.serialize(searchByCallWrapperList);
	}

	public static String formWhereQueryString(Map<String, String> searchOptionsMap, String queryStr) {
		if (String.isNotBlank(searchOptionsMap.get('name'))) {
			name = '%' + searchOptionsMap.get('name') + '%';
			queryStr += ' AND Name Like :name';
		}

		if (String.isNotBlank(searchOptionsMap.get('gender'))) {
			gender = searchOptionsMap.get('gender');
			queryStr += ' AND Gender__c = :gender';
		}

		if (String.isNotBlank(searchOptionsMap.get('city'))) {
			city = searchOptionsMap.get('city');
			queryStr += ' AND MailingCity LIKE :city';
		}

		if (String.isNotBlank(searchOptionsMap.get('state'))) {
			state = searchOptionsMap.get('state');
			queryStr += ' AND MailingState LIKE :state';
		}

		if (String.isNotBlank(searchOptionsMap.get('phone'))) {
			phone = searchOptionsMap.get('phone');
			queryStr += ' AND (HomePhone = :phone OR Phone = :phone OR Fax = :phone)';
		}

		queryStr += ' LIMIT 20';

		return queryStr;
	}

	public class SearchByCallWrapper {
		public String callerId;
		public String callerName;
		public String contactUrl;
		public String accountId;
		public String accountName;
		public String patientUrl;
		public String callDateTime;
		public String callingPhoneNumber;
		public System.Address patientAddress;
		public String role;
		public String ARCUserId;
		public String ARCUserName;
		public String callSubject;
		public String callStatus;
		public String callNotes;
		public String taskId;
		public String contactName;
	}

	public class ContactSearchWrapper {
		public String id;
		public String name;
		public String contactUrl;
		public String accountId;
		public String accountName;
		public String patientUrl;
		public String patientTaskId;
		public String patientTaskSubject;
		public String patientTaskUrl;
		public String contactTaskId;
		public String contactTaskSubject;
		public String contactTaskUrl;
		public String role;
	}
}
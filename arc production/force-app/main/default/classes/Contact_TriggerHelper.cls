public without sharing class Contact_TriggerHelper {
	/*
		Handle specific tasks for Contact trigger

		History
					180719	JN 		Created
	*/

	public static Id conPatientRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordtypeId();

	//fields that contribute to Patient Account Name
	public static List<String> nameFields = new List<String>{ 'FirstName', 'Preferred_First_Name__c', 'LastName' };

	public static void updatePatientAccountsFromContact(List<Contact> triggerNew, Map<Id, Contact> triggerOldMap) {
		Map<Id, Account> patientAccountIdMap = new Map<Id, Account>();
		Contact oldCon;
		for (Contact con : triggerNew) {
			if (con.RecordtypeId == conPatientRtId && null != triggerOldMap && null != triggerOldMap.get(con.Id)) {
				oldCon = triggerOldMap.get(con.Id);
				for (String nameField : nameFields) {
					if (triggerOldMap == null || oldCon.get(nameField) != con.get(nameField)) {
						patientAccountIdMap.put(con.AccountId, new Account(Id = con.AccountId, Name = getPatientName(con)));
						break;
					}
				}
			}
		}

		List<Account> queriedAccounts = [SELECT Id, Name FROM Account WHERE Id IN :patientAccountIdMap.keySet()];
		List<Account> accountsToUpdate = new List<Account>();

		for (Account queriedAcc : queriedAccounts) {
			Account calculatedAcc = patientAccountIdMap.get(queriedAcc.Id);
			if (queriedAcc.Name != calculatedAcc.Name) {
				accountsToUpdate.add(calculatedAcc);
			}
		}

		update accountsToUpdate;
	}

	public static String getPatientName(Contact patientContact) {
		return patientContact.FirstName + (patientContact.Preferred_First_Name__c != null ? ' (' + patientContact.Preferred_First_Name__c + ') ' : ' ') + patientContact.LastName;
	}

	public static void updateLegalNamesFromContact(List<Contact> triggerNew, Map<Id, Contact> triggerOldMap) {
		Set<Id> changedContactAccountIdSet = new Set<Id>();
		for (Contact contact : triggerNew) {
			if (contact.RecordtypeId == conPatientRtId && null != triggerOldMap && null != triggerOldMap.get(contact.Id)) {
				Contact oldContact = triggerOldMap.get(contact.Id);
				for (String nameField : nameFields) {
					if (triggerOldMap == null || oldContact.get(nameField) != contact.get(nameField)) {
						changedContactAccountIdSet.add(contact.AccountId);
						break;
					}
				}
			}
		}

		if (!changedContactAccountIdSet.isEmpty()) {
			List<Legal_Name__c> legalNamesToUpdate = new List<Legal_Name__c>();
			for (Legal_Name__c legalName : [SELECT Id, Patient__r.Patient_Contact__r.FirstName, Patient__r.Patient_Contact__r.LastName, Patient__r.Patient_Contact__r.Distinguished_Name__c, Current_First_Name__c, Current_Last_Name__c, Current_Distinguished_Name__c FROM Legal_Name__c WHERE Patient__c IN :changedContactAccountIdSet]) {
				String contactFirstName = '';
				String contactLastName = '';
				String contactDistinguishedName = '';
				if (legalName.Patient__r.Patient_Contact__r.FirstName != null) {
					contactFirstName = legalName.Patient__r.Patient_Contact__r.FirstName;
				}
				if (legalName.Patient__r.Patient_Contact__r.LastName != null) {
					contactLastName = legalName.Patient__r.Patient_Contact__r.LastName;
				}
				if (legalName.Patient__r.Patient_Contact__r.Distinguished_Name__c != null) {
					contactDistinguishedName = legalName.Patient__r.Patient_Contact__r.Distinguished_Name__c;
				}

				legalName.Current_First_Name__c = contactFirstName;
				legalName.Current_Last_Name__c = contactLastName;
				legalName.Current_Distinguished_Name__c = contactDistinguishedName;
				legalNamesToUpdate.add(legalName);
			}

			update legalNamesToUpdate;
		}
	}

	// remove 220513 JN
	// @future
	// public static void updateContactsUserFields(Id contactId){
	// 	Contact contact = [Select Staff_User__c, Professional_Name__c From Contact where Id = :contactId];
	// 	User user = new User(
	// 		Id = contact.Staff_User__c,
	// 		Contact_Professional_Name__c = contact.Professional_Name__c
	// 	);
	// 	update user;
	// }

	@future
	public static void updateStaffUserFields(Set<Id> staffContactIds) {
		List<Contact> staffContacts = [SELECT Id, Professional_Name__c, Staff_User__r.Professional_Suffix__c, Professional_Suffix__c, Staff_User__c, Staff_User__r.Contact_Professional_Name__c FROM Contact WHERE Id IN :staffContactIds];
		List<User> usersToUpdate = new List<User>();
		for (Contact con : staffContacts) {
			User userToUpdate = new User(Id = con.Staff_User__c);
			if (con.Professional_Name__c != con.Staff_User__r.Contact_Professional_Name__c) {
				userToUpdate.Contact_Professional_Name__c = con.Professional_Name__c;
			}
			if (con.Professional_Suffix__c != con.Staff_User__r.Professional_Suffix__c) {
				userToUpdate.Professional_Suffix__c = con.Professional_Suffix__c;
			}
			usersToUpdate.add(userToUpdate);
		}
		String forProcessLog = String.valueOf(staffContactIds) + '\n\nusersToUpdate: ' + String.valueOf(usersToUpdate);

		try {
			update usersToUpdate;
		} catch (Exception e) {
			ProcessLogging.quickProcessLog('Contact_TriggerHandler.updateStaffUserFields()', e.getStackTraceString(), 'Exception Message:\n' + e.getMessage() + '\n\n\n\n' + forProcessLog);
		}
	}
}
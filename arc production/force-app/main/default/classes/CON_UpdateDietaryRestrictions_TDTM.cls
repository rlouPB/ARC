global class CON_UpdateDietaryRestrictions_TDTM extends npsp.TDTM_RunnableMutable {
	global override void run(List<SObject> listNew, List<SObject> listOld, npsp.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult, npsp.TDTM_Runnable.DmlWrapper dmlWrapper) {
		List<Contact> newContactList = (List<Contact>) listNew;
		List<Contact> oldContactList = (List<Contact>) listOld;
		Map<Id, SObject> objectsToUpdateMap = new Map<Id, SObject>(dmlWrapper.objectsToUpdate);
		Boolean hasListOld = false;

		if (oldContactList != null && oldContactList.size() > 0) {
			hasListOld = true;
		}

		// Populate accountMap from newContactList
		Set<Id> accountIds = new Set<Id>();
		for (Contact newCon : newContactList) {
			accountIds.add(newCon.AccountId);
		}
		Map<Id, Account> accountMap = getAccounts(accountIds);

		if (triggerAction == npsp.TDTM_Runnable.Action.AfterInsert) {
			for (Contact newCon : newContactList) {
				if (accountMap.containsKey(newCon.AccountId)) {
					Account account;
					if (objectsToUpdateMap.containsKey(newCon.AccountId)) {
						account = (Account) objectsToUpdateMap.get(newCon.AccountId);
					} else {
						account = accountMap.get(newCon.AccountId);
					}
					objectsToUpdateMap.put(account.Id, account);
				}
			}
		} else if (triggerAction == npsp.TDTM_Runnable.Action.AfterUpdate) {
			for (Integer x = 0; x < newContactList.size(); x++) {
				Account account;
				if (objectsToUpdateMap.containsKey(newContactList[x].AccountId)) {
					account = (Account) objectsToUpdateMap.get(newContactList[x].AccountId);
				} else {
					account = accountMap.get(newContactList[x].AccountId);
				}
				objectsToUpdateMap.put(account.Id, account);
			}
		}

		dmlWrapper.objectsToUpdate = objectsToUpdateMap.values();
	}

	public static Map<Id, Account> getAccounts(Set<Id> recordIds) {
		Map<Id, Account> acctMap = new Map<Id, Account>();

		for (Account acc : [SELECT Id, Patient_Contact__c, Patient_LastName__c, Dietary_Restrictions__c FROM Account WHERE Id IN :recordIds ORDER BY Id]) {
			Account acct = new Account(Id = acc.Id, Patient_Contact__c = null, Dietary_Restrictions__c = null);

			if (acc.Patient_Contact__c != null) {
				acct.Patient_Contact__c = acc.Patient_Contact__c;
			}
			if (acc.Dietary_Restrictions__c != null) {
				acct.Dietary_Restrictions__c = acc.Dietary_Restrictions__c;
			}

			acctMap.put(acc.Id, acct);
		}

		return acctMap;
	}
}
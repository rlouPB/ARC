public with sharing class ProcedureResults {
	// Utility Class for Procedure Result trigger
	//called by BEFORE UPDATE trigger populate process fields in before context
	public static void populateProcedureResultBeforeData(Map<Id, sObject> newMap, Map<Id, sObject> oldMap) {
		Map<String, Set<Id>> fieldName2recordIdSetMap = new Map<String, Set<Id>>{ 'Reviewed_By__c' => new Set<Id>() };
		Set<Id> neededUserIds = new Set<Id>();

		for (sObject so : newMap.values()) {
			sObject oldSo = oldMap.get(so.Id);
			if (so.get('Status__c') != oldSo.get('Status__c') && so.get('Status__c') != null) {
				switch on String.valueOf(so.get('Status__c')) {
					when 'Received' {
						if (so.get('Received_Date__c') == null) {
							so.put('Received_Date__c', System.today()); //just populate directly
						}
					}
					when 'Reviewed' {
						so.put('Reviewed_By_Name__c', null);
						if (so.get('Reviewed_By__c') != null) {
							fieldName2recordIdSetMap.get('Reviewed_By__c').add(so.Id);
							neededUserIds.add((Id) so.get('Reviewed_By__c'));
						}
					}
				}
			}
		}

		//get Users needed to populate text Name field on PO
		String userQueryString = QueryUtils.getQueryAll('User', new List<String>()) + ' WHERE Id IN :neededUserIds';
		Map<Id, User> queriedUsersMap = new Map<Id, User>((List<User>) Database.query(userQueryString));

		Set<Id> recordIds = fieldName2recordIdSetMap.get('Reviewed_By__c');
		for (Id recordId : recordIds) {
			sObject so = newMap.get(recordId);
			User theUser = queriedUsersMap.get((Id) so.get('Reviewed_By__c'));
			so.put('Reviewed_By_Name__c', theUser.Professional_Name__c);
		}
	} // end populateProcedureResultBeforeData()
}
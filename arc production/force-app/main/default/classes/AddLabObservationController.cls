public with sharing class AddLabObservationController {
	@AuraEnabled(cacheable=true)
	public static string getCategory(String entryId) {
		string category = '';
		try {
			Compendium_Entry__c entry = [
				SELECT Id, Name, Test_Name__c, Category__c
				FROM Compendium_Entry__c
				WHERE ID = :entryId AND Is_Current__c = TRUE
				WITH SECURITY_ENFORCED
			];
			category = entry.Category__c;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return category;
	}
	@AuraEnabled(cacheable=true)
	public static string addLabObservation(String poId, String selectedEntryId) {
		String retId = '';
		Lab_Observation__c test = new Lab_Observation__c(Procedure_Order__c = poID, Compendium_Entry__c = selectedEntryId);
		Procedure_Order__c order = [SELECT Id , (SELECT Id FROM Procedure_Results__r) FROM Procedure_Order__c where Id =:poId];
		for(Procedure_Result__c r : order.Procedure_Results__r) {
			test.Procedure_Result__c = r.Id;
		}
		insert test;
		retId = test.Id;
		return retId;
	}

}
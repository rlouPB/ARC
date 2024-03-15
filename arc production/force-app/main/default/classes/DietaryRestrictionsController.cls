public with sharing class DietaryRestrictionsController {
	@AuraEnabled
	public static Account getDietaryRestrictionsData(Id patientId) {
		return [SELECT Id, Name, Dietary_Restrictions__c, Dietary_Allergy_Comments__c FROM Account WHERE Id = :patientId LIMIT 1];
	}

	@AuraEnabled
	public static Map<String, String> getOptions() {
		Map<String, String> options = new Map<String, String>();
		Schema.DescribeFieldResult dietaryRestrictionsResult = Account.Dietary_Restrictions__c.getDescribe();
		List<Schema.PicklistEntry> dietaryRestrictionsValues = dietaryRestrictionsResult.getPicklistValues();
		for (Schema.PicklistEntry dr : dietaryRestrictionsValues) {
			options.put(dr.getLabel(), dr.getValue());
		}

		return options;
	}
}
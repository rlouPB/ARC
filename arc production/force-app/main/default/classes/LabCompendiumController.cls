public with sharing class LabCompendiumController {
	@AuraEnabled(cacheable=true)
	public static List<CompediumEntryWrapper> retrieveBundle(String bundleId) {
		List<CompediumEntryWrapper> entries = new List<CompediumEntryWrapper>();
		for (Compendium_Bundle_Assignment__c ba : [
			SELECT Id, Compendium_Entry__r.Id, Compendium_Entry__r.Name, Compendium_Entry__r.Category__c, Compendium_Entry__r.Test_Name__c
			FROM Compendium_Bundle_Assignment__c
			WHERE Compendium_Bundle__c = :bundleId
			WITH SECURITY_ENFORCED
			ORDER BY Compendium_Entry__r.Test_Name__c
		]) {
			entries.add(
				new CompediumEntryWrapper(
					ba.Compendium_Entry__r.Id,
					ba.Compendium_Entry__r.Name,
					ba.Compendium_Entry__r.Test_Name__c,
					ba.Compendium_Entry__r.Category__c
				)
			);
		}
		return entries;
	}
	@AuraEnabled
	public static List<CompediumEntryWrapper> saveBundle(String bundleId, List<String> itemIds) {
		List<CompediumEntryWrapper> entries = new List<CompediumEntryWrapper>();
		List<Compendium_Bundle_Assignment__c> assignments = [
			SELECT Id
			FROM Compendium_Bundle_Assignment__c
			WHERE Compendium_Bundle__c = :bundleId
			WITH SECURITY_ENFORCED
		];
		delete assignments;
		List<Compendium_Bundle_Assignment__c> insertAssignments = new List<Compendium_Bundle_Assignment__c>();
		for (String item : itemIds) {
			insertAssignments.add(new Compendium_Bundle_Assignment__c(Compendium_Bundle__c = bundleId, Compendium_Entry__c = item));
		}
		insert insertAssignments;
		return retrieveBundle(bundleId);
	}

	@AuraEnabled(cacheable=true)
	public static List<CompediumEntryWrapper> retrieveCompendiumEntries() {
		List<CompediumEntryWrapper> entries = new List<CompediumEntryWrapper>();
		for (Compendium_Entry__c ce : [
			SELECT Id, Test_Name__c
			FROM Compendium_Entry__c
			WHERE Is_Current__c = TRUE
			WITH SECURITY_ENFORCED
			ORDER BY Test_Name__c
		]) {
			entries.add(new CompediumEntryWrapper(ce.Id, null, ce.Test_Name__c, null));
		}
		return entries;
	}
}
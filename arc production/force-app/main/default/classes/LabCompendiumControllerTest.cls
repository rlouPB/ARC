@isTest
private with sharing class LabCompendiumControllerTest {
	@testSetup
	static void setup() {
		List<sObject> compendium = Test.loadData(Compendium_Entry__c.sObjectType, 'TestData_Compendium');
		List<sObject> bundle = Test.loadData(Compendium_Bundle__c.sObjectType, 'TestData_CompendiumBundle');
		List<sObject> assignment = Test.loadData(Compendium_Bundle_Assignment__c.sObjectType, 'TestData_CompendiumBundleAssignment');
		System.assertEquals(29, compendium.size());
		System.assertEquals(3, bundle.size());
		System.assertEquals(30, assignment.size());
	}
	@isTest
	private static void unitTest() {
		Compendium_Bundle__c bundle = [SELECT Id FROM Compendium_Bundle__c WHERE Bundle_Name__c = 'Admission' LIMIT 1];
		List<CompediumEntryWrapper> bundleContents = LabCompendiumController.retrieveBundle(bundle.Id);
		System.assertEquals(3, bundleContents.size());
		List<CompediumEntryWrapper> entries = LabCompendiumController.retrieveCompendiumEntries();
		System.assertEquals(29, entries.size());
		List<Compendium_Entry__c> compendiumEntries = [SELECT Id FROM Compendium_Entry__c];
		Integer index = 0;
		List<String> idList = new List<String>();
		for (Compendium_Entry__c entry : compendiumEntries) {
			if (Math.mod(index, 3) == 0) {
				idList.add(entry.Id);
			}
			index++;
		}
		LabCompendiumController.saveBundle(bundle.Id, idList);
	}
}
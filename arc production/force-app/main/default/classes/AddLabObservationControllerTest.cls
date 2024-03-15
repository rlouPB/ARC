@isTest
private with sharing class AddLabObservationControllerTest {
	@testSetup
	static void setup() {
		List<sObject> compendium = Test.loadData(Compendium_Entry__c.sObjectType, 'TestData_Compendium');
		List<sObject> bundle = Test.loadData(Compendium_Bundle__c.sObjectType, 'TestData_CompendiumBundle');
		List<sObject> assignment = Test.loadData(Compendium_Bundle_Assignment__c.sObjectType, 'TestData_CompendiumBundleAssignment');
		// System.assertEquals(29, compendium.size());
		// System.assertEquals(3, bundle.size());
		// System.assertEquals(30, assignment.size());
	}
	@isTest
	private static void unitTest() {
		Compendium_Entry__c entry = [SELECT Id FROM Compendium_Entry__c WHERE Name = 'CBC' LIMIT 1];
		String cat = AddLabObservationController.getCategory(entry.Id);
		// System.assertEquals('LAB', cat);
		try {
			AddLabObservationController.getCategory('123');
			// System.assert(false);
		} catch (Exception e) {
		}
		RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType WHERE IsActive = TRUE AND SobjectType = 'Procedure_Order__c' AND DeveloperName = 'Lab_Order' LIMIT 1];

		Procedure_Order__c po = new Procedure_Order__c(recordtypeId = rt.Id);
		insert po;
		AddLabObservationController.addLabObservation(po.Id, entry.Id);
	}
}
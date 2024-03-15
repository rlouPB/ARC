@isTest
private class Medication_Admin_LineTriggerHandlerTest {
	@isTest(SeeAllData=true)
	static void Medical_Admin_Line_TriggerHandlerTest_1() {
		disco.Util.testLinkedObjLDTrigger('Medication_Administration_Line__c');
	}

	@isTest(SeeAllData=true)
	static void Medical_Admin_Line_TriggerHandlerTest_2() {
		disco.Util.testLinkedObjTrigger('Medication_Administration_Line__c');
	}
}
@isTest
private class Medication_AdminRecordTriggerHandlerTest {
	@isTest(SeeAllData=true)
	static void Medication_AdminRecordTriggerHandlerTest_1() {
		disco.Util.testLinkedObjLDTrigger('Medication_Administration_Record__c');
	}

	@isTest(SeeAllData=true)
	static void Medication_AdminRecordTriggerHandlerTest_2() {
		disco.Util.testLinkedObjTrigger('Medication_Administration_Record__c');
	}
}
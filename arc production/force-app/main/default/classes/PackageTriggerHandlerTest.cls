@isTest
private class PackageTriggerHandlerTest {
	@isTest(SeeAllData=true)
	static void packageTriggerHandlerTest_1() {
		disco.Util.testLinkedObjTrigger('Package__c');
	}

	@isTest(SeeAllData=true)
	static void packageTriggerHandlerTest_2() {
		disco.Util.testLinkedObjLDTrigger('Package__c');
	}
}
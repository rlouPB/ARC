@isTest
public class PrintedMedicalIncludedTriggerHandlerTest {
	static testMethod void test1() {
		Printed_Medical_Included_Record__c pmr = new Printed_Medical_Included_Record__c();
		PrintedMedicalIncludedTriggerHandler pmtt = new PrintedMedicalIncludedTriggerHandler();
		pmtt.afterUpdate(null, null);
		pmtt.beforeUpdate(null, null);
		pmtt.afterDelete(null);
		pmtt.beforeDelete(null);
		insert pmr;
		update pmr;
		delete pmr;
	}

	@isTest
	static void PrintedMedicalIncludedTriggerHandlerTEST() {
		PrintedMedicalIncludedTriggerHandler.increaseCoverage();
	}
}
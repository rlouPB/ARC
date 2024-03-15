@IsTest
public with sharing class TreatmentPlanSnapshotTest {
	@TestSetup
	static void setup() {
		ViewTreatmentPlanCtlTest.doSetup();
	}

	@IsTest
	public static void test() {
		Case tp = [SELECT Id FROM Case LIMIT 1];

		tp.Status = 'Finalized';
		update tp;
		test.startTest();
		TreatmentPlanSnapshot.process(new List<id>{ tp.Id });
		test.stopTest();

		system.assertNotEquals(0, [SELECT COUNT() FROM Snapshot__c WHERE Treatment_Plan__c != NULL], 'Should have created a snapshot of the treatment plan');
	}
}
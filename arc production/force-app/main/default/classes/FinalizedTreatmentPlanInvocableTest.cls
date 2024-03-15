@IsTest
public with sharing class FinalizedTreatmentPlanInvocableTest {
	@TestSetup
	static void setup() {
		ViewTreatmentPlanCtlTest.doSetup();
	}

	@IsTest
	public static void test() {
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Case tp = [SELECT Id FROM Case LIMIT 1];

		tp.Status = 'Finalized';
		update tp;
		TreatmentPlanSnapshot.process(new List<id>{ tp.Id });
		test.startTest();
		FinalizedTreatmentPlanInvocable.TreatmentPlanWrapper wrapper = new FinalizedTreatmentPlanInvocable.TreatmentPlanWrapper();
		wrapper.patientId = patient.Id;
		List<FinalizedTreatmentPlanInvocable.TreatmentPlanWrapper> wrappers = new List<FinalizedTreatmentPlanInvocable.TreatmentPlanWrapper>{ wrapper };
		List<FinalizedTreatmentPlanInvocable.TreatmentPlanWrapper> result = FinalizedTreatmentPlanInvocable.retrieveFinalizedTreatmentPlan(wrappers);
		test.stopTest();
	}
}
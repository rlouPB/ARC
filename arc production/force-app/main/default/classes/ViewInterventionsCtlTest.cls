@isTest
private class ViewInterventionsCtlTest {
	@testSetup
	private static void doSetup() {
		AdmissionScreeningControllerTest.setup();
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Admission__c admission = [SELECT Id, Team__c FROM Admission__c WHERE Patient_Account__c = :patient.Id LIMIT 1];
		Case currentCase = new Case(AccountId = patient.Id, Admission__c = admission.Id);
		insert currentCase;
		patient.Current_Case__c = currentCase.Id;
		update patient;
		admission.Team__c = 'A';
		update admission;

		List<Intervention__c> interventionList = new List<Intervention__c>();
		Intervention__c Psychopharm = new Intervention__c(Case__c = currentCase.Id, Description__c = 'Test Psychopharm', Discipline__c = 'Psychopharm', Start_Date__c = System.today().addDays(-10), Patient_specific_Details__c = 'Test', Status__c = 'Current');
		Intervention__c Therapy = new Intervention__c(Case__c = currentCase.Id, Description__c = 'Test Theraphy', Discipline__c = 'Therapy', Start_Date__c = System.today().addDays(-10), End_Date__c = System.today().addDays(-2), Patient_specific_Details__c = 'Test', Status__c = 'Discontinued');
		interventionList.add(Psychopharm);
		interventionList.add(Therapy);
		insert interventionList;
	}

	@isTest
	private static void testGetInterventions() {
		Case currentTreatmentPlan = [SELECT Id FROM Case LIMIT 1];
		Test.startTest();
		ViewInterventionsCtl.getInterventions(currentTreatmentPlan.Id, true);
		ViewInterventionsCtl.getInterventions(currentTreatmentPlan.Id, false);
		Test.stopTest();
	}
}
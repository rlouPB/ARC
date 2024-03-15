@IsTest
public class ManageInterventionsCtlTest {
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

		List<Assigned_Clinician__c> cliniciansToInsert = new List<Assigned_Clinician__c>();
		cliniciansToInsert.add(new Assigned_Clinician__c(Patient_Account__c = patient.Id, Admission__c = admission.ID, Role__c = 'Psychotherapist', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7)));
		insert cliniciansToInsert;

		List<Intervention__c> interventionList = new List<Intervention__c>();
		Intervention__c Psychopharm = new Intervention__c(Case__c = currentCase.Id, Description__c = 'Test Psychopharm', Discipline__c = 'Psychotherapy', Start_Date__c = System.today().addDays(-10), Patient_specific_Details__c = 'Test', Status__c = 'Current');
		Intervention__c Therapy = new Intervention__c(Case__c = currentCase.Id, Description__c = 'Test Theraphy', Discipline__c = 'Psychotherapy', Start_Date__c = System.today().addDays(-10), End_Date__c = System.today().addDays(-2), Patient_specific_Details__c = 'Test', Status__c = 'Discontinued');
		interventionList.add(Psychopharm);
		interventionList.add(Therapy);
		insert interventionList;
	}

	@isTest
	private static void testGetterMethods() {
		Case currentTreatmentPlan = [SELECT Id FROM Case LIMIT 1];
		Test.startTest();
		system.assertEquals(2, ManageInterventionsCtl.getInterventions(currentTreatmentPlan.Id, true, false).size());
		system.assertEquals(1, ManageInterventionsCtl.getInterventions(currentTreatmentPlan.Id, false, false).size());
		system.assertEquals(2, ManageInterventionsCtl.getInterventionsForDiscipline(currentTreatmentPlan.Id, 'Psychotherapy', true).size());
		system.assert(ManageInterventionsCtl.hasPermissions(currentTreatmentPlan.Id));
		system.assertNotEquals(0, ManageInterventionsCtl.getDiciplinesRecords(currentTreatmentPlan.Id).size());
		system.assertNotEquals(0, ManageInterventionsCtl.getDiciplinesRecordsForDiscipline(currentTreatmentPlan.Id, 'Psychotherapy').size());
		Test.stopTest();
	}

	@istest
	private static void testDiscontinue() {
		Intervention__c inter = [SELECT id FROM Intervention__c WHERE End_Date__c = NULL LIMIT 1];
		Test.startTest();
		ManageInterventionsCtl.discontinueIntervention(inter.Id);
		Test.stopTest();

		system.assertEquals(0, [SELECT COUNT() FROM Intervention__c WHERE End_Date__c = NULL]);
	}

	@istest
	private static void testSaveIntervention() {
		Case currentTreatmentPlan = [SELECT Id FROM Case LIMIT 1];
		system.assertEquals(2, [SELECT COUNT() FROM Intervention__c]);
		Test.startTest();
		ManageInterventionsCtl.saveNewIntervention(currentTreatmentPlan.Id, 'Psychotherapy', 'test', 'test', system.today());
		Test.stopTest();

		system.assertEquals(3, [SELECT COUNT() FROM Intervention__c]);
	}
}
@isTest
private class Ctl_LogNoteTest {
	@TestSetup
	static void testSetup() {
		AdmissionScreeningControllerTest.setup();
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Admission__c admission = [SELECT Id, Team__c FROM Admission__c WHERE Patient_Account__c = :patient.Id LIMIT 1];
		Case currentCase = new Case(AccountId = patient.Id, Admission__c = admission.Id);
		insert currentCase;
		patient.Current_Case__c = currentCase.Id;
		update patient;
		admission.Team__c = 'A';
		update admission;
	}

	@isTest
	static void testLogNote() {
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Basic_Note__c patientNote = new Basic_Note__c(Subject__c = 'Test Basic Note', CalL_Date_Time__c = System.now(), Call_Status__c = 'Logged', Rich_Text_Notes__c = 'this is testing');
		Test.startTest();
		Basic_Note__c basicNote = Ctl_LogNote.createLogNote(JSON.serialize(patientNote), patient.Id);
		Ctl_LogNote.getPatientNoteDetails(basicNote.Id);
		Test.stopTest();
	}
}
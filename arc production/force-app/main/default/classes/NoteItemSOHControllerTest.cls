@isTest
public with sharing class NoteItemSOHControllerTest {
	@testSetup
	static void createData() {
		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		List<Account> accountsToInsert = new List<Account>();
		Account testPatient1 = new Account(Name = 'Admission Test Patient 1');
		accountsToInsert.add(testPatient1);
		insert accountsToInsert;

		List<Admission__c> admissionsToInsert = new List<Admission__c>();
		Admission__c testAdm1 = new Admission__c(Patient_Account__c = testPatient1.Id, Stage__c = 'Open Inquiry');
		admissionsToInsert.add(testAdm1);
		insert admissionsToInsert;
		EGO__c ego = new EGO__c();
		ego.Admission__c = testAdm1.Id;
		insert ego;
		Snapshot__c snap = new Snapshot__c();
		snap.EGO__c = ego.Id;
		Patient_Note__c patientNote = new Patient_Note__c(Account__c = testPatient1.Id);
		patientNote.Admission__c = testAdm1.id;
		patientNote.Status__c = 'Finalized';
		patientNote.Finalized_Date_Time__c = Datetime.now();
		patientNote.Type__c = 'Medical Office Discharge Note';
		insert patientNote;
		snap.Patient_Note__c = patientNote.Id;
		snap.SOH_Html__c = 'Test';
		insert snap;
	}
	@isTest
	private static void unitTest() {
		Account acc = [SELECT Id FROM account LIMIT 1];
		Patient_Note__c patientNote = [SELECT Id FROM Patient_Note__c LIMIT 1];
		NoteItemSOHController.getSOHSnapshotSubset(patientNote.Id, acc.Id, 'Medical Office Discharge Note', 'SOH_Med_Office_Discharge__c');
	}
}
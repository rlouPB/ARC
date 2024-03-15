@isTest
public class AssignedCliniciansTest {
	@TestSetup
	static void makeData() {
		List<Account> accountsToInsert = new List<Account>();
		Account testAccount1 = new Account(Name = 'Test Account 1');
		testAccount1 = (Account) TestFactory_Patient.createSObject(testAccount1);
		accountsToInsert.add(testAccount1);
		insert accountsToInsert;

		List<Admission__c> admissionsToInsert = new List<Admission__c>();
		Admission__c testAdmission1 = new Admission__c(Patient_Account__c = testAccount1.ID, Current_Meds_Step1__c = 'test data identifier for AssignedCliniciansTest');
		admissionsToInsert.add(testAdmission1);
		insert admissionsToInsert;

		List<Assigned_Clinician__c> cliniciansToInsert = new List<Assigned_Clinician__c>();
		Assigned_Clinician__c testClin1 = new Assigned_Clinician__c(Admission__c = testAdmission1.ID, Role__c = 'Team Leader', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7));
		cliniciansToInsert.add(testClin1);
		Assigned_Clinician__c testClin2 = new Assigned_Clinician__c(Admission__c = testAdmission1.ID, Role__c = 'Program Manager', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7));
		cliniciansToInsert.add(testClin2);
		Assigned_Clinician__c testClin3 = new Assigned_Clinician__c(Admission__c = testAdmission1.ID, Role__c = 'Clinical Social Worker', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7), End_Date__c = Date.today().addDays(-3));
		cliniciansToInsert.add(testClin3);
		Assigned_Clinician__c testClin4 = new Assigned_Clinician__c(Admission__c = testAdmission1.ID, Role__c = 'Psychotherapist', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7), End_Date__c = Date.today().addDays(500));
		cliniciansToInsert.add(testClin4);
		insert cliniciansToInsert;
	}

	@isTest
	static void testSync1() {
		List<Assigned_Clinician__c> clinicians = [SELECT Admission__c, Role__c FROM Assigned_Clinician__c];
		system.debug(clinicians);
		List<String> admissionIDs = new List<String>();
		for (Assigned_Clinician__c clin : clinicians) {
			admissionIDs.add(clin.Admission__c);
		}

		Test.startTest();
		//AssignedClinicians.syncAssignedClinicians(admissionIDs);
		AssignedClinicians.invocableSyncAssignedClinicians(admissionIDs);
		Test.stopTest();

		Admission__c testAdmission = [SELECT Team_Leader__c, Program_Manager__c, Community_Program_Rep__c FROM Admission__c WHERE Current_Meds_Step1__c = 'test data identifier for AssignedCliniciansTest' LIMIT 1];
		system.debug(testAdmission);

		// System.assert(testAdmission.Team_Leader__c != null, 'Team Leader should be populated.');
		// System.assert(testAdmission.Program_Manager__c != null, 'Program Manager should be populated.');
		// System.assert(testAdmission.Community_Program_Rep__c == null, 'Community_Program_Rep__c should be null.');
	}

	@isTest
	static void testSync2() {
		List<Assigned_Clinician__c> clinicians = [SELECT Admission__c, Role__c FROM Assigned_Clinician__c];
		system.debug(clinicians);
		List<String> admissionIDs = new List<String>();
		for (Assigned_Clinician__c clin : clinicians) {
			admissionIDs.add(clin.Admission__c);
		}

		Admission__c testAdmission = [SELECT ID FROM Admission__c WHERE Current_Meds_Step1__c = 'test data identifier for AssignedCliniciansTest' LIMIT 1];

		Assigned_Clinician__c testProgramManagerChange = [SELECT ID FROM Assigned_Clinician__c WHERE Admission__c = :testAdmission.ID AND Role__c = 'Program Manager' LIMIT 1];
		testProgramManagerChange.Role__c = 'Psychiatrist';
		update testProgramManagerChange;

		Test.startTest();
		AssignedClinicians.syncAssignedClinicians(admissionIDs);
		Test.stopTest();

		testAdmission = [SELECT Team_Leader__c, Program_Manager__c, Psychiatrist__c FROM Admission__c WHERE Current_Meds_Step1__c = 'test data identifier for AssignedCliniciansTest' LIMIT 1];

		// System.assert(testAdmission.Team_Leader__c != null, 'Team Leader should be populated.');
		// System.assert(testAdmission.Program_Manager__c == null, 'Program Manager should be null.');
		// System.assert(testAdmission.Psychiatrist__c != null, 'Psychiatrist should be populated.');
	}

	@isTest
	static void testFixEndDates_Discharge() {
		SObjectType sObjType = ((SObject) Type.forName('Admission__c').newInstance()).getSObjectType();
		TriggerFactory.Exclusions.add(sObjType);

		Date admitDate = system.today().addDays(-100);
		Date testingDate = system.today().addDays(-2);
		String startingStage = 'Admitted';
		String testingStage = 'Discharged';

		Admission__c testAdmission = [SELECT Id FROM Admission__c LIMIT 1];
		testAdmission.Stage__c = AssignedClinicians.getAdmStagePicklistValue(startingStage);
		testAdmission.Admit_Date__c = admitDate;
		update testAdmission;

		List<Assigned_Clinician__c> unEndedClins = [SELECT Id, Role__c, Start_Date__c FROM Assigned_Clinician__c WHERE Admission__c = :testAdmission.Id AND (End_Date__c = NULL OR End_Date__c > :system.today())];
		// System.assertEquals(3, unEndedClins.size());

		Test.startTest();

		TriggerFactory.Exclusions.remove(sObjType);

		testAdmission.Stage__c = AssignedClinicians.getAdmStagePicklistValue(testingStage);
		testAdmission.Discharge_Date__c = testingDate;
		update testAdmission;

		Test.stopTest();

		List<Assigned_Clinician__c> reCheckClins = [SELECT Id, End_Date__c FROM Assigned_Clinician__c WHERE Id IN :unEndedClins];
		// System.assertEquals(unEndedClins.size(), reCheckClins.size());
		for (Assigned_Clinician__c clin : reCheckClins) {
			// System.assertEquals(testingDate, clin.End_Date__c, reCheckClins);
		}
	}

	@isTest
	static void testFixEndDates_Declined() {
		SObjectType sObjType = ((SObject) Type.forName('Admission__c').newInstance()).getSObjectType();
		TriggerFactory.Exclusions.add(sObjType);

		Date testingDate = system.today().addDays(-2);
		String startingStage = 'Consultation Pending';
		String testingStage = 'Declined';

		Admission__c testAdmission = [SELECT Id FROM Admission__c LIMIT 1];
		testAdmission.Stage__c = AssignedClinicians.getAdmStagePicklistValue(startingStage);
		testAdmission.Consultation_Date__c = testingDate;
		update testAdmission;

		List<Assigned_Clinician__c> unEndedClins = [SELECT Id, Role__c, Start_Date__c FROM Assigned_Clinician__c WHERE Admission__c = :testAdmission.Id AND (End_Date__c = NULL OR End_Date__c > :system.today())];
		// System.assertEquals(3, unEndedClins.size());

		Test.startTest();

		TriggerFactory.Exclusions.remove(sObjType);

		testAdmission.Stage__c = AssignedClinicians.getAdmStagePicklistValue(testingStage);
		update testAdmission;

		Test.stopTest();

		List<Assigned_Clinician__c> reCheckClins = [SELECT Id, End_Date__c FROM Assigned_Clinician__c WHERE Id IN :unEndedClins];
		// System.assertEquals(unEndedClins.size(), reCheckClins.size());
		for (Assigned_Clinician__c clin : reCheckClins) {
			// System.assertEquals(testingDate, clin.End_Date__c);
		}
	}

	@isTest
	static void testFixEndDates_Withdrawn() {
		SObjectType sObjType = ((SObject) Type.forName('Admission__c').newInstance()).getSObjectType();
		TriggerFactory.Exclusions.add(sObjType);

		Date testingDate = system.today().addDays(-2);
		String startingStage = 'Consultation Pending';
		String testingStage = 'Withdrawn';

		Admission__c testAdmission = [SELECT Id FROM Admission__c LIMIT 1];
		testAdmission.Stage__c = AssignedClinicians.getAdmStagePicklistValue(startingStage);
		testAdmission.Consultation_Date__c = testingDate;
		update testAdmission;

		List<Assigned_Clinician__c> unEndedClins = [SELECT Id, Role__c, Start_Date__c FROM Assigned_Clinician__c WHERE Admission__c = :testAdmission.Id AND (End_Date__c = NULL OR End_Date__c > :system.today())];
		// System.assertEquals(3, unEndedClins.size());

		Test.startTest();

		TriggerFactory.Exclusions.remove(sObjType);

		testAdmission.Stage__c = AssignedClinicians.getAdmStagePicklistValue(testingStage);
		update testAdmission;

		Test.stopTest();

		List<Assigned_Clinician__c> reCheckClins = [SELECT Id, End_Date__c FROM Assigned_Clinician__c WHERE Id IN :unEndedClins];
		// System.assertEquals(unEndedClins.size(), reCheckClins.size());
		for (Assigned_Clinician__c clin : reCheckClins) {
			// System.assertEquals(testingDate, clin.End_Date__c);
		}
	}
}
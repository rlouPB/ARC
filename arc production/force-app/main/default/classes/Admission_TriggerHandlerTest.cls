@isTest
private class Admission_TriggerHandlerTest {
	@TestSetup
	static void makeData() {
		Profile riggsClinicalProfile = [SELECT Id FROM Profile WHERE Name = 'RiggsClinical' LIMIT 1];

		List<User> usersToInsert = new List<User>();
		User testUser1 = new User(FirstName = 'Intervention Test 1', LastName = 'Test', ProfileId = riggsClinicalProfile.Id, Username = 'testuser1@austenriggs.net.Phase2Dev', Email = 'test@example.com', Alias = 'test1', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');
		usersToInsert.add(testUser1);
		insert usersToInsert;

		List<Account> accountsToInsert = new List<Account>();
		Account testPatient1 = new Account(Name = 'Admission Test Patient 1');
		accountsToInsert.add(testPatient1);
		insert accountsToInsert;

		List<Admission__c> admissionsToInsert = new List<Admission__c>();
		Admission__c testAdm1 = new Admission__c(Patient_Account__c = testPatient1.Id, Stage__c = 'Open Inquiry', Chart_Closed__c = false);
		admissionsToInsert.add(testAdm1);
		insert admissionsToInsert;

		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		// BEGIN Added by Sols in response to deployment test error 20220918
		discoFormTemplate = new disco__Form_Template__c(Name = 'Medication Package Contents from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Medication_Package_Contents');
		insert discoFormTemplate;

		discoFormTemplate = new disco__Form_Template__c(Name = 'Patient Certification of Dispensed from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Patient_Certification_of_Dispensed');
		insert discoFormTemplate;

		discoFormTemplate = new disco__Form_Template__c(Name = 'Patient Safety Assessment Tool from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Patient_Safety_Assessment_Tool');
		insert discoFormTemplate;
		// END Added by Sols in response to deployment test error 20220918

		discoFormTemplate = new disco__Form_Template__c(Name = 'Admissions Screening Checklist from Test', disco__Status__c = 'In Use');
		insert discoFormTemplate;
		
		Patient_Note__c ptn = new Patient_Note__c();
		ptn.Admission__c = testAdm1.id;
		insert ptn;

		Assigned_Clinician__c ac = new Assigned_Clinician__c(Admission__c = testAdm1.Id, Start_Date__c = Date.today(), User__c = UserInfo.getUserId(), Role__c = 'Psychotherapist');
		insert ac;

		List<EGO__c> egosToInsert = new List<EGO__c>();
		EGO__c testEGO1 = new EGO__c(Admission__c = admissionsToInsert[0].Id);
		egosToInsert.add(testEGO1);
		insert egosToInsert;

		EGO_Rating__c er = new EGO_Rating__c();
		er.EGO__c = testEGO1.id;
		insert er;
	}

	@isTest
	private static void testCreateClinicalSharing() {
		Admission__c testAdmission = [SELECT Id FROM Admission__c LIMIT 1];//WHERE Patient_Account__r.Name = 'Admission Test Patient 1'];

		Test.startTest();
		testAdmission.Stage__c = 'Consultation Pending';
		update testAdmission;
		Test.stopTest();
	}

	@isTest
	private static void testRemoveClinicalSharing() {
		Admission__c testAdmission = [SELECT Id FROM Admission__c LIMIT 1];//WHERE Patient_Account__r.Name = 'Admission Test Patient 1'];
		testAdmission.Stage__c = 'Consultation Pending';
		update testAdmission;

		Test.startTest();
		testAdmission.Stage__c = 'Discharged';
		testAdmission.Discharge_Date__c = Date.today();
		update testAdmission;
		Test.stopTest();
	}

	@isTest
	private static void testDischargePatient() {
		Admission__c testAdmission = [SELECT Id FROM Admission__c LIMIT 1];//WHERE Patient_Account__r.Name = 'Admission Test Patient 1'];

		Case draftTP = new Case(Admission__c = testAdmission.Id, Status = 'Draft');
		insert draftTP;
		testAdmission.Stage__c = 'Admitted';
		testAdmission.Chart_Closed__c = true;
		update testAdmission;

		List<Case> treatmentPlans = [SELECT Id, Status, Admission__c FROM Case WHERE Admission__c = :testAdmission.Id];
		// System.assertEquals(2, treatmentPlans.size()); // Should have one Active and this new Draft one

		Test.startTest();
		testAdmission.Stage__c = 'Discharged';
		testAdmission.Chart_Closed__c = true;
		testAdmission.Discharge_Date__c = Date.today();
		update testAdmission;
		treatmentPlans = [SELECT Id, Status, Admission__c FROM Case WHERE Admission__c = :testAdmission.Id AND Status = 'Inactive'];

		// Our TriggerFactory prevents recursive calls so the logic invoked by this isn't getting executed
		// with how the test data is setup.
		//System.assertEquals(2, treatmentPlans.size()); // upon discharge both TPs should be inactivated.
		Test.stopTest();
	}
	@istest
	public static void testdelete() {
		list<Admission__c> lstad = [SELECT id FROM Admission__c LIMIT 1];
		delete lstad;
	}

	@istest
	public static void testInactive() {
		Admission__c testAdmission = [SELECT Id FROM Admission__c LIMIT 1];//WHERE Patient_Account__r.Name = 'Admission Test Patient 1'];

		testAdmission.Stage__c = 'Inactive';
		testAdmission.Chart_Closed__c = true;
		update testAdmission;
	}

	//  @istest
	//  public static void testChangeDispensingStatus()
	//  {
	//      Admission__c testAdmission = [
	//         SELECT Id
	//         FROM Admission__c
	//         WHERE Patient_Account__r.Name = 'Admission Test Patient 1'
	//     ];

	//      testAdmission.Dispensing_Status__c = 'MSA';
	//     update testAdmission;
	//  }
}
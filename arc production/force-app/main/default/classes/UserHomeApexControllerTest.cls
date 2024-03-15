@isTest
public class UserHomeApexControllerTest {
    
	@TestSetup
	static void setupData(){
		List<Account> accountsToInsert = new List<Account>();
		Account testAccount1 = new Account(
			Name = 'Test Account 1'
		);
		testAccount1 = (Account)TestFactory_Patient.createSObject(testAccount1);
		accountsToInsert.add(testAccount1);
		insert accountsToInsert;

		List<Contact> contactsToInsert = new List<Contact>();
		Contact testContact1 = new Contact(
			FirstName = 'Test',
			LastName = 'Contact 1'
		);
		testContact1 = (Contact)TestFactory_Patient.createSObject(testContact1);
		contactsToInsert.add(testContact1);
		insert contactsToInsert;
		
		List<Outstanding_Tag__c> tagsToInsert = new List<Outstanding_Tag__c>();
		//overdue
		Outstanding_Tag__c tag1 = new Outstanding_Tag__c(
			Document_Type__c = 'Test 1',
			Patient__c = testAccount1.ID,
			Target_Date__c = Date.today().addDays(-1)
		);
		tagsToInsert.add(tag1);
		//next 7 days
		Outstanding_Tag__c tag2 = new Outstanding_Tag__c(
			Document_Type__c = 'Test 2',
			Patient__c = testAccount1.ID,
			Target_Date__c = Date.today().addDays(3)
		);
		tagsToInsert.add(tag2);
		//beyond 7 days: only in totalOpen
		Outstanding_Tag__c tag3 = new Outstanding_Tag__c(
			Document_Type__c = 'Test 3',
			Patient__c = testAccount1.ID,
			Target_Date__c = Date.today().addDays(10)
		);
		tagsToInsert.add(tag3);
		//null target date
		Outstanding_Tag__c tag4 = new Outstanding_Tag__c(
			Document_Type__c = 'Test 4',
			Patient__c = testAccount1.ID,
			Target_Date__c = null
		);
		tagsToInsert.add(tag4);
		insert tagsToInsert;
	}

    @IsTest
    static void test() 
	{
		List<Account> accs = [SELECT Id 
							FROM Account
							WHERE Name = 'Test Account 1'
							LIMIT 1];
		Account patient = accs[0];		

		Test.startTest();
			// UserHomeApexController cont = new UserHomeApexController();
			UserHomeApexController.SummaryInfoWrapper result = UserHomeApexController.getSummaryInfo();
			UserHomeApexController.SummaryInfoWrapper patientResult = UserHomeApexController.getSummaryInfoByPatient(patient.Id);
			UserHomeApexController.SummaryInfoWrapper nullPatientResult = UserHomeApexController.getSummaryInfoByPatient(null);
		Test.stopTest();

		System.assertEquals('1', result.overdueTags);
		System.assertEquals('1', result.dueNext7Days);
		System.assertEquals('4', result.totalOpen);
		
		System.assertEquals('1', patientResult.overdueTags);
		System.assertEquals('1', patientResult.dueNext7Days);
		System.assertEquals('4', patientResult.totalOpen);
		
		System.assertEquals(null, nullPatientResult);
	}

	@IsTest
    static void testGetPatientFileHeaderSetting() {
		Contact c = (Contact) TestFactory_Patient.createSObject(
		new Contact(LastName = 'Test_Patient'),
		true
		);
		Contact accountWithContact = [
		SELECT Id, AccountId
		FROM Contact
		WHERE Id = :c.Id
		];

		Admission__c admission = (Admission__c) TestFactory_Patient.createSObject(
		new Admission__c(
			Patient_Account__c = accountWithContact.AccountId,
			Patient_Contact__c = c.Id,
			Team__c = 'A'
		),
		true
		);
		admission.Service_Type__c = 'Residential';
		update admission;

		List<Account> accounts = [
		SELECT
			Id,
			Name,
			Current_Admission__c,
			Current_Admission__r.Service_Type__c
		FROM Account
		WHERE Id = :accountWithContact.AccountId
		];
		accounts[0].Current_Admission__c = admission.Id;
		upsert accounts[0];
		Map<string,string> ret = UserHomeApexController.getPatientFileHeaderSetting(accounts[0].Id);
		system.debug(ret);
		c.Deceased__c=true;
		update c;
		ret = UserHomeApexController.getPatientFileHeaderSetting(accounts[0].Id);
		admission.Stage__c='Discharged';
		admission.Discharge_Date__c = Date.today();
		update admission;
		ret = UserHomeApexController.getPatientFileHeaderSetting(accounts[0].Id);
		UserHomeApexController.getViewConfiguration(userInfo.getUserId());
	}

	@IsTest
    static void testGetViewConfiguration1() {
		PermissionSet clinPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Activities' LIMIT 1];
		PermissionSetAssignment psa = new PermissionSetAssignment(
			AssigneeId = userInfo.getUserId(),
			PermissionSetId = clinPermSet.Id
		);
		insert psa;
		system.AssertEquals(4, UserHomeApexController.getViewConfiguration(userInfo.getUserId()).size(), 'The returned map should have four items') ;
	}
	// @IsTest
    // static void testGetViewConfiguration2() {
	// 	PermissionSet clinPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Nursing' LIMIT 1];
	// 	PermissionSetAssignment psa = new PermissionSetAssignment(
	// 		AssigneeId = userInfo.getUserId(),
	// 		PermissionSetId = clinPermSet.Id
	// 	);
	// 	insert psa;
	// 	system.AssertEquals(4, UserHomeApexController.getViewConfiguration(userInfo.getUserId()).size(), 'The returned map should have four items') ;
	// }

	@IsTest
	static void testGetPostRenderConfig() {

		Account testAccount1 = new Account(
			Name = 'Test Account GETPOSTRENDERCONFIG'
		);
		testAccount1 = (Account)TestFactory_Patient.createSObject(testAccount1);
		insert testAccount1;

		Admission__c admission = new Admission__c(
			Chart_Closed__c = true,
			Patient_Account__c = testAccount1.Id
		);
		insert admission;

		testAccount1.Current_Admission__c = admission.Id;
		update testAccount1;

		Test.startTest();
		UserHomeApexController.getPostRenderConfig(testAccount1.Id);
		Test.stopTest();
	}

	@IsTest
	static void testShouldShowClinicalPatientFile() {
		Account a = [SELECT Id 
							FROM Account
							LIMIT 1];

		UserHomeApexController.shouldShowClinicalPatientFile(a.Id);
	}
	
}
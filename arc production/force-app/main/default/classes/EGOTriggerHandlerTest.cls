@isTest
private class EGOTriggerHandlerTest {
	@TestSetup
	static void makeData() {
		Profile riggsClinicalProfile = [SELECT Id FROM Profile WHERE Name = 'RiggsClinical' LIMIT 1];

		List<User> usersToInsert = new List<User>();
		User testUser1 = new User(FirstName = 'Intervention Test 1', LastName = 'Test', ProfileId = riggsClinicalProfile.Id, Username = 'testuser1@austenriggs.net.Phase2Dev', Email = 'test@example.com', Alias = 'test1', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');
		usersToInsert.add(testUser1);
		insert usersToInsert;

		List<Account> accountsToInsert = new List<Account>();
		Account testPatient1 = new Account(Name = 'EGO Test Patient 1');
		accountsToInsert.add(testPatient1);
		insert accountsToInsert;

		List<Admission__c> admissionsToInsert = new List<Admission__c>();
		Admission__c testAdm1 = new Admission__c(Patient_Account__c = testPatient1.Id);

		admissionsToInsert.add(testAdm1);
		insert admissionsToInsert;

		EGO__c testEGO = new EGO__c(Admission__c = admissionsToInsert[0].Id);
		insert testEGO;
	}

	@isTest
	private static void testCreation() {
		Admission__c testAdmission = [SELECT Id FROM Admission__c WHERE Patient_Account__r.Name = 'EGO Test Patient 1'];

		Test.startTest();
		EGO__c testEGO = new EGO__c(Admission__c = testAdmission.Id);
		insert testEGO;

		Test.stopTest();
	}

	@istest
	public static void testupdate() {
		EGO__c ee = [SELECT id, status__c FROM EGO__c LIMIT 1];

		ee.Status__c = 'Finalized';
		update ee;
	}
}
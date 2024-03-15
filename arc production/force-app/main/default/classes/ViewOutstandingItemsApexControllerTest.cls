@IsTest
public class ViewOutstandingItemsApexControllerTest {
    
    @testSetup
    static void createData() {
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
		Outstanding_Tag__c tag1 = new Outstanding_Tag__c(
			Document_Type__c = 'Test 1',
			Patient__c = testAccount1.ID,
			Target_Date__c = Date.today().addDays(-1)
		);
		tagsToInsert.add(tag1);
		Outstanding_Tag__c tag2 = new Outstanding_Tag__c(
			Document_Type__c = 'Test 2',
			Patient__c = testAccount1.ID,
			Target_Date__c = Date.today().addDays(3)
		);
		tagsToInsert.add(tag2);
		Outstanding_Tag__c tag3 = new Outstanding_Tag__c(
			Document_Type__c = 'Test 3',
			Patient__c = testAccount1.ID,
			Target_Date__c = Date.today().addDays(10)
		);
		tagsToInsert.add(tag3);
		insert tagsToInsert;
    }

    @IsTest
    static void test() 
	{
		Account patient = [SELECT Id 
							FROM Account 
							WHERE Recordtype.Name = 'Patient' 
							LIMIT 1];
		List<String> categories = new List<String>();
		List<String> category = new List<String> { 'Test 2' };

		Test.startTest();
			ViewOutstandingItemsApexController.OutstandingResult results1 = ViewOutstandingItemsApexController.getResult(UserInfo.getUserId(), patient.Id, 'Open Items');
			ViewOutstandingItemsApexController.OutstandingResult results2 = ViewOutstandingItemsApexController.getResult(UserInfo.getUserId(), null, 'Open Items');
			ViewOutstandingItemsApexController.OutstandingResult results3 = ViewOutstandingItemsApexController.getResult(UserInfo.getUserId(), patient.Id, 'Shared Open Items');
			ViewOutstandingItemsApexController.OutstandingResult results4 = ViewOutstandingItemsApexController.getResult(UserInfo.getUserId(), null, 'Shared Open Items');

			ViewOutstandingItemsApexController.OutstandingResult filteredResults1 = ViewOutstandingItemsApexController.getFilteredResult(UserInfo.getUserID(), category, patient.Id, 'Open Items');
			ViewOutstandingItemsApexController.OutstandingResult filteredResults2 = ViewOutstandingItemsApexController.getFilteredResult(UserInfo.getUserID(), categories, null, 'Open Items');
			ViewOutstandingItemsApexController.OutstandingResult filteredResults3 = ViewOutstandingItemsApexController.getFilteredResult(UserInfo.getUserID(), categories, patient.Id, 'Shared Open Items');
			ViewOutstandingItemsApexController.OutstandingResult filteredResults4 = ViewOutstandingItemsApexController.getFilteredResult(UserInfo.getUserID(), categories, null, 'Shared Open Items');
        Test.stopTest();

		System.assertEquals(3, results1.categories.size());
		System.assertEquals(true, results1.categories.contains('Test 1'));
		System.assertEquals(true, results1.categories.contains('Test 2'));
		System.assertEquals(true, results1.categories.contains('Test 3'));
		System.assertEquals(3, results1.outstandingWrappers.size());

		System.assertEquals(1, filteredResults1.outstandingWrappers.size());
		System.assertEquals('Test 2', filteredResults1.outstandingWrappers[0].DocumentType);
    }

}
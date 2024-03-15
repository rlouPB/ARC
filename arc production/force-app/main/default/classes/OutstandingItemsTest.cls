@isTest
public class OutstandingItemsTest {
	@TestSetup
	static void makeData() {
		ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();

		List<Account> accountsToInsert = new List<Account>();
		Account testAccount1 = new Account(Name = 'Test Account 1');
		testAccount1 = (Account) TestFactory_Patient.createSObject(testAccount1);
		accountsToInsert.add(testAccount1);
		insert accountsToInsert;

		List<Contact> contactsToInsert = new List<Contact>();
		Contact testContact1 = new Contact(FirstName = 'Test', LastName = 'Contact 1');
		testContact1 = (Contact) TestFactory_Patient.createSObject(testContact1);
		contactsToInsert.add(testContact1);
		insert contactsToInsert;

		Case tplan = new Case(AccountId = testAccount1.Id);
		insert tplan;
		test.startTest();

		List<Action_Item__c> actionItemsToInsert = new List<Action_Item__c>();
		Action_Item__c aitem = new Action_Item__c(Treatment_Plan__c = tplan.Id, Status__c = 'Open', RecordTypeId = RecordTypeHelper.getIdByName('Action_Item__c', 'Intervention Change'));
		actionItemsToInsert.add(aitem);
		insert actionItemsToInsert;

		Outstanding_Item_Rule__mdt testRule = [SELECT ID FROM Outstanding_Item_Rule__mdt WHERE sObject__c = 'Action_Item__c' LIMIT 1];

		List<Outstanding_Tag__c> existingTagsToInsert = new List<Outstanding_Tag__c>();
		Outstanding_Tag__c testTag1 = new Outstanding_Tag__c(Outstanding_Item_Rule__c = testRule.ID, Target_Date__c = Date.today().addDays(2), Object__c = 'Action_Item__c', Record_ID__c = aitem.ID);
		existingTagsToInsert.add(testTag1);
		insert existingTagsToInsert;
		test.stopTest();
	}

	static OutstandingItems initializeTestWithPatientNotes() {
		// Initialize OutstandingItems class. This runs the following Methods automatically:
		//  - queryRules()
		//  - queryRecords()
		//  - queryExistingTags()
		//  - buildDraftTags()
		//  - compareTags()
		map<Id, Action_Item__c> itemsMap = new Map<id, Action_Item__c>([SELECT ID FROM Action_Item__c]);
		OutstandingItems testClass = new OutstandingItems(new List<id>(itemsMap.keyset()), 'Action_Item__c');
		return testClass;
	}

	@isTest
	static void testQueryRules() {
		Test.startTest();
		OutstandingItems testClass = initializeTestWithPatientNotes();

		// Check that fields are properly populated.
		//System.assert(OutstandingItems.rules.size() > 0);
		//System.assert(OutstandingItems.objectTypeToImportantFieldsMap.values().size() > 0);
		//System.assert(OutstandingItems.objectTypeToOutstandingItemRulesMap.values().size() > 0);
		Test.stopTest();
	}

	@isTest
	static void testQueryRecords() {
		Test.startTest();
		OutstandingItems testClass = initializeTestWithPatientNotes();

		// Check that fields are properly populated.
		//System.assert(testClass.records.size() > 0);
		Test.stopTest();
	}

	@isTest
	static void testQueryExistingTags() {
		Test.startTest();
		OutstandingItems testClass = initializeTestWithPatientNotes();

		// Check that fields are properly populated.
		//System.assertEquals(1,testClass.existingTagMap.values().size());
		Test.stopTest();
	}

	@isTest
	static void testBuilddraftTags() {
		Test.startTest();
		OutstandingItems testClass = initializeTestWithPatientNotes();

		// Check that fields are properly populated.
		//System.assertEquals(1, testClass.draftTagMap.values().size());
		Test.stopTest();
	}

	@isTest
	static void testCompareTags() {
		OutstandingItems testClass = initializeTestWithPatientNotes();

		//System.assertNotEquals(0, [select count() from Action_Item__c]);

		// Check that fields are properly populated.
		//System.assertEquals(1, testClass.tagsToInsert.size());
		//System.assertEquals(1, testClass.tagsToDelete.size());
	}

	@isTest
	static void testCommitTags() {
		Test.startTest();
		OutstandingItems testClass = initializeTestWithPatientNotes();
		testClass.commitTags(); //already been called in the constructor
		Test.stopTest();

		List<Outstanding_Tag__c> allTags = [SELECT ID FROM Outstanding_Tag__c];
		//System.assertEquals(1, allTags.size());
	}

	@isTest
	static void testCheckOutstandingItems() {
	}

	@isTest
	static void testFireCheckOutstandingEvent() {
		Test.startTest();
		OutstandingItems.fireCheckOutstandingEvent([SELECT ID FROM Action_Item__c]);
		Test.stopTest();
	}

	@isTest
	static void testEmptyList() {
		Test.startTest();
		delete [SELECT ID FROM Action_Item__c];

		OutstandingItems testClass = initializeTestWithPatientNotes();
	}

	@IsTest
	static void testFormatLabel() {
		Account testAccount = new Account(Name = 'MyAccount');
		insert testAccount;

		Contact testCon = new Contact(LastName = 'testLastName', FirstName = 'testFirstName', AccountId = testAccount.Id);
		insert testCon;

		Contact queriedCon = [SELECT Id, FirstName, LastName, Account.Name FROM Contact LIMIT 1];

		String formatString = 'Hello {{LastName}}, I see your Account Name is {{Account.Name}}';

		Test.startTest();

		List<String> stringResults = OutstandingItems.processLabelFormat(formatString, queriedCon);

		Test.stopTest();

		//System.assertEquals(3, stringResults.size());
		//System.assertEquals('Hello ' + queriedCon.LastName + ', I see your Account Name is ' + queriedCon.Account.Name, stringResults[0]);
	}

	@IsTest
	static void testGetFieldValue() {
		Account testAccount = new Account(Name = 'MyAccount');
		insert testAccount;

		Contact testCon = new Contact(LastName = 'testLastName', FirstName = 'testFirstName', AccountId = testAccount.Id);
		insert testCon;

		Contact queriedCon = [SELECT Id, FirstName, LastName, Account.Name FROM Contact LIMIT 1];
		Test.startTest();
		Object accName = OutstandingItems.getFieldValue(queriedCon, 'Account.Name');
		Test.stopTest();
		//System.assertEquals(queriedCon.Account.Name, (String)accName);
	}
}
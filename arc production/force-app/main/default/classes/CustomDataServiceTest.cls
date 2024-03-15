@IsTest
public class CustomDataServiceTest {
	@TestSetup
	static void setup() {
		//Account a = new Account(Name = 'Test Acc');
		//insert a;
	}

	@IsTest
	static void testInsertRecord() {
		Account a = new Account(Name = 'Test Acc');
		sObject s = (sObject) a;
		Test.startTest();
		CustomDataService.insertRecord(s);
		Test.stopTest();
	}

	@IsTest
	static void testUpdateRecord() {
		Account a = new Account(Name = 'Test Acc');
		sObject s = (sObject) a;
		Test.startTest();
		CustomDataService.updateRecord(s);
		Test.stopTest();
	}

	@IsTest
	static void testUpdateRecords() {
		Account a = new Account(Name = 'Test Acc');
		sObject s = (sObject) a;
		sObject[] listObject = new List<sObject>{ s, s };
		Test.startTest();
		CustomDataService.updateRecords(listObject);
		Test.stopTest();
	}
}
@isTest
public class PageAccessTest {

	@testSetup
	static void setup() {

		Account a = new Account(
			Name = 'Test'
		);

		insert a; 

	}

	@isTest
	static void shouldCreateAccessLogRecord() {

		Account a = [SELECT Id FROM Account LIMIT 1];

		Test.startTest(); 

        	PageAccess.log('Account Page', a.Id);

		Test.stopTest();

		List<Access_Log__c> accessLogs = [SELECT Id FROM Access_Log__c];

		System.assertEquals(accessLogs.size(), 1);

	}

}
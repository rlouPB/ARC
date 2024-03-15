@isTest
public with sharing class ProcessLoggingTest {
	
	@TestSetup
	static void setupData(){
		
	}

	@isTest
	static void testMain() {
		Test.startTest();
		ProcessLogging testPL = new ProcessLogging();
		Test.stopTest();
	}

	@isTest
	static void testQuickLog() {
		String processName = 'Test Method';
		String stackTrace = 'Test Method line 100';
		String message = 'Error';

		Test.startTest();
		ProcessLogging.quickProcessLog(processName, stackTrace, message);
		Test.stopTest();

		List<Process_Log__c> processLogs = [SELECT Process__c, Stack_Trace__c, Detail__c
											FROM Process_Log__c];

		system.assertEquals(1, processLogs.size(), 'Incorrect number of Process Logs generated.');
		system.assertEquals('Test Method', processLogs[0].Process__c, 'Process__c has incorrect value.');
		system.assertEquals('Test Method line 100', processLogs[0].Stack_Trace__c, 'Stack_Trace__c has incorrect value.');
		system.assertEquals('Error', processLogs[0].Detail__c, 'Detail__c has incorrect value.');
	}

	@isTest
	static void testQuickLogFuture() {
		String processName = 'Test Method';
		String stackTrace = 'Test Method line 100';
		String message = 'Error';

		Test.startTest();
		ProcessLogging.quickProcessLogFuture(processName, stackTrace, message);
		Test.stopTest();

		List<Process_Log__c> processLogs = [SELECT Process__c, Stack_Trace__c, Detail__c
											FROM Process_Log__c];

		system.assertEquals(1, processLogs.size(), 'Incorrect number of Process Logs generated.');
		system.assertEquals('Test Method', processLogs[0].Process__c, 'Process__c has incorrect value.');
		system.assertEquals('Test Method line 100', processLogs[0].Stack_Trace__c, 'Stack_Trace__c has incorrect value.');
		system.assertEquals('Error', processLogs[0].Detail__c, 'Detail__c has incorrect value.');
	}

}
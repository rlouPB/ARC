@isTest
public with sharing class PrintPhysicalMonitorControllerTest {
	@TestSetup
	static void makeData() {
		PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();
	}

	@IsTest
	static void testPhysicalMonitorFieldAutomation1() {
		Account patient = [SELECT Id, Current_Admission__c FROM Account LIMIT 1];
		Physical_Monitor__c pm2 = new Physical_Monitor__c(Account__c = patient.Id, Status__c = 'Finalized', Height_in__c = 80, BP_Cuff_Size__c = 'Large', View_Height_Weight__c = true, View_Blood_Pressure_Info__c = true, View_Orthostatic_Blood_Pressure_Info__c = true, View_Temperature_Info__c = true, View_Blood_Glucose_Info__c = true, View_Urinalysis__c = true);
		insert pm2;
		PageReference pageRef = Page.PrintPhysicalMonitor;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController csStdCtl = new ApexPages.StandardController(pm2);
		PrintPhysicalMonitorController csController = new PrintPhysicalMonitorController(csStdCtl);
		csController.init();
		csController.getHtmlText();
	}

	@isTest
	private static void unitTest() {
		PrintedPhysicalMonitorMedicalRecord printed = new PrintedPhysicalMonitorMedicalRecord();
		printed.getSDocJunctionLookupField();
		printed.getSObjectName();
		printed.formatLevel2Name(null);
		printed.formatLevel3Name(null);
		printed.collectAvailableMedicalRecords();
		printed.collectSelectedMedicalRecords();
		printed.collectSelectedMedicalRecordsInDateRange();
		printed.findMedicalRecordsForDocumentType(null);
		printed.getMedicalRecordAsHTMLs();
	}
}
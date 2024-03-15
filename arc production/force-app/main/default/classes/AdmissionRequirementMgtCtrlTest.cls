@isTest
public class AdmissionRequirementMgtCtrlTest {
	@testSetup
	static void setup() {
		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		PatientFileTestDataUtil.createPatient();
		PatientFileTestDataUtil.CVCDLInsert();
	}

	@isTest
	static void getAdmissionRequirementTest() {
		List<Account> accList = [SELECT Id, Current_Admission__c FROM Account WHERE Name LIKE 'TestPatient_%'];
		List<Admissions_Requirement__c> newAdReq = [SELECT Id, Name, Applicable_Phase__c, Completed__c, Admission__c FROM Admissions_Requirement__c WHERE Name = 'Clinical_Test'];
		List<Request_Item__c> requestItem = [SELECT Id, Admissions_Requirement__c FROM Request_Item__c WHERE Admissions_Requirement__c = :newAdReq[0].Id];
		String requestItemStr = JSON.serialize(requestItem[0]);

		test.startTest();
		AdmissionRequirementManagementController a = new AdmissionRequirementManagementController();
		AdmissionRequirementManagementController.getAdmissionsRequirement(accList[0].Id, 'Inquiry');
		AdmissionRequirementManagementController.updateAdmissionsRequirement(newAdReq[0].Id, true);
		AdmissionRequirementManagementController.dmlRequestItem(requestItemStr);
		AdmissionRequirementManagementController.requestItems(' ', 'showRequirements', 'showAll', accList[0].Id, accList[0].Current_Admission__c, 'Inquiry');

		test.stopTest();

		// System.assertEquals(accList.size(), 1);
		// System.assertEquals(requestItem.size(), 3);
	}

	@isTest
	static void getOpenRequests() {
		List<Account> accList = [SELECT Id, Current_Admission__c FROM Account WHERE Name LIKE 'TestPatient_%'];
		List<Admissions_Requirement__c> newAdReq = [SELECT Id, Name, Completed__c, Admission__c FROM Admissions_Requirement__c WHERE Name = 'Clinical_Test'];
		List<Request_Item__c> requestItem = [SELECT Id, Admissions_Requirement__c FROM Request_Item__c WHERE Admissions_Requirement__c = :newAdReq[0].Id];

		test.startTest();
		AdmissionRequirementManagementController a = new AdmissionRequirementManagementController();
		AdmissionRequirementManagementController.requestItems(' ', 'showRequirements', 'showOpen', accList[0].Id, accList[0].Current_Admission__c, 'Inquiry');
		test.stopTest();

		// System.assertEquals(accList.size(), 1);
		// System.assertEquals(requestItem.size(), 3);
	}

	@isTest
	static void getAllRequests() {
		List<Account> accList = [SELECT Id, Current_Admission__c FROM Account WHERE Name LIKE 'TestPatient_%'];

		test.startTest();
		AdmissionRequirementManagementController a = new AdmissionRequirementManagementController();
		AdmissionRequirementManagementController.requestItems(' ', 'showAllRequests', 'showOpen', accList[0].Id, accList[0].Current_Admission__c, 'Inquiry');

		test.stopTest();

		// System.assertEquals(accList.size(), 1);
	}

	@isTest
	static void getAllShowALL() {
		List<Account> accList = [SELECT Id, Current_Admission__c FROM Account WHERE Name LIKE 'TestPatient_%'];

		test.startTest();
		AdmissionRequirementManagementController a = new AdmissionRequirementManagementController();
		AdmissionRequirementManagementController.requestItems(' ', 'showAllRequests', 'showAll', accList[0].Id, accList[0].Current_Admission__c, 'Inquiry');

		test.stopTest();

		// System.assertEquals(accList.size(), 1);
	}

	@isTest
	static void insertCDL() {
		List<Account> accList = [SELECT Id, Current_Admission__c FROM Account WHERE Name LIKE 'TestPatient_%'];
		List<Admissions_Requirement__c> newAdReq = [SELECT Id, Name, Completed__c, Admission__c FROM Admissions_Requirement__c WHERE Admission__c = :accList[0].Current_Admission__c];
		List<Request_Item__c> requestItem = [SELECT Id, Admissions_Requirement__c FROM Request_Item__c WHERE Admissions_Requirement__c = :newAdReq LIMIT 1];

		List<ContentVersion> contentVersion = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Title = 'ABC'];
		String encodeValue = EncodingUtil.base64Encode(Blob.valueOf('This is test blob value'));
		test.startTest();
		AdmissionRequirementManagementController a = new AdmissionRequirementManagementController();
		AdmissionRequirementManagementController.uploadCDL(accList[0].Id, contentVersion[0].ContentDocumentId);
		AdmissionRequirementManagementController.getContents(accList[0].Id);
		test.stopTest();

		// System.assertEquals(accList.size(), 1);
		// System.assertEquals(contentVersion.size(), 1);
	}
}
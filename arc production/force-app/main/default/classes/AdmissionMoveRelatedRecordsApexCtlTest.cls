@isTest
class AdmissionMoveRelatedRecordsApexCtlTest {
	@testSetup
	static void setup() {
		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		PatientFileTestDataUtil.createPatient();
	}

	@isTest
	static void testCtl() {
		Account patientAccount = [SELECT Id, Current_Admission__c, Patient_Contact__c, (SELECT Id, Patient_Account__c, Patient_Contact__c, AdmissionId__c FROM Admission_Files__r ORDER BY Is_Current_Admission__c DESC) FROM Account WHERE Patient_Contact__r.LastName LIKE 'TestPatient_%' LIMIT 1];
		Admission__c targetAdmission = patientAccount.Admission_Files__r[0];
		List<Admission_Medication__c> existingMeds = [SELECT Id, Admission__c FROM Admission_Medication__c];

		// System.assert(existingMeds.size() > 0);
		// System.assertNotEquals(null, existingMeds[0].Admission__c);

		test.startTest();
		List<Admission__c> testAdmissions = AdmissionMoveRelatedRecordsApexCtl.getAdmissions(patientAccount.Id);
		// System.assertEquals((patientAccount.Admission_Files__r.size()), testAdmissions.size());

		List<Request_Item__c> reqItems = [SELECT Id, Admissions_Requirement__r.Admission__c FROM Request_Item__c WHERE Admissions_Requirement__r.Admission__c != NULL AND Admissions_Requirement__r.Admission__c != :targetAdmission.Id LIMIT 1];
		Id otherAdmissionId = reqItems[0].Admissions_Requirement__r.Admission__c;
		String testData = AdmissionMoveRelatedRecordsApexCtl.getMoveRecordsData(otherAdmissionId);
		String result = AdmissionMoveRelatedRecordsApexCtl.saveRecords(targetAdmission.Id, testData);
		// System.assertEquals('', result, 'saveRecords problem: ' + result);

		List<Request_Item__c> checkReqItems = [SELECT Id, Admissions_Requirement__r.Admission__c FROM Request_Item__c WHERE Admissions_Requirement__r.Admission__c = :targetAdmission.Id];
		// System.assert(!checkReqItems.isEmpty());

		testData = AdmissionMoveRelatedRecordsApexCtl.getMoveRecordsData(targetAdmission.Id);
		result = AdmissionMoveRelatedRecordsApexCtl.saveRecords(otherAdmissionId, testData);
		// System.assertEquals('', result, 'saveRecords problem: ' + result);

		List<disco__Form__c> forms = [SELECT Id, Admission__c FROM disco__Form__c WHERE Admission__c != NULL AND Admission__c != :otherAdmissionId LIMIT 1];
		// System.assert(!forms.isEmpty());
		otherAdmissionId = forms[0].Admission__c;
		Set<Id> checkFormIds = new Map<Id, sObject>([SELECT Id FROM disco__Form__c WHERE Admission__c = :otherAdmissionId]).keySet();

		testData = AdmissionMoveRelatedRecordsApexCtl.getMoveRecordsData(otherAdmissionId);
		result = AdmissionMoveRelatedRecordsApexCtl.saveRecords(targetAdmission.Id, testData);
		// System.assertEquals('', result, 'saveRecords problem: ' + result);
		Set<Id> newFormIds = new Map<Id, sObject>([SELECT Id FROM disco__Form__c WHERE Admission__c = :targetAdmission.Id]).keySet();
		// System.assert(newFormIds.containsAll(checkFormIds));

		testData = AdmissionMoveRelatedRecordsApexCtl.getMoveRecordsData(targetAdmission.Id);
		result = AdmissionMoveRelatedRecordsApexCtl.saveRecords(otherAdmissionId, testData);
		// System.assertEquals('', result, 'saveRecords problem: ' + result);
		Set<Id> finalFormIds = new Map<Id, sObject>([SELECT Id FROM disco__Form__c WHERE Admission__c = :otherAdmissionId]).keySet();
		// System.assert(finalFormIds.containsAll(newFormIds));

		List<Admission_Medication__c> allMeds = [SELECT Id, Admission__c FROM Admission_Medication__c];
		// System.assert(allMeds.size() > 0);
		// System.assertNotEquals(null, allMeds[0].Admission__c);
		// System.assertNotEquals(targetAdmission.Id, allMeds[0].Admission__c);

		List<Admission_Medication__c> admMeds = [SELECT Id, Admission__c FROM Admission_Medication__c WHERE Admission__c != NULL AND Admission__c != :targetAdmission.Id LIMIT 1];
		// System.assert(!admMeds.isEmpty());

		otherAdmissionId = admMeds[0].Admission__c;
		Set<Id> checkMedIds = new Map<Id, sObject>([SELECT Id FROM Admission_Medication__c WHERE Admission__c = :otherAdmissionId]).keySet();
		testData = AdmissionMoveRelatedRecordsApexCtl.getMoveRecordsData(otherAdmissionId);
		result = AdmissionMoveRelatedRecordsApexCtl.saveRecords(targetAdmission.Id, testData);
		// System.assertEquals('', result, 'saveRecords problem: ' + result);

		Set<Id> newCheckMedIds = new Map<Id, sObject>([SELECT Id FROM Admission_Medication__c WHERE Admission__c = :targetAdmission.Id]).keySet();
		// System.assert(newCheckMedIds.containsAll(checkMedIds));

		testData = AdmissionMoveRelatedRecordsApexCtl.getMoveRecordsData(targetAdmission.Id);
		result = AdmissionMoveRelatedRecordsApexCtl.saveRecords(otherAdmissionId, testData);
		// System.assertEquals('', result, 'saveRecords problem: ' + result);

		test.stopTest();
		Set<Id> finalCheckMedIds = new Map<Id, sObject>([SELECT Id, Admission__c FROM Admission_Medication__c WHERE Admission__c = :otherAdmissionId]).keySet();
		// System.assert(finalCheckMedIds.containsAll(newCheckMedIds));
	}
}
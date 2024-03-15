@istest
public class ScriptSureControllerTest {
	@TestSetup
	static void createTestData() {
		List<User> userList = new List<User>();
		Id profileId = [SELECT Id FROM Profile LIMIT 1].Id;

		for (Integer i = 0; i < 1; i++) {
			//TODO: Create Users
			User objUser = new User(ProfileId = profileId, LastName = 'last-' + String.valueOf(i), Email = 'puser000' + String.valueOf(i) + '@amamama.com', Username = 'puser000' + String.valueOf(i) + '@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias-' + String.valueOf(i), TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', External_ScriptSure_User_Id__c = 'test' + i);

			userList.add(objUser);
		}

		insert userList;

		// Added to accomodate ITrigger/TriggerFactory, 20220708 - Sols
		disco__Form_Template__c[] formTemplates = new List<disco__Form_Template__c>{ new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use'), new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer') };
		insert formTemplates;

		PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();
	}

	static testMethod void searchAllergies() {
		Test.setMock(HttpCalloutMock.class, new ScriptSureMock());

		List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy> resultList = ScriptSureController.searchAllergies('Dihydrotestosterone');
	}
	static testMethod void test1() {
		Test.setMock(HttpCalloutMock.class, new ScriptSureMock());

		try {
			ScriptSureController.getSessionToken();
		} catch (Exception ex) {
		}

		account acc = new account(name = 'test');
		insert acc;
		Prescription__c pres = new Prescription__c();
		pres.Account__c = acc.id;
		insert pres;
		// ScriptSureController.getUrl(acc.id);
		ScriptSureController.getAccount(acc.id);
		ScriptSureController.isExternalScriptSureUser();
		ScriptSureController.getExistingPrescriptions(acc.Id);
		ScriptSureController.updatePrescriptions(new List<Prescription__c>{ pres });
		ScriptSureController.getPatientAllergies(acc.id, 'all');
		ScriptSureController.getPatientAllergies(acc.id, 'active');
	}
	static testMethod void createUpdatePatientAllergy() {
		ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
		Test.setMock(HttpCalloutMock.class, mock);
		Account account = [SELECT Id from Account LIMIT 1];
		String strJson = '{"accountId": "' + account.Id + '",' + '"adverseEventCode": "414285001",' + '"allergyType": 0,' + '"comment": "Test",' + '"irisOnly": false,' + '"name": "Accu-Chek Comfort Curve Test",' + '"onsetDate": "2021-03-16",' + '"patientId": 13148,' + '"reactionId": 1,' + '"severityCode": "2"}';

		ScriptSureController.createUpdatePatientAllergy(strJson, false, '');
	}
	static testMethod void getExistingPrescriptionsWithQueryTest() {
		account acc = new account(name = 'test');
		insert acc;
		Prescription__c pres = new Prescription__c();
		pres.Account__c = acc.id;
		insert pres;
		Patient_Note__c p = new Patient_Note__c();
		p.Contact_Date__c = date.today();
		insert p;
		// ScriptSureController.getUrl(acc.id);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'This Month');
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'This Month', true);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'This Month', false);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'First of Month', true);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'First of Month', false);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'Monthly', true);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'Monthly', false);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'Admit Date', true);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'Admit Date', false);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'Note Date', true);
		ScriptSureController.getExistingPrescriptionsWithQuery(acc.id, p.id, 'Note Date', false);
		ScriptSureController.updateHideInSnapshotFlag(p.id, true);
	}
	@IsTest
	static void getPrescriptions() {
		Test.startTest();
		ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
		Test.setMock(HttpCalloutMock.class, mock);
		Account patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];
		patient.External_Patient_Id__c = '13148';
		ScriptSureController.pullPrescriptions(patient.External_Patient_Id__c, patient.Id);
		ScriptSureController.validateRequiredFields(patient.ID);
		Test.stopTest();
	}
}
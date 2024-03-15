/**
 * Description: This test Class tests the functionality of the ContactSensitiveFormDataCtl class.
 * Created By: Fernando Ortiz
 */

@isTest
private class ContactSensitiveFormDataCtl_Test {
	@testSetup
	static void createTestData() {
		//Needs to add role to the admin in order to create the portal account
		UserRole userRole_1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Admissions_Director' LIMIT 1];
		Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

		User admin = new User(alias = 'admin123', email = 'admin123@noemail.com', emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = adminProfileId, UserRoleId = userRole_1.Id, country = 'United States', IsActive = true, timezonesidkey = 'America/Los_Angeles', username = 'admin123@noemail.com');

		insert admin;

		System.runAs(admin) {
			//TODO: Create Patient Account
			Id accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId();

			Account acc = new Account(Name = 'Patient Test Account', RecordTypeId = accRecTypeId);
			insert acc;

			//TODO: Create Patient Contact
			Id ctcRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();

			Contact ctc = new Contact();
			ctc.AccountId = acc.Id;
			ctc.RecordTypeId = ctcRecTypeId;
			ctc.FirstName = 'Patient';
			ctc.LastName = 'Test';
			ctc.Birthdate = Date.newInstance(1990, 10, 26);
			ctc.Phone = '2587532356';
			ctc.MobilePhone = '7853415987';
			ctc.npe01__WorkPhone__c = '3698521478';
			ctc.Email = 'patient@test.com';
			ctc.npe01__PreferredPhone__c = 'Mobile';

			insert ctc;

			//TODO: Create Test Community User
			Id profileId = [SELECT Id FROM Profile WHERE Name = 'ARC Patient Community User'].Id;

			User user = new User(alias = 'test123', email = 'test123@noemail.com', emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = profileId, country = 'United States', IsActive = true, ContactId = ctc.Id, timezonesidkey = 'America/Los_Angeles', username = 'tester@noemail.com');

			insert user;
		}

	}

	/****** Test Scenarios: ******/

	/**
	 * Name: loadExistingPatientInfo
	 * Description: Try to load existing Patient Info
	 * Type: Positive
	 */
	@IsTest
	static void loadExistingPatientInfo() {
		User patientUser = [SELECT Id FROM User WHERE UserName = 'tester@noemail.com'];

		ContactSensitiveFormDataCtl.PatientWrapper wrapper;

		Test.startTest();

		System.runAs(patientUser) {
			wrapper = ContactSensitiveFormDataCtl.getPatientInformation();
		}

		Test.stopTest();

		System.assert(wrapper != null, 'Null Value was not expected');
		System.assertEquals('patient@test.com', wrapper.Email, 'Patient Email did not match.');
		System.assertEquals(Date.newInstance(1990, 10, 26), wrapper.Birthdate, 'Patient BirthDate did not match.');
		System.assertEquals('2587532356', wrapper.HomePhone, 'Patient Home Phone did not match.');
		System.assertEquals('7853415987', wrapper.MobilePhone, 'Patient Mobile Phone did not match.');
		System.assertEquals('3698521478', wrapper.WorkPhone, 'Patient Work Phone did not match.');
		System.assertEquals('Mobile', wrapper.PreferredPhone, 'Patient Preferred Phone did not match.');
		System.assertEquals('Patient Test', wrapper.Name, 'Patient Work Phone did not match.');
		System.assertEquals(null, wrapper.SSN, 'Patient SSN must be null.');
	}

	/**
	 * Name: loadNoneExistingPatientInfo
	 * Description: Try to load Patient Info from a none "ARC Patient Community User" context.
	 * Type: Negative
	 */
	@IsTest
	static void loadNoneExistingPatientInfo() {
		// Create new User with a none "ARC Patient Community User " profile
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		User patientUser = new User(alias = 'test456', email = 'test456@noemail.com', emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = profileId, country = 'United States', IsActive = true, timezonesidkey = 'America/Los_Angeles', username = 'tester456@noemail.com');

		insert patientUser;

		Test.startTest();

		ContactSensitiveFormDataCtl.PatientWrapper wrapper;

		System.runAs(patientUser) {
			wrapper = ContactSensitiveFormDataCtl.getPatientInformation();
		}

		Test.stopTest();

		System.assert(wrapper == null, 'Null Value was expected');
	}

	/**
	 * Name: loadExistingPatientInfoWithSSN
	 * Description: Try to load existing Patient Info with SSN field populated.
	 * Type: Positive
	 */
	@IsTest
	static void loadExistingPatientInfoWithSSN() {
		User patientUser = [SELECT Id FROM User WHERE UserName = 'tester@noemail.com'];

		ContactSensitiveFormDataCtl.PatientWrapper wrapper;

		Test.startTest();

		System.runAs(patientUser) {
			//Populate SSN
			// Contact ctc = ContactSensitiveFormDataCtl.getContactRecord();
			// ctc.Social_Security_Number__c = '123456789';
			// update ctc;

			ContactSensitiveFormDataCtl.saveSSN('123456789');
			wrapper = ContactSensitiveFormDataCtl.getPatientInformation();
		}

		Test.stopTest();

		System.assert(wrapper != null, 'Null Value was not expected');
		System.assertEquals('***-**-6789', wrapper.SSN, 'Patient SSN did not match.');
	}

	/**
	 * Name: savePatientSSN
	 * Description: Save Patient with a valid SSN.
	 * Type: Positive
	 */
	@IsTest
	static void savePatientSSN() {
		final String ssn = '987654321';
		Boolean isSaved = false;

		User patientUser = [SELECT Id FROM User WHERE UserName = 'tester@noemail.com'];

		Test.startTest();

		System.runAs(patientUser) {
			isSaved = ContactSensitiveFormDataCtl.saveSSN(ssn);
		}

		Test.stopTest();

		List<Contact> ctcList = [SELECT Id, Social_Security_Number__c FROM Contact WHERE Email = :'patient@test.com'];

		System.assert(isSaved, 'True value was expected when saving Patient SSN.');
		System.assert(ctcList.size() == 1, 'Number of Patient records did not match.');
		System.assertEquals(ctcList[0].Social_Security_Number__c, ssn, 'SSN did not match.');
	}

	/**
	 * Name: savePatientSSNAlreadyPopulated
	 * Description: Save Patient with the SSN field already populated.
	 * Type: Positive
	 */
	@IsTest
	static void savePatientSSNAlreadyPopulated() {
		final String ssn = '987654321';
		Boolean isSaved = false;

		User patientUser = [SELECT Id FROM User WHERE UserName = 'tester@noemail.com'];

		Test.startTest();

		System.runAs(patientUser) {
			//Populate SSN
			// Contact ctc = ContactSensitiveFormDataCtl.getContactRecord();
			// ctc.Social_Security_Number__c = '123456789';
			// update ctc;

			isSaved = ContactSensitiveFormDataCtl.saveSSN('123456789');
			isSaved = ContactSensitiveFormDataCtl.saveSSN('123450000');
		}

		Test.stopTest();

		List<Contact> ctcList = [SELECT Id, Social_Security_Number__c FROM Contact WHERE Email = :'patient@test.com'];

		System.assert(!isSaved, 'False value was expected when saving Patient SSN.');
		System.assert(ctcList.size() == 1, 'Number of Patient records did not match.');
		System.assertNOTEquals(ssn, ctcList[0].Social_Security_Number__c, 'SSN should not match.');
	}

	/**
	 * Name: savePatientWithInvalidSSN
	 * Description: Try to Save Patient with an invalid SSN.
	 * Type: Negative
	 */
	@IsTest
	static void savePatientWithInvalidSSN() {
		Boolean isSaved = false;

		User patientUser = [SELECT Id FROM User WHERE UserName = 'tester@noemail.com'];

		Test.startTest();

		System.runAs(patientUser) {
			isSaved = ContactSensitiveFormDataCtl.saveSSN('123');
		}

		Test.stopTest();

		List<Contact> ctcList = [SELECT Id, Social_Security_Number__c FROM Contact WHERE Email = :'patient@test.com'];

		System.assert(!isSaved, 'False value was expected when saving Patient SSN.');
		System.assert(ctcList.size() == 1, 'Number of Patient records did not match.');
		System.assertEquals(null, ctcList[0].Social_Security_Number__c, 'SSN should be null');
	}

	/**
	 * Name: savePatientWithNullSSN
	 * Description: Try to Save Patient with null SSN.
	 * Type: Negative
	 */
	@IsTest
	static void savePatientWithNullSSN() {
		Boolean isSaved = false;

		User patientUser = [SELECT Id FROM User WHERE UserName = 'tester@noemail.com'];

		Test.startTest();

		System.runAs(patientUser) {
			isSaved = ContactSensitiveFormDataCtl.saveSSN(null);
		}

		Test.stopTest();

		List<Contact> ctcList = [SELECT Id, Social_Security_Number__c FROM Contact WHERE Email = :'patient@test.com'];

		System.assert(!isSaved, 'False value was expected when saving Patient SSN.');
		System.assert(ctcList.size() == 1, 'Number of Patient records did not match.');
		System.assertEquals(null, ctcList[0].Social_Security_Number__c, 'SSN should be null');
	}

	/**
	 * Name: savePatientWithEmptySSN
	 * Description: Try to Save Patient with empty SSN.
	 * Type: Negative
	 */
	@IsTest
	static void savePatientWithEmptySSN() {
		Boolean isSaved = false;

		User patientUser = [SELECT Id FROM User WHERE UserName = 'tester@noemail.com'];

		Test.startTest();

		System.runAs(patientUser) {
			isSaved = ContactSensitiveFormDataCtl.saveSSN('');
		}

		Test.stopTest();

		List<Contact> ctcList = [SELECT Id, Social_Security_Number__c FROM Contact WHERE Email = :'patient@test.com'];

		System.assert(!isSaved, 'False value was expected when saving Patient SSN.');
		System.assert(ctcList.size() == 1, 'Number of Patient records did not match.');
		System.assertEquals(null, ctcList[0].Social_Security_Number__c, 'SSN should be null');
	}
}
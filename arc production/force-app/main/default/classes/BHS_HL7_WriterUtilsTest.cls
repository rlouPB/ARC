@isTest
private with sharing class BHS_HL7_WriterUtilsTest {
	@TestSetup
	static void makeData() {
		//Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		Id patientContactRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Patient').getRecordTypeId();
		system.assertNotEquals(null, patientContactRTId, 'Patient Contact record type Id should not be null.');

		//make patients
		List<Contact> patientContactList = new List<Contact>{ new Contact(RecordTypeId = patientContactRTId, Birthdate = Date.newInstance(1962, 6, 10), LastName = 'TestPatient_0', FirstName = 'Dejah', MiddleName = 'Jack', MailingStreet = 'Theo Pines', MailingCity = 'Petaluma', MailingPostalCode = '63823-7028', Phone = '1-339-274-6423', MailingStateCode = 'ND', MailingCountryCode = 'US', Gender__c = 'M') };
		insert patientContactList;

		List<Contact> accWithContacts = [SELECT Id, LastName, AccountId FROM Contact WHERE Id IN :patientContactList ORDER BY LastName];

		List<Admission__c> admissionList = new List<Admission__c>{
			new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id, Stage__c = 'Consultation Pending', Service_Type__c = 'Residential') //good
		};
		insert admissionList;
		Procedure_Order__c po = new Procedure_Order__c(Patient_Account__c = accWithContacts[0].AccountId, Admission__c = admissionList[0].Id, BHS_Message_Control_Id__c = 'TEST000001');
		insert po;
	}

	@istest
	private static void unitTest1() {
		Procedure_Order__c po1 = [
			SELECT
				Admission__r.Patient_Contact__r.Birthdate,
				Admission__r.Patient_Contact__r.FirstName,
				Admission__r.Patient_Contact__r.LastName,
				Admission__r.Patient_Contact__r.MiddleName,
				Admission__r.Patient_Contact__c,
				Admission__r.Patient_Contact__r.MailingState,
				Admission__r.Patient_Contact__r.MailingStreet,
				Admission__r.Patient_Contact__r.MailingCity,
				Admission__r.Patient_Contact__r.MailingCountry,
				Admission__r.Patient_Contact__r.MailingCountryCode,
				Admission__r.Patient_Contact__r.MailingPostalCode,
				Admission__r.Patient_Contact__r.MailingStateCode,
				Admission__r.Patient_Contact__r.Phone,
				Admission__r.Patient_Contact__r.Race__c,
				Admission__r.Patient_Contact__r.Gender__c,
				Patient_Account__r.Age__c,
				Patient_Account__r.Email__c,
				Patient_Account__r.Gender__c,
				Patient_Account__r.Name,
				Admission__r.Admit_Date__c,
				BHS_Message_Control_Id__c,
				Patient_Account__r.BHS_Patient_Id__c,
				Admission__r.Patient_Contact__r.BHS_Patient_Name__c,
				Admission__r.Patient_Contact__r.BHS_Gender_Code__c,
				Admission__r.Patient_Contact__r.BHS_Patient_Address__c
			FROM Procedure_Order__c
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		system.assertEquals('TestPatient_0', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.LastName')), 'LastName should be TestPatient_0');
		system.assertEquals('Dejah', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.FirstName')), 'FirstName should be Dejah');
		system.assertEquals('Jack', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MiddleName')), 'MiddleName should be jack');
		system.assertEquals('Theo Pines', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingStreet')), 'Street Name should be Theo Pines');
		system.assertEquals('Petaluma', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingCity')), 'City should be Petaluma');
		system.assertEquals('63823-7028', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingPostalCode')), 'PostalCode should be 63823-7028');
		system.assertEquals('1-339-274-6423', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.Phone')), 'Phone should be 1-339-274-6423');
		system.assertEquals('ND', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingStateCode')), 'StateCode should be ND');
		system.assertEquals('US', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingCountryCode')), 'COuntryCode should be US');
		system.assertEquals('M', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.Gender__c')), 'Gender should be M');
	}

	@istest
	private static void unitTestMSH() {
		Procedure_Order__c po1 = [
			SELECT
				Admission__r.Patient_Contact__r.Birthdate,
				Admission__r.Patient_Contact__r.FirstName,
				Admission__r.Patient_Contact__r.LastName,
				Admission__r.Patient_Contact__r.MiddleName,
				Admission__r.Patient_Contact__c,
				Admission__r.Patient_Contact__r.MailingState,
				Admission__r.Patient_Contact__r.MailingStreet,
				Admission__r.Patient_Contact__r.MailingCity,
				Admission__r.Patient_Contact__r.MailingCountry,
				Admission__r.Patient_Contact__r.MailingCountryCode,
				Admission__r.Patient_Contact__r.MailingPostalCode,
				Admission__r.Patient_Contact__r.MailingStateCode,
				Admission__r.Patient_Contact__r.Phone,
				Admission__r.Patient_Contact__r.Race__c,
				Admission__r.Patient_Contact__r.Gender__c,
				Patient_Account__r.Age__c,
				Patient_Account__r.Email__c,
				Patient_Account__r.Gender__c,
				Patient_Account__r.Name,
				Admission__r.Admit_Date__c,
				BHS_Message_Control_Id__c,
				Patient_Account__r.BHS_Patient_Id__c,
				Admission__r.Patient_Contact__r.BHS_Patient_Name__c,
				Admission__r.Patient_Contact__r.BHS_Gender_Code__c,
				Admission__r.Patient_Contact__r.BHS_Patient_Address__c
			FROM Procedure_Order__c
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		string ret = BHS_HL7_WriterUtils.transformASegment('MSH', po1, 1);
		system.assertNotEquals(null, ret, 'Should not be null.');
		string[] parts = ret.split('\\|');
		system.assertEquals('MSH', parts[0], 'Message Type should be MSH');
		system.assertEquals('LIFEPOINT', parts[2], 'Message Type should be LIFEPOINT');
		system.assertEquals('AUSTENRIGGS', parts[3], 'Message Type should be AUSTENRIGGS');
	}
	@istest
	private static void unitTestPID() {
		Procedure_Order__c po1 = [
			SELECT
				Admission__r.Patient_Contact__r.Birthdate,
				Admission__r.Patient_Contact__r.FirstName,
				Admission__r.Patient_Contact__r.LastName,
				Admission__r.Patient_Contact__r.MiddleName,
				Admission__r.Patient_Contact__c,
				Admission__r.Patient_Contact__r.MailingState,
				Admission__r.Patient_Contact__r.MailingStreet,
				Admission__r.Patient_Contact__r.MailingCity,
				Admission__r.Patient_Contact__r.MailingCountry,
				Admission__r.Patient_Contact__r.MailingCountryCode,
				Admission__r.Patient_Contact__r.MailingPostalCode,
				Admission__r.Patient_Contact__r.MailingStateCode,
				Admission__r.Patient_Contact__r.Phone,
				Admission__r.Patient_Contact__r.Race__c,
				Admission__r.Patient_Contact__r.Gender__c,
				Patient_Account__r.Age__c,
				Patient_Account__r.Email__c,
				Patient_Account__r.Gender__c,
				Patient_Account__r.Name,
				Patient_Account__r.BHS_Patient_Id__c,
				Admission__r.Patient_Contact__r.BHS_Patient_Name__c,
				Admission__r.Patient_Contact__r.BHS_Gender_Code__c,
				Admission__r.Patient_Contact__r.BHS_Patient_Address__c
			FROM Procedure_Order__c
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		string ret = BHS_HL7_WriterUtils.transformASegment('PID', po1, 1);
		system.assertNotEquals(null, ret, 'Should not be null.');
		string[] parts = ret.split('\\|');

		/*
        system.assertEquals('TestPatient_0', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.LastName')), 'LastName should be TestPatient_0');
        system.assertEquals('Dejah', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.FirstName')), 'FirstName should be Dejah');
        system.assertEquals('Jack', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MiddleName')), 'MiddleName should be jack');
        system.assertEquals('Theo Pines', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingStreet')), 'Street Name should be Theo Pines');
        system.assertEquals('Petaluma', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingCity')), 'City should be Petaluma');
        system.assertEquals('63823-7028', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingPostalCode')), 'PostalCode should be 63823-7028');
        system.assertEquals('1-339-274-6423', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.Phone')), 'Phone should be 1-339-274-6423');
        system.assertEquals('ND', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingStateCode')), 'StateCode should be ND');
        system.assertEquals('US', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.MailingCountryCode')), 'COuntryCode should be US');
        system.assertEquals('M', string.valueOf(BHS_HL7_WriterUtils.extractFieldValues(po1, 'Admission__r.Patient_Contact__r.Gender__c')), 'Gender should be M');
        */
	}
	@istest
	private static void unitTestPV1() {
		string ret = BHS_HL7_WriterUtils.transformASegment('PV1', null, 1);
		system.assertNotEquals(null, ret, 'Should not be null.');
	}
	@istest
	private static void unitTestORC() {
		string ret = BHS_HL7_WriterUtils.transformASegment('ORC', null, 1);
		system.assertNotEquals(null, ret, 'Should not be null.');
	}
	@istest
	private static void unitTestOBR() {
		string ret = BHS_HL7_WriterUtils.transformASegment('OBR', null, 1);
		system.assertNotEquals(null, ret, 'Should not be null.');
	}
	@istest
	private static void unitTestOBX() {
		string ret = BHS_HL7_WriterUtils.transformASegment('OBX', null, 1);
		system.assertNotEquals(null, ret, 'Should not be null.');
	}
	@istest
	private static void testHandleDatetimeValueFailurePath() {
		string ret = BHS_HL7_WriterUtils.handleDatetimeValue(null, null, null);
		system.assertEquals(true, string.isBlank(ret), 'Should be blank.');
		string fieldMappingJSON = '{"field":"not_now","type":"dt","index":"0","asValue":false}';
		BHS_HL7_WriterUtils.FieldMapping m = (BHS_HL7_WriterUtils.FieldMapping) JSON.deserialize(fieldMappingJSON, BHS_HL7_WriterUtils.FieldMapping.class);
		ret = BHS_HL7_WriterUtils.handleDatetimeValue(m, null, null);
		system.assertEquals(true, string.isBlank(ret), 'Should be blank.');
	}
	@istest
	private static void testHandleDateValueFailurePath() {
		string ret = BHS_HL7_WriterUtils.handleDatetimeValue(null, null, null);
		system.assertEquals(true, string.isBlank(ret), 'Should be blank.');
		string fieldMappingJSON = '{"field":"not_now","type":"date","index":"0","asValue":false}';
		BHS_HL7_WriterUtils.FieldMapping m = (BHS_HL7_WriterUtils.FieldMapping) JSON.deserialize(fieldMappingJSON, BHS_HL7_WriterUtils.FieldMapping.class);
		ret = BHS_HL7_WriterUtils.handleDateValue(m, null, null);
		system.assertEquals(true, string.isBlank(ret), 'Should be blank.');
	}
	@istest
	private static void testHandlehandleIntegerValueValueFailurePath() {
		string ret = BHS_HL7_WriterUtils.handleIntegerValue(null, null, null);
		system.assertEquals(true, string.isBlank(ret), 'Should be blank.');
	}
	@istest
	private static void testHandleStringValueFailurePath() {
		string ret = BHS_HL7_WriterUtils.handleStringValue(null, null, null);
		system.assertEquals(true, string.isBlank(ret), 'Should be blank.');
	}
}
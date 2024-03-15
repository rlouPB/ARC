@isTest
private with sharing class PrintedMedIncludedTriggerHandlerTest {
	@TestSetup
	static void makeData() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		List<Contact> patientContactList = new List<Contact>{ new Contact(LastName = 'TestPatient_0', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')) };
		insert patientContactList;
	}
	@isTest
	private static void unitTest() {
		Account patient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];
		Printed_Medical_Record_Request__c request = new Printed_Medical_Record_Request__c(Patient_Account__c = patient.Id);
		TriggerFactory.Recursions.clear();
		insert request;
		SDoc_Junction__c junction = new SDoc_Junction__c(Object_SF_Id__c = '12345');
		insert junction;
		Printed_Medical_Included_Record__c included = new Printed_Medical_Included_Record__c(Printed_Medical_Record_Request__c = request.Id, SDoc_Junction__c = junction.Id);
		TriggerFactory.Recursions.clear();
		insert included;
		TriggerFactory.Recursions.clear();
		included.Document_Type__c = 'test';
		update included;
		TriggerFactory.Recursions.clear();
		delete included;

		List<SDoc_Junction__c> junctionList = [SELECT Id FROM SDoc_Junction__c];
		//System.assertEquals(0, junctionList.size(), 'The SDoc_Junction__c objects should be deleted cascadingly.');
	}
}
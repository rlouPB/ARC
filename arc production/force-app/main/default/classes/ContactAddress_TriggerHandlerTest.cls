@isTest
private class ContactAddress_TriggerHandlerTest {
	@TestSetup
	static void testSetup() {
		/*
        Account personAccount = new Account(RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Patient').getRecordTypeId(),
        FirstName = 'Test', LastName = 'Patient');*/
		Contact patient = new Contact(RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Patient').getRecordTypeId(), FirstName = 'Test', LastName = 'Patient');
		insert patient;
	}

	@isTest
	static void testInsertPrimaryAddress() {
		Contact patient = [SELECT Id, Name, RecordTypeId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact LIMIT 1];
		Test.startTest();
		Contact_Address__c primaryAddress = new Contact_Address__c(Contact__c = patient.Id, City__c = 'Scottsdale', Country__c = 'United States', PostalCode__c = '52001', Primary_Address__c = true, State__c = 'Arizona', Street_1__c = '5000 St. E', Street_2__c = 'PO Box', Street_3__c = 'Extra Long text that exceeds 255 to test max length' + '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' + '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890');
		insert primaryAddress;
		Contact_Address__c newPrimaryAddress = new Contact_Address__c(Contact__c = patient.Id, City__c = 'Scottsdale', Country__c = 'United States', PostalCode__c = '52002', Primary_Address__c = true, State__c = 'Arizona', Street_1__c = '5001 St. E', Street_2__c = 'PO Box', Street_3__c = 'Extra Long text that exceeds 255 to test max length' + '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' + '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890');
		insert newPrimaryAddress;
		primaryAddress.Primary_Address__c = true;
		update primaryAddress;
		Test.stopTest();
		ContactAddress_TriggerHandler h = new ContactAddress_TriggerHandler(new List<Contact_Address__c>{ newPrimaryAddress }, null);
		h.updateAddressForExistingPrimaryAddresses(new Set<id>{ patient.id }, new Set<id>{ patient.id });
	}
}
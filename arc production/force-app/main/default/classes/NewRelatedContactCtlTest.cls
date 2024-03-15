@isTest
public class NewRelatedContactCtlTest {
	public NewRelatedContactCtlTest() {
	}

	@testSetup
	static void makeData() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

		List<Account> patientAccounts = new List<Account>{ new Account(RecordtypeId = recordTypeMap.get('Patient-Account'), Name = 'TestPatient_1', Service_Type_Text__c = 'Residential') };
		insert patientAccounts;

		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient_1', AccountId = patientAccounts[0].Id, RecordTypeId = recordTypeMap.get('Patient-Contact')) };
		insert contactList;

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{ new Related_Contact__c(Contact__c = contactList[0].Id, Account__c = patientAccounts[0].Id, RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')) };
		insert relatedContacts;
	}

	@isTest
	static void testNewRelatedContactCtl() {
		Account Acc = [SELECT Id FROM Account LIMIT 1];
		Related_Contact__c rc = [SELECT Id, Contact__c, Account__c FROM Related_Contact__c LIMIT 1];
		NewRelatedContactCtl.getAccount(Acc.Id);
		NewRelatedContactCtl.saveRelatedContact(rc);
		NewRelatedContactCtl.getRelatedContact(rc.Id);
		NewRelatedContactCtl.getContactRecordTypeDetails();
	}
}
@isTest
public class RelatedContactMergeControllerTest {
	@isTest
	static void testGetRelatedContacts() {
		// disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
		//     Name = 'Psychiatrist Transfer from Test',
		//     disco__Status__c = 'In Use',
		//     DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
		// );
		// insert discoFormTemplate;

		PatientFileTestDataUtil.createPatient();
		Contact patientCon = [SELECT Id, Name, AccountId FROM Contact WHERE LastName = 'TestPatient_1' LIMIT 1];
		List<Related_Contact__c> relConList = [SELECT Id, Name, Account__c FROM Related_Contact__c];
		RelatedContactMergeController.RelatedContacts relatedContactWrapper = new RelatedContactMergeController.RelatedContacts();
		relatedContactWrapper = (RelatedContactMergeController.RelatedContacts) JSON.deserialize(RelatedContactMergeController.getRelatedContacts(patientCon.AccountId), RelatedContactMergeController.RelatedContacts.class);
		//System.assert(relatedContactWrapper.records.size() > 0);
	}

	@isTest
	static void testMergeRelatedContacts() {
		// disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
		//     Name = 'Psychiatrist Transfer from Test',
		//     disco__Status__c = 'In Use',
		//     DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
		// );
		// insert discoFormTemplate;

		PatientFileTestDataUtil.createPatient();
		List<Related_Contact__c> relConList = [SELECT Id, Name, Contact_Name__c, Former__c, Payor__c, Primary_Contact__c, Referrer__c, Role__c, Account__c FROM Related_Contact__c WHERE RecordType.DeveloperName = 'Personal'];
		List<Contact> patientConList = [SELECT Id, FirstName, LastName, MailingCity, MailingState, MailingCountry, MailingPostalCode, AccountId, Account.Current_Admission__c FROM Contact WHERE LastName LIKE '%TestMerge%'];

		Contact nonMasterContact = patientConList[1];
		Task t = new Task(WhoId = nonMasterContact.Id);
		insert t;

		Admissions_Requirement__c req = new Admissions_Requirement__c(Name = 'Clinical', Admission__c = patientConList[1].Account.Current_Admission__c);
		insert req;

		Request_Item__c reqItem = new Request_Item__c(Responsible_Contact__c = nonMasterContact.Id, Admissions_Requirement__c = req.Id);
		insert reqItem;
		//Insurance_Policy__c ip = new Insurance_Policy__c(
		//    Admission__c = nonMasterContact.Account.Current_Admission__c,
		//    Subscriber__c = nonMasterContact.Id,
		//    Insurance_Case_Manager__c = nonMasterContact.Id,
		//    Level_of_Care__c = 'Residential',
		//     );
		//insert ip;

		Related_Contact__c newRc = new Related_Contact__c(Account__c = patientConList[0].AccountId, Contact__c = nonMasterContact.Id, Role__c = 'Father');
		insert newRc;

		//relconList[0].Role__c = relconList[1].Role__c;
		//relconList[0].Payor__c = relconList[1].Payor__c;

		//patientConList[0].MailingCity = patientConList[1].MailingCity;
		//patientConList[0].MailingState = patientConList[1].MailingState;
		//patientConList[0].MailingCountry = patientConList[1].MailingCountry;

		Test.startTest();
		RelatedContactMergeController.mergeRelatedContacts(JSON.serialize(relconList[0]), JSON.serialize(patientConList[0]), relconList[1].Id, nonMasterContact.Id);
		Test.stopTest();

		Related_Contact__c relCon = [SELECT Id, Name, Contact_Name__c, Former__c, Payor__c, Primary_Contact__c, Referrer__c, Role__c, Account__c FROM Related_Contact__c WHERE Id = :relconList[0].Id];
		List<Related_Contact__c> relConNewList = [SELECT Id, Name FROM Related_Contact__c WHERE Id = :relconList[1].Id];
		//System.assert(relCon.Role__c == relconList[1].Role__c);
		System.assert(relConNewList.isEmpty());
		Contact patientCon = [SELECT Id, FirstName, LastName, MailingCity, MailingState, MailingCountry, MailingPostalCode, AccountId FROM Contact WHERE Id = :patientConList[0].Id];
		//System.assert(patientCon.MailingCity == patientConList[1].MailingCity);
	}
}
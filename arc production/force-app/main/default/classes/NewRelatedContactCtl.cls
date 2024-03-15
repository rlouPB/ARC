public with sharing class NewRelatedContactCtl {
	/*
		Purpose: 	Controller for New Related Contact / Edit Related Contact page
		History: 	Class Created 	180718	jn
	*/
	@AuraEnabled
	public static Account getAccount(Id accountId) {
		return [SELECT Id, Current_Admission_Stage__c FROM Account WHERE Id = :accountId];
	}

	@AuraEnabled
	public static Related_Contact__c getRelatedContact(Id relatedContactRecordId) {
		return [SELECT Id, RecordType.Name FROM Related_Contact__c WHERE Id = :relatedContactRecordId];
	}

	@AuraEnabled
	public static String saveRelatedContact(Related_Contact__c relatedContact) {
		upsert relatedContact;

		Contact con = [SELECT Id, Name FROM Contact WHERE Id IN (SELECT Contact__c FROM Related_Contact__c WHERE Id = :relatedContact.Id)];
		return JSON.serialize(con);
	}

	@AuraEnabled
	public static RecordTypeInfoWrapper getContactRecordTypeDetails() {
		List<RecordType> contactRecordTypes = [SELECT Id, DeveloperName, Name FROM RecordType WHERE sObjectType = 'Contact' AND (DeveloperName = 'Personal' OR DeveloperName = 'Professional')];
		List<RecordType> relatedContactRecordTypes = [SELECT Id, DeveloperName, Name FROM RecordType WHERE sObjectType = 'Related_Contact__c'];

		return new RecordTypeInfoWrapper(contactRecordTypes, relatedContactRecordTypes);
	}

	public class RecordTypeInfoWrapper {
		@AuraEnabled
		public List<RecordType> contactRecordTypes;
		@AuraEnabled
		public List<RecordType> relatedContactRecordTypes;

		public RecordTypeInfoWrapper(List<RecordType> contactRecordTypes, List<RecordType> relatedContactRecordTypes) {
			this.contactRecordTypes = contactRecordTypes;
			this.relatedContactRecordTypes = relatedContactRecordTypes;
		}
	}
}
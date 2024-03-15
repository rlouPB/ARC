public with sharing class RelatedContactMergeController {
	private static String contactFieldSet = 'Dedup_View';
	static Set<String> otherContactFields = new Set<String>{ 'Id' };
	private static String relatedContactFieldSet = 'Dedupe_View';

	@AuraEnabled
	public static void mergeRelatedContacts(String relatedConMasterRecordStr, String contactMasterRecordStr, Id nonMasterRelContactId, Id nonMasterContactId) {
		Related_Contact__c relatedConMasterRecord = (Related_Contact__c) JSON.deserialize(relatedConMasterRecordStr, Related_Contact__c.class);
		Contact contactMasterRecord = (Contact) JSON.deserialize(contactMasterRecordStr, Contact.class);
		relatedConMasterRecord.Contact__c = contactMasterRecord.Id;

		Related_Contact__c relContactDel = new Related_Contact__c(Id = nonMasterRelContactId);
		Contact nonMasterContact = new Contact();

		Map<Id, disco__Form__c> formsToUpdateMap = new Map<Id, disco__Form__c>();
		Map<Id, Account> accsToUpdateMap = new Map<Id, Account>();
		Map<Id, Insurance_Policy__c> insPolsToUpdateMap = new Map<Id, Insurance_Policy__c>();
		Map<Id, Task> tasksToUpdateMap = new Map<Id, Task>();
		Map<Id, Request_Item__c> reqItemsToUpdateMap = new Map<Id, Request_Item__c>();
		Map<Id, Related_Contact__c> rcsToUpdateMap = new Map<Id, Related_Contact__c>();
		Map<Id, Basic_Note__c> basicNoteToUpdateMap = new Map<Id, Basic_Note__c>(); // Added By Fernando Ortiz
		Map<Id, Contact_Address__c> contactAddressesToUpdateMap = new Map<Id, Contact_Address__c>(); // Added By Fernando Ortiz
		Map<Id, Legal_Name__c> legalNamesToUpdateMap = new Map<Id, Legal_Name__c>(); // Added By Fernando Ortiz

		for (disco__Form__c form : [SELECT Id, Related_Contact__r.Name FROM disco__Form__c WHERE Related_Contact__c = :relContactDel.Id]) {
			formsToUpdateMap.put(form.Id, new disco__Form__c(Id = form.Id, Related_Contact__c = relatedConMasterRecord.Id));
		}

		if (String.isNotBlank(nonMasterContactId)) {
			nonMasterContact = [
				SELECT
					Id,
					AccountId,
					(SELECT Id, disco__Form_Contact__c FROM disco__Forms__r),
					(SELECT Id, WhoId FROM Tasks),
					(SELECT Id, Contact__c FROM Related_Contacts__r),
					(SELECT Id, Emergency_Contact__c FROM Accounts_Emergency__r),
					(SELECT Id, Subscriber__c FROM Insurance_Policies__r),
					// (SELECT Id, Insurance_Case_Manager__c from Insurance_Policies1__r),
					(SELECT Id, Responsible_Contact__c FROM Request_Items__r),
					(SELECT Id, Account__c, Contact__c FROM Basic_Notes__r), // Added By Fernando Ortiz
					(SELECT Id, Contact__c, Primary_Address__c FROM Contact_Addresses__r) // Added By Fernando Ortiz
				FROM Contact
				WHERE Id = :nonMasterContactId
			]; //(SELECT Id from Patient_Notes__r),

			//for (disco__Form__c form : nonMasterContact.disco__Forms__r) {
			//    disco__Form__c thisForm = form;
			//    if (formsToUpdateMap.containsKey(form.Id)) {
			//        thisForm = formsToUpdateMap.get(form.Id);
			//    }
			//    thisForm.disco__Form_Contact__c = contactMasterRecord.Id;
			//    formsToUpdateMap.put(thisForm.Id, thisForm);
			//}

			for (Account obj : nonMasterContact.Accounts_Emergency__r) {
				obj.Emergency_Contact__c = contactMasterRecord.Id;
				accsToUpdateMap.put(obj.Id, obj);
			}

			for (Insurance_Policy__c obj : nonMasterContact.Insurance_Policies__r) {
				obj.Subscriber__c = contactMasterRecord.Id;
				insPolsToUpdateMap.put(obj.Id, obj);
			}

			// for (Insurance_Policy__c obj : nonMasterContact.Insurance_Policies1__r) {
			//     Insurance_Policy__c pol = insPolsToUpdateMap.get(obj.Id);
			//     if (pol == null) pol = obj;
			//     pol.Insurance_Case_Manager__c = contactMasterRecord.Id;
			//     insPolsToUpdateMap.put(obj.Id, pol);
			// }

			for (Request_Item__c obj : nonMasterContact.Request_Items__r) {
				obj.Responsible_Contact__c = contactMasterRecord.Id;
				reqItemsToUpdateMap.put(obj.Id, obj);
			}

			for (Task obj : nonMasterContact.Tasks) {
				obj.WhoId = contactMasterRecord.Id;
				tasksToUpdateMap.put(obj.Id, obj);
			}

			for (Related_Contact__c obj : nonMasterContact.Related_Contacts__r) {
				if (obj.Id != relContactDel.Id) {
					obj.Contact__c = contactMasterRecord.Id;
					//obj.Contact__c = relatedConMasterRecord.Contact__c;
					rcsToUpdateMap.put(obj.Id, obj);
				}
			}

			for (Basic_Note__c bNote : nonMasterContact.Basic_Notes__r) {
				// Added By Fernando Ortiz
				bNote.Account__c = contactMasterRecord.AccountId;
				bNote.Contact__c = contactMasterRecord.Id; // Need to validate and Confirm with David
				basicNoteToUpdateMap.put(bNote.Id, bNote);
			}

			for (Contact_Address__c ctcAddress : nonMasterContact.Contact_Addresses__r) {
				// Added By Fernando Ortiz
				ctcAddress.Contact__c = contactMasterRecord.Id;
				ctcAddress.Primary_Address__c = false; // Need to validate and Confirm with David
				contactAddressesToUpdateMap.put(ctcAddress.Id, ctcAddress);
			}

			for (Legal_Name__c lName : [SELECT Id, Patient__c FROM Legal_Name__c WHERE Patient__c = :nonMasterContact.AccountId]) {
				lName.Patient__c = contactMasterRecord.AccountId;
				legalNamesToUpdateMap.put(lName.Id, lName);
			}
		}

		update formsToUpdateMap.values();
		update tasksToUpdateMap.values();
		update accsToUpdateMap.values();
		update insPolsToUpdateMap.values();
		update reqItemsToUpdateMap.values();
		update rcsToUpdateMap.values();
		update basicNoteToUpdateMap.values(); // Added By Fernando Ortiz
		update contactAddressesToUpdateMap.values(); // Added By Fernando Ortiz
		update legalNamesToUpdateMap.values(); // Added By Fernando Ortiz

		if (relContactDel.Id != null) {
			relContactDel.OwnerId = UserInfo.getUserId();
			update relContactDel;
			delete relContactDel;
		}

		update relatedConMasterRecord;
		if (contactMasterRecord.Id != null)
			update contactMasterRecord;

		if (nonMasterContact.Id != null) {
			nonMasterContact.OwnerId = UserInfo.getUserId();
			update nonMasterContact;
			delete nonMasterContact;

			Account a = new Account(Id = nonMasterContact.AccountId);
			a.OwnerId = UserInfo.getUserId();
			update a;
			delete a;
		}
	}

	@AuraEnabled
	public static String getRelatedContacts(String patientId) {
		RelatedContacts data = new RelatedContacts();
		List<RecordWrapper> records = new List<RecordWrapper>();

		List<Field> relatedContactFieldList = new List<Field>();
		List<Field> contactFieldList = new List<Field>();
		String conFieldsStr = '';
		String relatedConFieldsStr = '';
		String queryStr = '';
		Schema.FieldSet relatedConFS = Schema.SObjectType.Related_Contact__c.fieldSets.getMap().get(relatedContactFieldSet);
		Schema.FieldSet conFS = Schema.SObjectType.Contact.fieldSets.getMap().get(contactFieldSet);

		Set<String> fieldsToQuery = new Set<String>();

		if (relatedConFS != null) {
			//relatedConFieldsStr = 'Id';
			Schema.SObjectType t = Schema.getGlobalDescribe().get('Related_Contact__c');
			Schema.DescribeSObjectResult r = t.getDescribe();

			for (Schema.FieldSetMember field : relatedConFS.getFields()) {
				String relationshipName = '';

				if (String.valueOf(field.getType()) == 'REFERENCE') {
					Schema.DescribeFieldResult f = r.fields.getMap().get(field.getFieldPath()).getDescribe();
					relationshipName = f.getRelationshipName() + '.Name';
					//relatedConFieldsStr += ', '+field.getFieldPath()+', '+relationshipName;
					fieldsToQuery.add(field.getFieldPath());
					fieldsToQuery.add(relationshipName);
				} else {
					fieldsToQuery.add(field.getFieldPath());
					//relatedConFieldsStr += ', '+field.getFieldPath();
				}

				relatedContactFieldList.add(new Field(field.getLabel(), field.getFieldPath(), String.valueOf(field.getType()), relationshipName));
			}
		}

		Boolean firstField = true;

		for (String field : fieldsToQuery) {
			if (firstField) {
				firstField = false;
			} else {
				relatedConFieldsStr += ', ';
			}
			relatedConFieldsStr += field;
		}

		if (conFS != null) {
			//conFieldsStr = 'Contact__r.Id';
			Schema.SObjectType t = Schema.getGlobalDescribe().get('Contact');
			Schema.DescribeSObjectResult r = t.getDescribe();

			fieldsToQuery = new Set<String>();
			fieldsToQuery.addAll(otherContactFields);
			for (Schema.FieldSetMember field : conFS.getFields()) {
				String relationshipName = '';
				String parentRelationshipName = 'Contact__r.';

				if (String.valueOf(field.getType()) == 'REFERENCE') {
					Schema.DescribeFieldResult f = r.fields.getMap().get(field.getFieldPath()).getDescribe();
					relationshipName = f.getRelationshipName() + '.Name';
					fieldsToQuery.add(parentRelationshipName + field.getFieldPath());
					fieldsToQuery.add(relationshipName);
				} else {
					fieldsToQuery.add(parentRelationshipName + field.getFieldPath());
				}

				contactFieldList.add(new Field(field.getLabel(), field.getFieldPath(), String.valueOf(field.getType()), relationshipName));
			}
		}

		firstField = true;

		for (String field : fieldsToQuery) {
			if (firstField)
				firstField = false;
			else {
				conFieldsStr += ', ';
			}
			conFieldsStr += field;
		}

		queryStr = 'SELECT ' + relatedConFieldsStr + ', ' + conFieldsStr + ', RecordType.Id' + ' FROM Related_Contact__c' + ' WHERE Account__c = :patientId AND Role__c != \'Patient\'' + ' ORDER BY Recordtype.Name, Contact__r.LastName ASC, Contact__r.FirstName ASC';
		List<Related_Contact__c> relatedContacts = Database.query(queryStr);

		if (!relatedContacts.isEmpty()) {
			for (Related_Contact__c rc : relatedContacts) {
				RecordWrapper rw = new RecordWrapper();
				rw.relatedContactRec = rc;
				rw.contactRec = rc.Contact__r;
				records.add(rw);
			}
		}

		data.allFieldSet = new FieldSetWrapper(relatedContactFieldList, contactFieldList);
		data.records = records;

		return JSON.serialize(data);
	}

	public class RelatedContacts {
		public FieldSetWrapper allFieldSet;
		public List<RecordWrapper> records;
	}

	public class FieldSetWrapper {
		public List<Field> relatedContactFS;
		public List<Field> contactFS;

		public FieldSetWrapper(List<Field> relatedContactFS, List<Field> contactFS) {
			this.relatedContactFS = relatedContactFS;
			this.contactFS = contactFS;
		}
	}

	public class RecordWrapper {
		public Related_Contact__c relatedContactRec;
		public Contact contactRec;
		public Boolean isSelected;
	}

	public class Field {
		public String label;
		public String name;
		public String type;
		public String referenceName;
		public Field(String label, String name, String type, String referenceName) {
			this.label = label;
			this.name = name;
			this.type = type;
			this.referenceName = referenceName;
		}
	}
}
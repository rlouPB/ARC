public with sharing class PatientDeDupeController {
	static List<String> extraContactFields = new List<String>{ 'Id', 'Name', 'Phone', 'MailingCity', 'MailingState', 'Gender__c', 'AccountId', 'Distinguished_Name__c' };
	static List<String> extraAccountFields = new List<String>{ 'Account.Current_Admission_Stage__c' };

	@AuraEnabled
	public static Boolean isDuplicateRecordsExist(String recordId) {
		Integer anyNonDifferentItemsCount = 0;
		List<Account> accs = [SELECT Patient_Contact__c FROM Account WHERE Id = :recordId];
		if (!accs.isEmpty()) {
			Id conId = accs[0].Patient_Contact__c;

			Boolean hasDuplicateRecordSets = false;

			List<DuplicateRecordItem> duplicatePatients = [SELECT Id, DuplicateRecordSetId, Different_Person__c FROM DuplicateRecordItem WHERE RecordId = :conId];
			Set<Id> dupSetIds = new Set<Id>();
			for (DuplicateRecordItem recItem : duplicatePatients) {
				if (!recItem.Different_Person__c) {
					return true;
				}
				dupSetIds.add(recItem.DuplicateRecordSetId);
			}

			anyNonDifferentItemsCount = [SELECT COUNT() FROM DuplicateRecordItem WHERE Different_Person__c = FALSE AND DuplicateRecordSetId IN :dupSetIds];
		}
		return (anyNonDifferentItemsCount > 0);
	}

	@AuraEnabled
	public static void setAsDifferentPeople(String conIds, Boolean newDifferentValue) {
		Set<Id> conIdSet = (Set<Id>) JSON.deserialize(conIds, Set<Id>.class);
		List<DuplicateRecordItem> dupRecItems = [SELECT Id FROM DuplicateRecordItem WHERE RecordId IN :conIdSet];

		for (DuplicateRecordItem dupItem : dupRecItems) {
			dupItem.Different_Person__c = newDifferentValue;
		}
		update dupRecItems;
	}

	@AuraEnabled
	public static String getDuplicateRecordSet(String recordId) {
		DedupeWrapper deDupeWrapper = new DedupeWrapper();
		FieldSetWrapper allFieldSetWrapper = new FieldSetWrapper();
		List<Contact> con = [SELECT Id FROM Contact WHERE AccountId = :recordId];
		List<Contact> duplicatePatients = new List<Contact>();
		List<RecordsWrapper> recordsWrapperList = new List<RecordsWrapper>();
		Set<Id> dubRecSetIds = new Set<Id>();

		Schema.FieldSet accFS = Schema.SObjectType.Account.fieldSets.getMap().get('Dedup_View');
		Schema.FieldSet conFS = Schema.SObjectType.Contact.fieldSets.getMap().get('Dedup_View');
		List<Field> accountFieldList = new List<Field>();
		List<Field> contactFieldList = new List<Field>();
		String conFieldsStr = '';
		String accFieldsStr = '';

		String queryStr = '';

		if (conFS != null) {
			Schema.SObjectType t = Schema.getGlobalDescribe().get('Contact');
			Schema.DescribeSObjectResult r = t.getDescribe();

			conFieldsStr = String.join(extraContactFields, ',');
			for (Schema.FieldSetMember field : conFS.getFields()) {
				String relationshipName = '';
				Boolean isFormulaField = r.fields.getMap().get(field.getFieldPath()).getDescribe().isCalculated();

				if (!isFormulaField) {
					if (!extraContactFields.contains(field.getFieldPath())) {
						conFieldsStr += ', ' + field.getFieldPath();

						if (String.valueOf(field.getType()) == 'REFERENCE') {
							Schema.DescribeFieldResult f = r.fields.getMap().get(field.getFieldPath()).getDescribe();
							relationshipName = f.getRelationshipName() + '.Name';

							conFieldsStr += ', ' + relationshipName;
						}
					}

					contactFieldList.add(new Field(field.getLabel(), field.getFieldPath(), String.valueOf(field.getType()), relationshipName));
				}
			}
		}

		if (accFS != null) {
			Schema.SObjectType t = Schema.getGlobalDescribe().get('Account');
			Schema.DescribeSObjectResult r = t.getDescribe();

			accFieldsStr = String.join(extraAccountFields, ',');
			for (Schema.FieldSetMember field : accFS.getFields()) {
				String relationshipName = '';
				Boolean isFormulaField = r.fields.getMap().get(field.getFieldPath()).getDescribe().isCalculated();

				if (!isFormulaField) {
					if (!extraAccountFields.contains(field.getFieldPath())) {
						accFieldsStr += ', Account.' + field.getFieldPath();

						if (String.valueOf(field.getType()) == 'REFERENCE') {
							Schema.DescribeFieldResult f = r.fields.getMap().get(field.getFieldPath()).getDescribe();
							relationshipName = f.getRelationshipName() + '.Name';

							accFieldsStr += ', Account.' + relationshipName;
						}
					}

					accountFieldList.add(new Field(field.getLabel(), field.getFieldPath(), String.valueOf(field.getType()), relationshipName));
				}
			}
		}

		queryStr = conFieldsStr + ', ' + accFieldsStr;

		allFieldSetWrapper.accountFS = accountFieldList;
		allFieldSetWrapper.contactFS = contactFieldList;

		deDupeWrapper.allFieldSet = allFieldSetWrapper;

		if (!con.isEmpty()) {
			List<DuplicateRecordItem> duplicateRecordItems = [SELECT Id, DuplicateRecordSetId, Different_Person__c FROM DuplicateRecordItem WHERE RecordId = :con[0].Id]; // AND Different_Person__c = False];

			if (!duplicateRecordItems.isEmpty()) {
				for (DuplicateRecordItem dupRecItem : duplicateRecordItems) {
					dubRecSetIds.add(dupRecItem.DuplicateRecordSetId);
				}

				if (!dubRecSetIds.isEmpty()) {
					List<DuplicateRecordItem> dupRecItems = [SELECT Id, RecordId, DuplicateRecordSetId, Different_Person__c FROM DuplicateRecordItem WHERE DuplicateRecordSetId IN :dubRecSetIds]; // AND Different_Person__c = False];
					Map<Id, List<DuplicateRecordItem>> conId2DupRecItemsMap = new Map<Id, List<DuplicateRecordItem>>();
					for (DuplicateRecordItem rec : dupRecItems) {
						if (!conId2DupRecItemsMap.containsKey(rec.RecordId))
							conId2DupRecItemsMap.put(rec.RecordId, new List<DuplicateRecordItem>());

						conId2DupRecItemsMap.get(rec.RecordId).add(rec);
					}

					if (!conId2DupRecItemsMap.isEmpty()) {
						Set<Id> conIds = conId2DupRecItemsMap.keySet();
						queryStr = 'SELECT ' + conFieldsStr + ', ' + accFieldsStr + ' FROM Contact' + ' WHERE Id IN :conIds';
						duplicatePatients = Database.query(queryStr);

						Integer rowCount = 1;
						for (contact conRec : duplicatePatients) {
							RecordsWrapper recWrapper = new RecordsWrapper();

							Account accRec = conRec.Account;

							recWrapper.isDifferent = true;
							List<DuplicateRecordItem> recItems = conId2DupRecItemsMap.get(conRec.Id);
							for (DuplicateRecordItem recItem : recItems) {
								if (!recItem.Different_Person__c) {
									recWrapper.isDifferent = false;
									break;
								}
							}

							recWrapper.rowNumber = rowCount;
							recWrapper.contactRec = conRec;
							recWrapper.accountRec = accRec;
							recordsWrapperList.add(recWrapper);

							rowCount++;
						}

						Integer nonDifferentCount = autoSelectWrappers(recordsWrapperList);
						if (nonDifferentCount == 1) {
							for (RecordsWrapper rw : recordsWrapperList) {
								rw.isDifferent = false;
							}
							autoSelectWrappers(recordsWrapperList);
						}
					}
				}
			}
			deDupeWrapper.records = recordsWrapperList;
		}
		return JSON.serialize(deDupeWrapper);
	}

	//select up to 2 wrappers that are not marked as different
	static Integer autoSelectWrappers(List<RecordsWrapper> recordsWrapperList) {
		Integer nonDifferentCount = 0;

		for (RecordsWrapper recWrapper : recordsWrapperList) {
			recWrapper.isSelected = false;
			if (nonDifferentCount < 2 && !recWrapper.isDifferent) {
				recWrapper.isSelected = true;
				nonDifferentCount++;
			}
		}

		return nonDifferentCount;
	}

	@AuraEnabled
	public static RecordsWrapper mergePatients(String masterRecStr, String secondaryConId) {
		RecordsWrapper masterRec;
		Savepoint sp = Database.setSavepoint();
		try {
			masterRec = (RecordsWrapper) JSON.deserialize(masterRecStr, RecordsWrapper.class);

			String masterAccountId = masterRec.accountRec.Id;
			String masterContactId = masterRec.contactRec.Id;

			List<Account> secondaryAccounts = [
				SELECT Id, Current_Case__c, (SELECT Id FROM Admission_Files__r), (SELECT Id, WhoId FROM Tasks), (SELECT Id, Role__c FROM Related_Contacts__r), (SELECT Id FROM disco__Forms__r), (SELECT Id, AccountId, Admission__c FROM Cases) //Added by Fernando
				FROM Account
				WHERE Patient_Contact__c = :secondaryConId
			];
			Account secondaryAccount = secondaryAccounts[0];
			Account masterAccount = [SELECT Id, Current_Admission__c, (SELECT Id FROM Related_Contacts__r WHERE Role__c = 'Patient') FROM Account WHERE Id = :masterAccountId];
			Id masterPatientRcId;
			if (!masterAccount.Related_Contacts__r.isEmpty())
				masterPatientRcId = masterAccount.Related_Contacts__r[0].Id;

			/*********** UPDATE CHILDREN RECORDS ***********/

			List<Basic_Note__c> basicNoteToUpdateList = new List<Basic_Note__c>(); // Added By Fernando Ortiz
			List<Contact_Address__c> contactAddressesToUpdateList = new List<Contact_Address__c>(); // Added By Fernando Ortiz
			List<Legal_Name__c> legalNamesToUpdateList = new List<Legal_Name__c>(); // Added By Fernando Ortiz

			Contact nonMasterContact = [
				SELECT
					Id,
					AccountId,
					(SELECT Id, Account__c, Contact__c FROM Basic_Notes__r), // Added By Fernando Ortiz
					(SELECT Id, Contact__c, Primary_Address__c FROM Contact_Addresses__r) // Added By Fernando Ortiz
				FROM Contact
				WHERE Id = :secondaryConId
			];

			List<Contact_Address__c> masterCtcAddresList = [SELECT Id, Contact__c, Primary_Address__c FROM Contact_Address__c WHERE Contact__c = :masterContactId];
			boolean masterHasAddresses = !masterCtcAddresList.isEmpty();

			for (Basic_Note__c bNote : nonMasterContact.Basic_Notes__r) {
				// Added By Fernando Ortiz
				bNote.Account__c = masterAccountId;
				bNote.Contact__c = masterContactId; // Need to validate and Confirm with David
				basicNoteToUpdateList.add(bNote);
			}

			for (Contact_Address__c ctcAddress : nonMasterContact.Contact_Addresses__r) {
				// Added By Fernando Ortiz
				ctcAddress.Contact__c = masterContactId;
				if (masterHasAddresses) {
					// In case the Master records does not have related contact Addresses then get the primary address from the nonMaster.
					ctcAddress.Primary_Address__c = false;
				}
				contactAddressesToUpdateList.add(ctcAddress);
			}

			for (Legal_Name__c lName : [SELECT Id, Patient__c FROM Legal_Name__c WHERE Patient__c = :secondaryAccount.Id]) {
				lName.Patient__c = masterAccountId;
				legalNamesToUpdateList.add(lName);
			}

			update basicNoteToUpdateList;
			update contactAddressesToUpdateList;
			update legalNamesToUpdateList;

			/*********** END ***********/

			//Admission
			List<Admission__c> admsToUpdate = new List<Admission__c>();
			for (Admission__c obj : secondaryAccount.Admission_Files__r) {
				obj.Patient_Account__c = masterAccountId;
				obj.Patient_Contact__c = masterContactId;
				admsToUpdate.add(obj);
			}

			//Tasks
			List<Task> tasksToUpdate = new List<Task>();
			for (Task obj : secondaryAccount.Tasks) {
				obj.WhatId = masterAccountId;
				if (obj.WhoId == secondaryConId)
					obj.WhoId = masterContactId;
				tasksToUpdate.add(obj);
			}

			//Related Contacts
			Id secondaryPatientRcId;
			List<Related_Contact__c> rcsToUpdate = new List<Related_Contact__c>();
			for (Related_Contact__c obj : secondaryAccount.Related_Contacts__r) {
				if (obj.Role__c == 'Patient') {
					secondaryPatientRcId = obj.Id;
					obj.OwnerId = UserInfo.getUserId();
					update obj;
					delete obj;
				} else {
					obj.Account__c = masterAccountId;
					rcsToUpdate.add(obj);
				}
			}

			//Forms
			List<disco__Form__c> formsToUpdate = new List<disco__Form__c>();
			for (disco__Form__c obj : secondaryAccount.disco__Forms__r) {
				obj.disco__Form_Account__c = masterAccountId;
				if (obj.disco__Form_Contact__c == secondaryConId)
					obj.disco__Form_Contact__c = masterContactId;
				if (obj.Related_Contact__c == secondaryPatientRcId)
					obj.Related_Contact__c = masterPatientRcId;

				formsToUpdate.add(obj);
			}

			//TODO: rebase Treatment Plans
			List<Case> casesToUpdate = new List<Case>();
			for (Case c : secondaryAccount.Cases) {
				c.AccountId = masterAccountId;
				c.Admission__c = masterAccount.Current_Admission__c;
				c.ContactId = masterContactId;
				casesToUpdate.add(c);
			}

			//Assign current Treatment Plan to the Master Account
			masterRec.accountRec.Current_Case__c = secondaryAccount.Current_Case__c;
			//secondaryAccount.Current_Case__c = null;
			//update secondaryAccount;

			//

			//Contact
			update masterRec.contactRec;
			update admsToUpdate;
			update tasksToUpdate;
			update rcsToUpdate;
			update formsToUpdate;
			update casesToUpdate;

			//remove secondary
			Contact c = new Contact(Id = secondaryConId, OwnerId = UserInfo.getUserId());
			update c;
			delete c;

			Account a = new Account(Id = secondaryAccount.Id, OwnerId = UserInfo.getUserId());
			update a;
			delete a;

			//Account
			update masterRec.accountRec;

			//remove duprecorditems
			deleteDuplicateRecords(masterContactId);
		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, '**** Merger Error ---> ' + e.getMessage());
			Database.rollback(sp);
			System.debug(LoggingLevel.ERROR, '**** Merger Error ---> ' + e.getMessage());

			// return new RecordsWrapper('Error. Changes were not saved. Please contact system administrator: \n'
			//     + e.getMessage()
			//     + '\n' + e.getStackTraceString());

			RecordsWrapper rw = new RecordsWrapper('Error. Changes were not saved. Please contact system administrator: \n' + e.getMessage() + '\n' + e.getStackTraceString());

			System.debug(LoggingLevel.ERROR, '**** RecordsWrapper ---> ' + rw);

			return rw;
		}

		return masterRec;
	}
	public static void deleteDuplicateRecords(String masterConId) {
		List<DuplicateRecordItem> dupRecItems = new List<DuplicateRecordItem>();
		List<DuplicateRecordSet> dupRecSets = new List<DuplicateRecordSet>();
		Set<Id> dupRecSetIds = new Set<Id>();

		if (String.isNotBlank(masterConId)) {
			dupRecItems = [SELECT Id, RecordId, DuplicateRecordSetId FROM DuplicateRecordItem WHERE RecordId = :masterConId];

			if (!dupRecItems.isEmpty()) {
				for (DuplicateRecordItem rec : dupRecItems) {
					dupRecSetIds.add(rec.DuplicateRecordSetId);
				}

				if (!dupRecSetIds.isEmpty()) {
					dupRecSets = [SELECT Id, (SELECT Id FROM DuplicateRecordItems) FROM DuplicateRecordSet WHERE Id IN :dupRecSetIds];
					List<DuplicateRecordSet> deleteRecSets = new List<DuplicateRecordSet>();
					List<DuplicateRecordItem> deleteRecItems = new List<DuplicateRecordItem>();

					if (!dupRecSets.isEmpty()) {
						for (DuplicateRecordSet dupSet : dupRecSets) {
							List<DuplicateRecordItem> dupRecSetItems = dupSet.DuplicateRecordItems;
							if (dupRecSetItems.size() == 1) {
								deleteRecItems.addAll(dupRecSetItems);
								deleteRecSets.add(dupSet);
							}
						}
					}

					delete deleteRecItems;
					delete deleteRecSets;
				}
			}
		}
	}

	public class DedupeWrapper {
		public FieldSetWrapper allFieldSet;
		public List<RecordsWrapper> records;
	}

	public class FieldSetWrapper {
		public List<Field> contactFS;
		public List<Field> accountFS;
	}

	public class RecordsWrapper {
		@AuraEnabled
		public Contact contactRec;
		@AuraEnabled
		public Account accountRec;
		@AuraEnabled
		public Boolean isSelected;
		@AuraEnabled
		public Boolean isDifferent;
		@AuraEnabled
		public String errorMessage;
		@AuraEnabled
		public Integer rowNumber;

		public RecordsWrapper() {
		}

		public RecordsWrapper(String message) {
			this.errorMessage = message;
		}
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
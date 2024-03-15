public without sharing class ContactAddress_TriggerHandler {
	public List<Contact_Address__c> newRecords;
	public Map<Id, Contact_Address__c> oldMap;
	public Set<Id> contactIdSet;
	public Set<Id> primaryAddressChangedContactAddressIdSet;
	public Set<Id> existingPrimaryAddressesChangedContactAddressIdSet;
	public List<Contact> updateContactList;
	public List<Contact_Address__c> updateContactAddressList;
	public static Boolean bypassTrigger = false;
	public Map<String, String> stateNameCodeMap;

	public ContactAddress_TriggerHandler(List<Contact_Address__c> newRecords, Map<Id, Contact_Address__c> oldMap) {
		this.newRecords = newRecords;
		this.oldMap = oldMap;
		contactIdSet = new Set<Id>();
		primaryAddressChangedContactAddressIdSet = new Set<Id>();
		existingPrimaryAddressesChangedContactAddressIdSet = new Set<Id>();
		stateNameCodeMap = new Map<String, String>();
	}

	public void beforeInsert(List<Contact_Address__c> newRecords) {
		Set<String> stateNameSet = new Set<String>();
		Map<Id, List<Integer>> contactIdContactAddressIndexListMap = new Map<Id, List<Integer>>();
		Integer index = 0;
		Set<Id> contactIdSet = new Set<Id>();
		Set<Id> contactAddressIdSet = new Set<Id>();
		for (Contact_Address__c newRecord : newRecords) {
			stateNameSet.add(newRecord.State__c);
			if (newRecord.Primary_Address__c != true) {
				contactIdSet.add(newRecord.Contact__c);
				contactAddressIdSet.add(newRecord.Id);
				List<Integer> contactAddressIndexList = contactIdContactAddressIndexListMap.get(newRecord.Contact__c);
				if (contactAddressIndexList == null) {
					contactAddressIndexList = new List<Integer>();
				}
				contactAddressIndexList.add(index);
				contactIdContactAddressIndexListMap.put(newRecord.Contact__c, contactAddressIndexList);
			}
			index++;
		}

		Map<Id, Boolean> contactIdPrimaryAddressMap = validatePrimaryAddress(newRecords, contactIdSet, contactAddressIdSet);

		for (Id contactId : contactIdContactAddressIndexListMap.keySet()) {
			Boolean hasPrimaryAddress = contactIdPrimaryAddressMap.get(contactId);
			if (hasPrimaryAddress != true) {
				List<Integer> contactAddressIndexList = contactIdContactAddressIndexListMap.get(contactId);
				for (Integer contactAddressIndex : contactAddressIndexList) {
					Contact_Address__c newRecord = newRecords.get(contactAddressIndex);
					newRecord.addError('There must be a primary contact address for this contact.');
				}
			}
		}

		buildStateCodeMap(stateNameSet);

		for (Contact_Address__c newRecord : newRecords) {
			setExternalAddress(newRecord, null);
			setStateCode(newRecord, null, stateNameCodeMap);
		}
	}

	public void afterInsert(List<Contact_Address__c> newRecords) {
		for (Contact_Address__c newRecord : newRecords) {
			if (isPrimaryAddress(newRecord, null)) {
				contactIdSet.add(newRecord.Contact__c);
				primaryAddressChangedContactAddressIdSet.add(newRecord.Id);
			}
		}
		setPrimaryAddress(contactIdSet, primaryAddressChangedContactAddressIdSet);
	}

	public void beforeUpdate(List<Contact_Address__c> newRecords, Map<Id, Contact_Address__c> oldMap) {
		Set<String> stateNameSet = new Set<String>();
		Map<Id, List<Integer>> contactIdContactAddressIndexListMap = new Map<Id, List<Integer>>();
		Integer index = 0;
		Set<Id> contactIdSet = new Set<Id>();
		Set<Id> contactAddressIdSet = new Set<Id>();
		for (Contact_Address__c newRecord : newRecords) {
			Contact_Address__c oldRecord = (Contact_Address__c) oldMap.get(newRecord.Id);
			stateNameSet.add(newRecord.State__c);
			if (oldRecord.Primary_Address__c != newRecord.Primary_Address__c) {
				contactIdSet.add(newRecord.Contact__c);
				contactAddressIdSet.add(newRecord.Id);
				List<Integer> contactAddressIndexList = contactIdContactAddressIndexListMap.get(newRecord.Contact__c);
				if (contactAddressIndexList == null) {
					contactAddressIndexList = new List<Integer>();
				}
				contactAddressIndexList.add(index);
				contactIdContactAddressIndexListMap.put(newRecord.Contact__c, contactAddressIndexList);
			}
			index++;
		}

		Map<Id, Boolean> contactIdPrimaryAddressMap = validatePrimaryAddress(newRecords, contactIdSet, contactAddressIdSet);

		for (Id contactId : contactIdContactAddressIndexListMap.keySet()) {
			Boolean hasPrimaryAddress = contactIdPrimaryAddressMap.get(contactId);

			if (hasPrimaryAddress != true) {
				List<Integer> contactAddressIndexList = contactIdContactAddressIndexListMap.get(contactId);
				for (Integer contactAddressIndex : contactAddressIndexList) {
					Contact_Address__c newRecord = newRecords.get(contactAddressIndex);
					newRecord.addError('There must be a primary contact address for this contact.');
				}
			}
		}

		buildStateCodeMap(stateNameSet);

		for (Contact_Address__c newRecord : newRecords) {
			Contact_Address__c oldRecord = (Contact_Address__c) oldMap.get(newRecord.Id);
			setStateCode(newRecord, oldRecord, stateNameCodeMap);
		}
	}

	public void afterUpdate(List<Contact_Address__c> newRecords, Map<Id, Contact_Address__c> oldMap) {
		for (Contact_Address__c newRecord : newRecords) {
			if (isPrimaryAddress(newRecord, oldMap.get(newRecord.Id))) {
				contactIdSet.add(newRecord.Contact__c);
				primaryAddressChangedContactAddressIdSet.add(newRecord.Id);
			}
			// Handling address updates to existing primary addresses
			Contact_Address__c oldContactAddress = oldMap.get(newRecord.Id);
			if (
				newRecord.Primary_Address__c == true &&
				(oldContactAddress != null ||
				newRecord.Primary_Address__c == oldContactAddress.Primary_Address__c) &&
				(newRecord.Country__c != oldContactAddress.Country__c ||
				newRecord.Street_1__c != oldContactAddress.Street_1__c ||
				newRecord.Street_2__c != oldContactAddress.Street_2__c ||
				newRecord.Street_3__c != oldContactAddress.Street_3__c ||
				newRecord.City__c != oldContactAddress.City__c ||
				newRecord.State__c != oldContactAddress.State__c ||
				newRecord.PostalCode__c != oldContactAddress.PostalCode__c ||
				newRecord.Address_Notes__c != oldContactAddress.Address_Notes__c)
			) {
				contactIdSet.add(newRecord.Contact__c);
				existingPrimaryAddressesChangedContactAddressIdSet.add(newRecord.Id);
			}
		}

		if (!primaryAddressChangedContactAddressIdSet.isEmpty())
			setPrimaryAddress(contactIdSet, primaryAddressChangedContactAddressIdSet);

		if (!existingPrimaryAddressesChangedContactAddressIdSet.isEmpty())
			updateAddressForExistingPrimaryAddresses(contactIdSet, existingPrimaryAddressesChangedContactAddressIdSet);
	}

	public void invokeContextMethod() {
		if (Trigger.isInsert) {
			if (Trigger.isBefore) {
				this.beforeInsert(this.newRecords);
			}
			if (Trigger.isAfter) {
				this.afterInsert(this.newRecords);
			}
		}
		if (Trigger.isUpdate) {
			if (Trigger.isBefore) {
				this.beforeUpdate(this.newRecords, this.oldMap);
			}
			if (Trigger.isAfter) {
				this.afterUpdate(this.newRecords, this.oldMap);
			}
		}
	}

	/**
	 * Build Contact Id - Has Primary Address
	 */
	Map<Id, Boolean> validatePrimaryAddress(List<Contact_Address__c> newRecords, Set<Id> contactIdSet, Set<Id> contactAddressIdSet) {
		Map<Id, Boolean> contactIdPrimaryAddressMap = new Map<Id, Boolean>();
		List<Contact_Address__c> contactAddressList = [SELECT Id, Contact__c, Primary_Address__c FROM Contact_Address__C WHERE Contact__c = :contactIdSet AND Id != :contactAddressIdSet];

		for (Contact_Address__c contactAddress : contactAddressList) {
			if (!contactIdPrimaryAddressMap.containsKey(contactAddress.Contact__c) || (contactIdPrimaryAddressMap.get(contactAddress.Contact__c) == false && contactAddress.Primary_Address__c == true)) {
				contactIdPrimaryAddressMap.put(contactAddress.Contact__c, contactAddress.Primary_Address__c);
			}
		}
		return contactIdPrimaryAddressMap;
	}

	void buildStateCodeMap(Set<String> stateNameSet) {
		List<States_and_State_Codes__mdt> stateCodeList = [SELECT Id, StateCode__c, StateName__c FROM States_and_State_Codes__mdt WHERE StateName__c = :stateNameSet];
		for (States_and_State_Codes__mdt stateCode : stateCodeList) {
			stateNameCodeMap.put(stateCode.StateName__c, stateCode.StateCode__c);
		}
	}

	/**
	 * Set External ID
	 */
	void setExternalAddress(Contact_Address__c newContactAddress, Contact_Address__c oldContactAddress) {
		newContactAddress.External_Address_Id__c = newContactAddress.Id;
	}

	/**
	 * Set StateCode
	 */
	void setStateCode(Contact_Address__c newContactAddress, Contact_Address__c oldContactAddress, Map<String, String> stateNameCodeMap) {
		if (stateNameCodeMap.containsKey(newContactAddress.State__c)) {
			newContactAddress.StateCode__c = stateNameCodeMap.get(newContactAddress.State__c);
		}
	}

	/**
	 * Is this marked as primary address
	 */
	Boolean isPrimaryAddress(Contact_Address__c newContactAddress, Contact_Address__c oldContactAddress) {
		Boolean isPrimaryAddress = false;
		if (newContactAddress.Primary_Address__c == true && (oldContactAddress == null || newContactAddress.Primary_Address__c != oldContactAddress.Primary_Address__c)) {
			isPrimaryAddress = true;
		}
		return isPrimaryAddress;
	}

	/**
	 * Set Primary Address
	 */
	void setPrimaryAddress(Set<Id> contactIdSet, Set<Id> primaryAddressChangedContactAddressIdSet) {
		if (!contactIdSet.isEmpty()) {
			updateContactList = new List<Contact>();
			updateContactAddressList = new List<Contact_Address__c>();
			Integer index = 0;
			List<Contact_Address__c> contactAddressList = [SELECT Id, Contact__c, Primary_Address__c, Street_1__c, Street_2__c, Street_3__c, City__c, PostalCode__c, Address_Notes__c, State__c, Country__c FROM Contact_Address__c WHERE Contact__c = :contactIdSet];
			Map<Id, List<Integer>> contactIdContactAddressIndexListMap = new Map<Id, List<Integer>>();
			for (Contact_Address__c contactAddress : contactAddressList) {
				List<Integer> contactIdContactAddressIndexList = contactIdContactAddressIndexListMap.get(contactAddress.Contact__c);
				if (contactIdContactAddressIndexList == null) {
					contactIdContactAddressIndexList = new List<Integer>();
				}
				contactIdContactAddressIndexList.add(index);
				contactIdContactAddressIndexListMap.put(contactAddress.Contact__c, contactIdContactAddressIndexList);
				index++;
			}

			List<Contact> contactList = [SELECT Id, Primary_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Address_Notes__c FROM Contact WHERE id = :contactIdSet];
			for (Contact contactObj : contactList) {
				List<Integer> contactIdContactAddressIndexList = contactIdContactAddressIndexListMap.get(contactObj.Id);
				if (contactIdContactAddressIndexList != null && !contactIdContactAddressIndexList.isEmpty()) {
					for (Integer contactIdContactAddressIndex : contactIdContactAddressIndexList) {
						Contact_Address__c contactAddress = contactAddressList.get(contactIdContactAddressIndex);
						if (primaryAddressChangedContactAddressIdSet.contains(contactAddress.Id)) {
							contactObj.MailingCountry = contactAddress.Country__c;
							contactObj.Primary_Address__c = contactAddress.Id;
							contactObj.MailingStreet = ((String.isNotBlank(contactAddress.Street_1__c) ? contactAddress.Street_1__c : '') + (String.isNotBlank(contactAddress.Street_2__c) ? contactAddress.Street_2__c : '') + (String.isNotBlank(contactAddress.Street_3__c) ? contactAddress.Street_3__c : '')).left(255);
							contactObj.MailingCity = contactAddress.City__c;
							contactObj.MailingState = contactAddress.State__c;
							contactObj.MailingPostalCode = contactAddress.PostalCode__c;
							contactObj.Address_Notes__c = contactAddress.Address_Notes__c;
							updateContactList.add(contactObj);
						} else {
							contactAddress.Primary_Address__c = false;
						}
						updateContactAddressList.add(contactAddress);
					}
				}
			}
			if (!updateContactList.isEmpty()) {
				update updateContactList;
			}
			if (!updateContactAddressList.isEmpty()) {
				update updateContactAddressList;
			}
		}
	}

	@TestVisible
	void updateAddressForExistingPrimaryAddresses(Set<Id> contactIdSet, Set<Id> existingPrimaryAddressesChangedContactAddressIdSet) {
		if (!contactIdSet.isEmpty()) {
			updateContactList = new List<Contact>();
			Integer index = 0;
			List<Contact_Address__c> contactAddressList = [SELECT Id, Contact__c, Primary_Address__c, Street_1__c, Street_2__c, Street_3__c, City__c, PostalCode__c, Address_Notes__c, State__c, Country__c FROM Contact_Address__c WHERE Contact__c = :contactIdSet];
			Map<Id, List<Integer>> contactIdContactAddressIndexListMap = new Map<Id, List<Integer>>();
			for (Contact_Address__c contactAddress : contactAddressList) {
				List<Integer> contactIdContactAddressIndexList = contactIdContactAddressIndexListMap.get(contactAddress.Contact__c);
				if (contactIdContactAddressIndexList == null) {
					contactIdContactAddressIndexList = new List<Integer>();
				}
				contactIdContactAddressIndexList.add(index);
				contactIdContactAddressIndexListMap.put(contactAddress.Contact__c, contactIdContactAddressIndexList);
				index++;
			}

			List<Contact> contactList = [SELECT Id, Primary_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Address_Notes__c FROM Contact WHERE id = :contactIdSet];
			for (Contact contactObj : contactList) {
				List<Integer> contactIdContactAddressIndexList = contactIdContactAddressIndexListMap.get(contactObj.Id);
				if (contactIdContactAddressIndexList != null && !contactIdContactAddressIndexList.isEmpty()) {
					for (Integer contactIdContactAddressIndex : contactIdContactAddressIndexList) {
						Contact_Address__c contactAddress = contactAddressList.get(contactIdContactAddressIndex);
						if (existingPrimaryAddressesChangedContactAddressIdSet.contains(contactAddress.Id)) {
							contactObj.MailingCountry = contactAddress.Country__c;
							contactObj.Primary_Address__c = contactAddress.Id;
							contactObj.MailingStreet = ((String.isNotBlank(contactAddress.Street_1__c) ? contactAddress.Street_1__c : '') + (String.isNotBlank(contactAddress.Street_2__c) ? contactAddress.Street_2__c : '') + (String.isNotBlank(contactAddress.Street_3__c) ? contactAddress.Street_3__c : '')).left(255);
							contactObj.MailingCity = contactAddress.City__c;
							contactObj.MailingState = contactAddress.State__c;
							contactObj.MailingPostalCode = contactAddress.PostalCode__c;
							contactObj.Address_Notes__c = contactAddress.Address_Notes__c;
							updateContactList.add(contactObj);
						}
					}
				}
			}
			if (!updateContactList.isEmpty()) {
				update updateContactList;
			}
		}
	}
}
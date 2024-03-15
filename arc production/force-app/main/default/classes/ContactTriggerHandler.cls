public class ContactTriggerHandler implements ITrigger {
	//Contacts with Staff User populated
	public Set<Id> staffContactIds = new Set<Id>();

	/**
	 * bulkBefore
	 *
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
	}

	/**
	 * bulkAfter
	 *
	 * This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		if (Trigger.new != null) {
			Contact_TriggerHelper.updatePatientAccountsFromContact((List<Contact>) Trigger.new, (Map<Id, Contact>) Trigger.oldMap);
			Contact_TriggerHelper.updateLegalNamesFromContact((List<Contact>) Trigger.new, (Map<Id, Contact>) Trigger.oldMap);
		}
	}

	/**
	 * beforeInsert
	 *
	 * This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
		Contact currentContact = (Contact) so;
		String recordTypeName = Schema.SObjectType.Contact.getRecordTypeInfosById().get(currentContact.RecordTypeID).getname();
		if (recordTypeName.equals('ARC Staff')) {
			currentContact.Active_Employee__c = true;
		}
	}

	/**
	 * beforeUpdate
	 *
	 * This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
	}

	/**
	 * beforeDelete
	 *
	 * This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so) {
	}

	/**
	 * afterInsert
	 *
	 * This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public void afterInsert(SObject so) {
		// Contact contact = (Contact)so;

		// removed 220513 JN
		// if(null != contact.Staff_User__c && null != contact.Suffix_Credentials__c) {
		//     Contact_TriggerHelper.updateContactsUserFields(contact.Id);
		// }
		if (so.get('Staff_User__c') != null) {
			staffContactIds.add(so.Id);
		}
	}

	/**
	 * afterUpdate
	 *
	 * This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		// Contact contact = (Contact)so;
		// Contact oldContact = (Contact)oldSo;

		// removed 220513 JN
		// if(null != contact.Staff_User__c && contact.Suffix_Credentials__c != oldContact.Suffix_Credentials__c) {
		//     Contact_TriggerHelper.updateContactsUserFields(contact.Id);
		// }
		if (so.get('Staff_User__c') != null) {
			staffContactIds.add(so.Id);
		}
	}

	/**
	 * afterDelete
	 *
	 * This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	/**
	 * andFinally
	 *
	 * This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
		if(!System.isBatch()){
			Contact_TriggerHelper.updateStaffUserFields(staffContactIds);
		}
	}
}
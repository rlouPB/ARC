public with sharing class Medication_Admin_LineTriggerHandler implements ITrigger {
	static Map<Id, Prescription__c> prescriptionsByIdMap = new Map<Id, Prescription__c>();

	/*******************************************************************************************************
	 * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		if (!Trigger.isDelete) {
			List<Medication_Administration_Line__c> newMarLines = Trigger.new;
			Set<Id> prescriptionIds = new Set<Id>();
			for (Medication_Administration_Line__c marLine : newMarLines) {
				prescriptionIds.add(marLine.Prescription__c);
			}

			prescriptionsByIdMap = new Map<Id, Prescription__c>([SELECT Id, Medication_Format__c FROM Prescription__c WHERE Id IN :prescriptionIds]);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		if (Trigger.isUpdate) {
			disco.Util.updateAnswersInLinkedSections(Trigger.new, 'Medication_Administration_Line__c');
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
		Medication_Administration_Line__c marLine = (Medication_Administration_Line__c) so;
		setMedFormat(marLine);
	}

	private void setMedFormat(Medication_Administration_Line__c marLine) {
		String medFormat = prescriptionsByIdMap.containsKey(marLine.Prescription__c) ? prescriptionsByIdMap.get(marLine.Prescription__c).Medication_Format__c : null;
		if (null != medFormat) {
			Integer endingIndex = medFormat.length() >= 255 ? 255 : medFormat.length();
			marLine.Medication_Format__c = medFormat.substring(0, endingIndex);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
		Medication_Administration_Line__c marLine = (Medication_Administration_Line__c) so;
		setMedFormat(marLine);
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public void afterInsert(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
	}
}
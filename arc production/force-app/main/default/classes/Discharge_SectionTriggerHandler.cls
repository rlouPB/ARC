/**
 * @group Discharge_Section__c
 *
 * @description DischargeSection_TriggerHandler for the Patient Note SObject. This class implements the ITrigger
 *  Please check ITrigger and TriggerFactory to understand the order execution and methods used
 */
public without sharing class Discharge_SectionTriggerHandler implements ITrigger {
	public static Map<Id, Discharge_Disposition__c> dischargeDispositionsByIdMap = new Map<Id, Discharge_Disposition__c>();

	/*******************************************************************************************************
	 * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
	}

	/*******************************************************************************************************
	 * @description This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		// Check for outstanding items.
		if (!Trigger.isDelete) {
			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);
			if (Trigger.isInsert) {
				Set<Id> dischargeDispositionIds = new Set<Id>();
				for (Discharge_Section__c ds : (List<Discharge_Section__c>) Trigger.new) {
					dischargeDispositionIds.add(ds.Discharge_Disposition__c);
				}
				dischargeDispositionsByIdMap = new Map<Id, Discharge_Disposition__c>([SELECT Id, Owner.Id FROM Discharge_Disposition__c WHERE Id IN :dischargeDispositionIds]);
			}
		} else {
			OutstandingItems.deleteRelatedTags(Trigger.old);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
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
		Discharge_Section__c dischargeSection = (Discharge_Section__c) so;

		if (null != dischargeSection.Discharge_Disposition__c && dischargeDispositionsByIdMap.containsKey(dischargeSection.Discharge_Disposition__c)) {
			Discharge_Disposition__c dd = dischargeDispositionsByIdMap.get(dischargeSection.Discharge_Disposition__c);
			//don't share the Discharge Section record with its owner.
			if (dischargeSection.ownerId != dd.Owner.Id) {
				String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{ dischargeSection.Id }, new List<Id>{ dd.Owner.Id }, 'Edit');
			}
		}
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
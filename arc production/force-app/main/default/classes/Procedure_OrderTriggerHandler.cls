/**
 * @group Procedure_Order__c
 *
 * @description Procedure_OrderTriggerHandler for the Procedure Order SObject. This class implements the ITrigger
 *  Please check ITrigger and TriggerFactory to understand the order execution and methods used
 */
public without sharing class Procedure_OrderTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	 */
	private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
	private static Id labTestRTId = Schema.SObjectType.Procedure_Order__c.getRecordTypeInfosByDeveloperName().get('Lab_Order').getRecordTypeId();

	/*******************************************************************************************************
	 * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		if (Trigger.isUpdate) {
			//pop process field values
			ProcedureOrders.populateProcedureOrderBeforeData(Trigger.newMap, Trigger.oldMap);
		} //end if Trigger.isUpdate
	}

	/*******************************************************************************************************
	 * @description This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		if (!Trigger.isDelete) {
			// Check for outstanding items.
			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);

			//Execute and process Procedure Orders
			if (!Test.isRunningTest()) {
				ProcedureOrders.executeProcedureOrders(Trigger.new);
			}
		} else {
			//delete open tags on delete
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
		String triggerObject = 'Procedure_Order__c';
		AlertsFilter.execute(null, so, alertsToBePublished, triggerObject, 'Insert');
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		String triggerObject = 'Procedure_Order__c';
		AlertsFilter.execute(oldSo, so, alertsToBePublished, triggerObject, 'Update');
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
		if (alertsToBePublished.size() > 0) {
			EventBus.publish(alertsToBePublished);
		}
	}

	public static void SendLabOrder() {
		for (Procedure_Order__c po : (Procedure_Order__c[]) Trigger.New) {
			if (po.RecordTypeId == labTestRTId) {
				Procedure_Order__c old = Trigger.oldMap?.containsKey(po.Id) == true ? (Procedure_Order__c) Trigger.oldMap?.get(po.Id) : null;
				if (po.Active__c && !old.Active__c) {
					//ProcedureOrderHL7Processor.sendHL7OrderFuture(po.Id);
				}
			}
		}
	}
}
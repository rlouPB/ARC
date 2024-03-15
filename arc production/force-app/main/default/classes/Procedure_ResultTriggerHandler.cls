/**
* @group Procedure_Result__c
*
* @description Procedure_ResultTriggerHandler for the Procedure Result SObject. This class implements the ITrigger
*  Please check ITrigger and TriggerFactory to understand the order execution and methods used
*/
public without sharing class Procedure_ResultTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	*/
	private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
	List<Id> procedureResultIds = new List<Id>();
	/*******************************************************************************************************
	* @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore() 
	{
		if (Trigger.isUpdate)
		{
			// if (Userinfo.getUserId() == [select Id from User where Name = 'Jeremy Nottingham' and IsActive = true].Id)
			// {
			//     System.assert(false, 'This is Jeremy in ProcResultTrigHandler');
			// }
			//pop process fields where applicable
			ProcedureResults.populateProcedureResultBeforeData(Trigger.newMap, Trigger.oldMap);
		} //end if Trigger.isUpdate		
	}

	/*******************************************************************************************************
	* @description This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter()
	{
		// Check for outstanding items.
		if (!Trigger.isDelete)
		{
			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);

			List<ID> recordIds = new List<ID>();
			List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
			String triggerObject = String.valueOf(Trigger.new.getSObjectType());
			for (sObject obj: Trigger.new)
			{
				if(Trigger.isUpdate) {
					Procedure_Result__c pr = (Procedure_Result__c) obj;
					//if a procedure result is set to 'Cancelled', collect the Procedure Result Ids
					if(pr.Status__c == 'Cancelled') {
						procedureResultIds.add(pr.Id);
					}
				}
				AlertsFilter.execute(null, obj, alertsToBePublished, triggerObject, 'Insert');
			}
			//Collect the shift items, and set the Procedure_Result__c to null
			if(procedureResultIds.size() > 0) {
				List<disco__Form__c> forms =new List<disco__Form__c>();
				List<Physical_Monitor__c> monitors = new List<Physical_Monitor__c> ();
				Set<String> pOrderIds = new Set<String>();
				List<Procedure_Order__c> pOrders = new List<Procedure_Order__c>();
				List<Nursing_Shift_Item__c> shiftItems = [SELECT Id, Procedure_Result__c, form__c, Physical_Monitor__c, Procedure_Order__c FROM Nursing_Shift_Item__c WHERE Procedure_Result__c in :procedureResultIds];
				for(Nursing_Shift_Item__c si : shiftItems) {
					if(String.isNotBlank(si.form__c)) {
						forms.add(new disco__Form__c(Id = si.form__c));
					}
					if(String.isNotBlank(si.Physical_Monitor__c)) {
						monitors.add(new Physical_Monitor__c(Id = si.Physical_Monitor__c));
					}
				}
				if(shiftItems.size() > 0) {
					delete shiftItems;
				}
				if(forms.size() > 0) {
					delete forms;
				}
				if(monitors.size() > 0) {
					delete monitors;
				}
			}
			
			EventBus.publish(alertsToBePublished);
		} else
		{
			OutstandingItems.deleteRelatedTags(Trigger.old);
		}

	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) 
	{
		
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be deleted during a BEFORE
	* trigger.
	*/
	public void beforeDelete(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record inserted during an AFTER
	* trigger. Always put field validation in the 'After' methods in case another trigger
	* has modified any values. The record is 'read only' by this point.
	*/
	public void afterInsert(SObject so) {

		Procedure_Result__c newRecord = (Procedure_Result__c) so;

		String triggerObject = String.valueOf(Trigger.new.getSObjectType());

		AlertsFilter.execute(null, newRecord, alertsToBePublished, triggerObject, 'Insert');
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {

		Procedure_Result__c oldRecord = (Procedure_Result__c) oldSo;
		Procedure_Result__c newRecord = (Procedure_Result__c) so;

		String triggerObject = String.valueOf(Trigger.new.getSObjectType());

		AlertsFilter.execute(oldRecord, newRecord, alertsToBePublished, triggerObject, 'Update');
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record deleted during an AFTER
	* trigger.
	*/
	public void afterDelete(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called once all records have been processed by the trigger. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void andFinally() {
		if(alertsToBePublished.size() > 0) {
			EventBus.publish(alertsToBePublished);
		}
	}
}
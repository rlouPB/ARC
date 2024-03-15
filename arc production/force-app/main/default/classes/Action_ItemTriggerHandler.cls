public class Action_ItemTriggerHandler implements ITrigger {

	private static Map<Id, Admission__c> currentAdmissionsByAccountIdMap;

    /**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore(){

		if(!Trigger.isDelete) {
			List<Action_Item__c> actionItems = (List<Action_Item__c>)Trigger.new;

			Set<Id> accountIds = new Set<Id>();
			for(Action_Item__c ai : actionItems) {
				accountIds.add(ai.Account__c);
			}

			Set<Id> currentAdmissionIds = new Set<Id>();
			for(Account account : [SELECT Id, Current_Admission__c FROM Account WHERE Id IN :accountIds]) {
				currentAdmissionIds.add(account.Current_Admission__c);
			}

			currentAdmissionsByAccountIdMap = new Map<Id, Admission__c>();
			for(Admission__c admission : [SELECT Id, Patient_Account__c from Admission__c 
											WHERE Id IN :currentAdmissionIds]){
				currentAdmissionsByAccountIdMap.put(admission.Patient_Account__c, admission);
			}
		}
	}

	/**
	* bulkAfter
	*
	* This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter(){
        if (!Trigger.isDelete) {
			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);
		} else {
			OutstandingItems.deleteRelatedTags(trigger.old);
        }
        
        // if (Trigger.isInsert || Trigger.isUpdate)
		// {
		// 	TrackFieldHistory.trackFields(trigger.new, trigger.oldMap);
		// }
    }

	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so){
		Action_Item__c actionItem = (Action_Item__c)so;

		if(null != currentAdmissionsByAccountIdMap.get(actionItem.Account__c)) {
			actionItem.Admission__c = currentAdmissionsByAccountIdMap.get(actionItem.Account__c).Id;
		}
	}

	/**
	* beforeUpdate
	*
	* This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so){}

	/**
	* beforeDelete
	*
	* This method is called iteratively for each record to be deleted during a BEFORE
	* trigger.
	*/
	public void beforeDelete(SObject so){}

	/**
	* afterInsert
	*
	* This method is called iteratively for each record inserted during an AFTER
	* trigger. Always put field validation in the 'After' methods in case another trigger
	* has modified any values. The record is 'read only' by this point.
	*/
	public void afterInsert(SObject so){}

	/**
	* afterUpdate
	*
	* This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so){}

	/**
	* afterDelete
	*
	* This method is called iteratively for each record deleted during an AFTER
	* trigger.
	*/
	public void afterDelete(SObject so){}

	/**
	* andFinally
	*
	* This method is called once all records have been processed by the trigger. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void andFinally(){}
}
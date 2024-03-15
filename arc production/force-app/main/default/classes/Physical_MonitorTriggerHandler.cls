/**
 * @Description:
 * @Created By: Fernando Ortiz
 */

public class Physical_MonitorTriggerHandler implements iTrigger {

    private Id finalizedRecordTypeId = Schema.SObjectType.Physical_Monitor__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
    private Id draftRecordTypeId = Schema.SObjectType.Physical_Monitor__c.getRecordTypeInfosByName().get('Draft').getRecordTypeId();
	private static Map<Id, Admission__c> currentAdmissionsByAccountIdMap;
	// private static List<Admission__c> admissionsToUpdate = new List<Admission__c>();
	private static Map<Id, Admission__c> admissionsToUpdateMap = new Map<Id, Admission__c>();

    private void changeRecordTypeToFinalized(Physical_Monitor__c physicalMonitor) {
        if (physicalMonitor.Status__c == 'Finalized') {
            physicalMonitor.RecordTypeId = finalizedRecordTypeId;
        } else {
            physicalMonitor.RecordTypeId = draftRecordTypeId;
        }
    }

	static void closeAllNursingShiftItemsWhenFinalized(){
		Id[] physicalMonitorIds = new Id[]{};
		map<Id,Physical_Monitor__c> oldMap = Trigger.oldmap != nulL? (map<Id,Physical_Monitor__c>)Trigger.oldmap : null;
		for( Physical_Monitor__c pm : (Physical_Monitor__c[])Trigger.new ){
			Physical_Monitor__c old = oldMap != null ? oldMap.get(pm.Id) : null;
			if( pm.Status__c == 'Finalized' && ( old == null || old.Status__c != pm.Status__c ) ) {
				physicalMonitorIds.add(pm.Id);
			}
		}
		if ( physicalMonitorIds.size() > 0 ) 
		{
			List<Nursing_Shift_Item__c> itemsToUpdate = new Nursing_Shift_Item__c[]{};	
			List<Procedure_Result__c> resultsToUpdate = new List<Procedure_Result__c>();
			for (Nursing_Shift_Item__c item : [SELECT Id, Procedure_Result__c FROM Nursing_Shift_Item__c WHERE Physical_Monitor__c in :physicalMonitorIds])
			{
				itemsToUpdate.add(new Nursing_Shift_Item__c(
					Id = item.Id,
					Status__c = 'Closed'
				));
				if (item.Procedure_Result__c != null)
				{
					resultsToUpdate.add(new Procedure_Result__c(
						Id = item.Procedure_Result__c,
						Status__c = 'Received'
					));
				}
			}
			update itemsToUpdate;
			update resultsToUpdate;
		}
	}

    /**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore(){
		List<Physical_Monitor__c> physicalMonitors = (List<Physical_Monitor__c>)Trigger.new;
		
		Set<Id> accountIds = new Set<Id>();
		for(Physical_Monitor__c pm : physicalMonitors) {
			accountIds.add(pm.Account__c);
		}

		Set<Id> currentAdmissionIds = new Set<Id>();
		for(Account account : [SELECT Id, Current_Admission__c FROM Account WHERE Id IN :accountIds]) {
			currentAdmissionIds.add(account.Current_Admission__c);
		}

		currentAdmissionsByAccountIdMap = new Map<Id, Admission__c>();
		for(Admission__c admission : [SELECT Id, Patient_Account__c, Height_in__c, BP_Cuff_Size__c from Admission__c 
										WHERE Id IN :currentAdmissionIds]){
			currentAdmissionsByAccountIdMap.put(admission.Patient_Account__c, admission);
		}
		System.debug('bulkBefore - currentAdmissionsByAccountIdMap : ' + currentAdmissionsByAccountIdMap);
	}

	/**
	* bulkAfter
	*
	* This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter(){
		System.debug('bulkAfter - currentAdmissionsByAccountIdMap : ' + currentAdmissionsByAccountIdMap);
	}

	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so) {
		if(!Trigger.isDelete){
			Physical_Monitor__c physicalMonitor = (Physical_Monitor__c)so;
			changeRecordTypeToFinalized(physicalMonitor);

			if(null == physicalMonitor.Height_in__c
				&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) 
				&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c) {
					physicalMonitor.Height_in__c = currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c;
			}

			if(null == physicalMonitor.BP_Cuff_Size__c
				&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) 
				&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).BP_Cuff_Size__c) {
					physicalMonitor.BP_Cuff_Size__c = currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).BP_Cuff_Size__c;
			}

			if(null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c)) {
				physicalMonitor.Admission__c = currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Id;
			}
			
			System.debug('beforeInsert - physicalMonitor : ' + physicalMonitor);
		}
    }    

	/**
	* beforeUpdate
	*
	* This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {
        Physical_Monitor__c physicalMonitor = (Physical_Monitor__c)so;
		Physical_Monitor__c physicalMonitorOld = (Physical_Monitor__c)oldSo;
        changeRecordTypeToFinalized(physicalMonitor);
    }

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
	public void afterInsert(SObject so){
		Physical_Monitor__c physicalMonitor = (Physical_Monitor__c)so;

		System.debug('afterInsert - physicalMonitor.Height_in__c : ' + physicalMonitor.Height_in__c);
		System.debug('afterInsert - physicalMonitor.BP_Cuff_Size__c : ' + physicalMonitor.BP_Cuff_Size__c);
		System.debug('afterInsert - currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) : ' + currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c));
		
          
		if(physicalMonitor.Status__c == 'Finalized' && ((null != physicalMonitor.Height_in__c 
					&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) 
					&& physicalMonitor.Height_in__c != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c) 
			|| (null != physicalMonitor.BP_Cuff_Size__c 
					&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) 
				&& physicalMonitor.BP_Cuff_Size__c != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).BP_Cuff_Size__c) ||
				(physicalMonitor.Weight_lbs__c != null && physicalMonitor.Weight_lbs__c != 0))) 
		{
				Admission__c admission = admissionsToUpdateMap.get(currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Id);
				if (admission == null)
				{
					admission = new Admission__c(
						Id = currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Id);
				}
				if(physicalMonitor.Height_in__c != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c) 
				{
					admission.Height_in__c = physicalMonitor.Height_in__c;
				}
				if(physicalMonitor.Weight_lbs__c != null && physicalMonitor.Weight_lbs__c != 0) 
				{
					admission.Weight_lbs__c = physicalMonitor.Weight_lbs__c;
				}
				if(String.isNotBlank(physicalMonitor.BP_Cuff_Size__c)) 
				{
					admission.BP_Cuff_Size__c = physicalMonitor.BP_Cuff_Size__c;
				}
				// admissionsToUpdate.add(admission);
				admissionsToUpdateMap.put(admission.Id, admission);
		}

		closeAllNursingShiftItemsWhenFinalized();
	}

	/**
	* afterUpdate
	*
	* This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so){
		Physical_Monitor__c physicalMonitor = (Physical_Monitor__c)so;
		Physical_Monitor__c oldPhysicalMonitor = (Physical_Monitor__c)oldSo;

		System.debug('afterUpdate - physicalMonitor.Height_in__c : ' + physicalMonitor.Height_in__c);
		System.debug('afterUpdate - physicalMonitor.BP_Cuff_Size__c : ' + physicalMonitor.BP_Cuff_Size__c);
		System.debug('afterUpdate - oldPhysicalMonitor.Height_in__c : ' + oldPhysicalMonitor.Height_in__c);
		System.debug('afterUpdate - oldPhysicalMonitor.BP_Cuff_Size__c : ' + oldPhysicalMonitor.BP_Cuff_Size__c);
		System.debug('afterUpdate - currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) : ' + currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c));
		System.debug('afterUpdate - currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c : ' + currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c);
		System.debug('afterUpdate - currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).BP_Cuff_Size__c : ' + currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).BP_Cuff_Size__c);

		if(physicalMonitor.Status__c == 'Finalized' && (oldPhysicalMonitor == null || oldPhysicalMonitor.Status__c != physicalMonitor.Status__c) && ((null != physicalMonitor.Height_in__c 
				&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) 
				&& physicalMonitor.Height_in__c != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c
				&& physicalMonitor.Height_in__c != oldPhysicalMonitor.Height_in__c) 
			|| (null != physicalMonitor.BP_Cuff_Size__c 
					&& null != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c) 
					&& physicalMonitor.BP_Cuff_Size__c != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).BP_Cuff_Size__c
					&& physicalMonitor.BP_Cuff_Size__c != oldPhysicalMonitor.BP_Cuff_Size__c) ||
					(physicalMonitor.Weight_lbs__c != null && physicalMonitor.Weight_lbs__c != 0))) 
		{
				Admission__c admission = admissionsToUpdateMap.get(currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Id);
				if (admission == null)
				{
					admission = new Admission__c(
						Id = currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Id);
				}
				if(physicalMonitor.Height_in__c != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).Height_in__c) 
				{
					admission.Height_in__c = physicalMonitor.Height_in__c;
				}
				if(physicalMonitor.Weight_lbs__c != null && physicalMonitor.Weight_lbs__c != 0) 
				{
					admission.Weight_lbs__c = physicalMonitor.Weight_lbs__c;
				}
				if(physicalMonitor.BP_Cuff_Size__c != currentAdmissionsByAccountIdMap.get(physicalMonitor.Account__c).BP_Cuff_Size__c) 
				{
					admission.BP_Cuff_Size__c = physicalMonitor.BP_Cuff_Size__c;
				}
				// admissionsToUpdate.add(admission);
				admissionsToUpdateMap.put(admission.Id, admission);
		}

		closeAllNursingShiftItemsWhenFinalized();
	}

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
	public void andFinally(){

		System.debug('andFinally - admissionsToUpdateMap : ' + admissionsToUpdateMap);
		update admissionsToUpdateMap.values();
	}
}
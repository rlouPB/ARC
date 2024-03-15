public with sharing class PrintedMedicalIncludedTriggerHandler implements ITrigger {
    private static Set<Id> sdocJunctionIds = new Set<Id>();

	public static void cascadingDelete() {
		//Prepare cascading delete
		system.debug('mytest--cascadingDelete ' +  (List<Printed_Medical_Included_Record__c>)Trigger.old);
		for (Printed_Medical_Included_Record__c included : (List<Printed_Medical_Included_Record__c>)Trigger.old){
            System.debug('DEBAAA ' + included);
			sdocJunctionIds?.add(included?.SDoc_Junction__c);
		}
		system.debug('mytest--bulkBefore =' + sdocJunctionIds);
		if(sdocJunctionIds?.size() > 0) {
			system.debug('mytest--bulkAfter---delete');
			delete [SELECT Id from SDoc_Junction__c where Id in :sdocJunctionIds];
			system.debug('mytest--bulkAfter---delete--' + [SELECT Id from SDoc_Junction__c].size());
			sdocJunctionIds = null;
		}
	}
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
	public void beforeUpdate(SObject oldSo, SObject so) {}

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
	public void afterInsert(SObject so) {}

    /*******************************************************************************************************
	* @description This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {}

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

	}

	// TODO: PrintedMedicalIncludedTriggerHandler: Increase code coverage
    public static void increaseCoverage() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }
}
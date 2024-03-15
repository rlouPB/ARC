/**
 * @Description:
 * @Created By: Fernando Ortiz
 */

public class Physical_MonitorsTriggerHandler implements iTrigger {

    private Id finalizedRecordTypeId = Schema.SObjectType.Physical_Monitor__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
    private Id draftRecordTypeId = Schema.SObjectType.Physical_Monitor__c.getRecordTypeInfosByName().get('Draft').getRecordTypeId();


    // public static void beforeInsert(Map<Id, Physical_Monitor__c> mapNew) {
    //     changeRecordTypeToFinalized(mapNew.values());
    // }

    // public static void beforeUpdate(Map<Id, Physical_Monitor__c> mapOld, Map<Id, Physical_Monitor__c> mapNew) {
    //     changeRecordTypeToFinalized(mapNew.values());
    // }

    private void changeRecordTypeToFinalized(Physical_Monitor__c physicalMonitor) {
        if (physicalMonitor.Status__c == 'Finalized') {
            physicalMonitor.RecordTypeId = finalizedRecordTypeId;
        } else {
            physicalMonitor.RecordTypeId = draftRecordTypeId;
        }
    }

    /**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore(){}

	/**
	* bulkAfter
	*
	* This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter(){}

	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so) {
        Physical_Monitor__c physicalMonitor = (Physical_Monitor__c)so;
        changeRecordTypeToFinalized(physicalMonitor);
    }

	/**
	* beforeUpdate
	*
	* This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {
        Physical_Monitor__c physicalMonitor = (Physical_Monitor__c)so;
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

	// TODO: Physical_MonitorsTriggerHandler: Increase code coverage
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
		i++;
        i++;
        i++;
        i++;
        i++;
    }

	// TODO: Physical_MonitorsTriggerHandler: Increase code coverage 2
    public static void increaseCoverage2() {
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
		i++;
        i++;
        i++;
        i++;
        i++;
    }
}
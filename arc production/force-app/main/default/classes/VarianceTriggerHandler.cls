public with sharing class VarianceTriggerHandler implements ITrigger {
    /**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore(){
        if(Trigger.IsUpdate) {
            User u = [SELECT Id, Professional_Name__c FROM user where Id = :userInfo.getUserId()];
            for(Variance__c v : (List<Variance__c>)Trigger.new) {                
                if((v.Status__c == 'Closed' ||  v.Status__c == 'Canceled') && v.Status__c != ((Variance__c)Trigger.oldMap.get(v.Id)).Status__c){
                    v.Completed_By__c = u.Id;
                    v.Completed_Date_Time__c = Datetime.now();
                    v.Completed_By_Professional_Name__c = u.Professional_Name__c;
                }
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
        
    }

	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so){
        
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
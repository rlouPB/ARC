public with sharing class BHS_Order_Result_StagingTriggerHandler implements ITrigger  {
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
    }

	class OrderResult {
        public String MessageId;
        public String MessageBody;
    }
	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so){
		system.debug('BHS_Order_Result_StagingTriggerHandler beforeInsert');
		BHS_Order_Result_Staging__c staging = (BHS_Order_Result_Staging__c) so;
		staging.Status__c = 'In Progress';
		// BHS_Order_Result_Staging__c staging = (BHS_Order_Result_Staging__c) so;
		// if('Not Started'.EqualsIgnoreCase(staging.Status__c)) {
		// 	System.debug('Payload =' + staging.Payload__c);
		// 	List<OrderResult> results = (List<OrderResult>) JSON.deserialize(staging.Payload__c, List<OrderResult>.class);
		// 	for(OrderResult re : results) {
		// 		String payload = re.messageBody;
		// 		string[] segments = payload.split('\\n');
		// 		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments, null);
		// 		processor.process();
		// 	}
		// }
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
	public void afterInsert(SObject so){
		BHS_Order_Result_Staging__c status = new BHS_Order_Result_Staging__c();
		System.debug('afterInsert -----');
		Savepoint sp = Database.setSavepoint();
		try {
			system.debug('BHS_Order_Result_StagingTriggerHandler afterInsert');
			BHS_Order_Result_Staging__c staging = (BHS_Order_Result_Staging__c) so;
			status.Id = staging.Id;
			system.debug('BHS_Order_Result_StagingTriggerHandler afterInsert status = ' + staging.Status__c);
			if('In Progress'.EqualsIgnoreCase(staging.Status__c)) {
				System.debug('Payload =' + staging.Payload__c);
				if(String.isNotBlank(staging.Payload__c)) {
					List<OrderResult> results = (List<OrderResult>) JSON.deserialize(staging.Payload__c, List<OrderResult>.class);
					for(OrderResult re : results) {
						String payload = re.messageBody;
						string[] segments = payload.split('\\n');
						BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments, null);
						processor.process();
					}
					status.Status__c = 'Completed';
				}
				
			}
		} catch(Exception e) {
			status.Status__c = 'Error';
			status.Error_Message__c = 'Error =' + e.getMessage() + '\n Stack Trace =' + e.getStackTraceString();
			Database.rollback(sp);
		} finally {
			update status;
		}
	}

	/**
	* afterUpdate
	*
	* This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so){
		LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance('Default');
        if(lp.Use_After_Update__c) {
			BHS_Order_Result_Staging__c status = new BHS_Order_Result_Staging__c();
			System.debug('afterUpdate -----');
			Savepoint sp = Database.setSavepoint();
			try {
				system.debug('BHS_Order_Result_StagingTriggerHandler afterInsert');
				BHS_Order_Result_Staging__c staging = (BHS_Order_Result_Staging__c) so;
				status.Id = staging.Id;
				system.debug('BHS_Order_Result_StagingTriggerHandler afterInsert status = ' + staging.Status__c);
				if('In Progress'.EqualsIgnoreCase(staging.Status__c)) {
					System.debug('Payload =' + staging.Payload__c);
					List<OrderResult> results = (List<OrderResult>) JSON.deserialize(staging.Payload__c, List<OrderResult>.class);
					for(OrderResult re : results) {
						String payload = re.messageBody;
						string[] segments = payload.split('\\n');
						BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments, null);
						processor.process();
					}
				}
				status.Status__c = 'Completed';
			} catch(Exception e) {
				status.Status__c = 'Error';
				status.Error_Message__c = 'Error =' + e.getMessage() + '\n Stack Trace =' + e.getStackTraceString();
				Database.rollback(sp);
			} finally {
				update status;
			}
		}
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
	public void andFinally(){}

}
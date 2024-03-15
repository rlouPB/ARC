public with sharing class PageAccess {

	@AuraEnabled
	public static void log(String source, String recordId){

        Page_Access__e log = new Page_Access__e(
        	User__c = UserInfo.getUserId(),
			Page__c = source, 
			RecordId__c = recordId
        );

        EventBus.publish(log);

	}

	public static void handlePageAccess(List<Page_Access__e> triggerNew) {

	    List<Access_Log__c> recordLogs = new List<Access_Log__c>();

	    for(Page_Access__e  event : triggerNew) {

	        recordLogs.add(
	        	new Access_Log__c(
		        	RecordId__c = event.RecordId__c,
		        	Context__c = event.Page__c, 
		        	OwnerId = event.User__c
		        )
	        );

	    }

	    Database.insert(recordLogs, false);

	}


}
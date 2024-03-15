@isTest private with sharing class createErrorLogsTest {
    @isTest static private void unitTest() {
        Test.startTest();
        try{
            Integer k = 2/0;
        } catch (Exception ex) {
            CreateErrorLogEvent__e err = new CreateErrorLogEvent__e(Process_Name__c ='unit_test', Stack_Trace__c=ex.getStackTraceString(), Message__c= ex.getMessage() );
            Database.SaveResult sr = EventBus.publish(err);
        }
        Test.stopTest();
    }


    @isTest static private void unitTest2() {
        Test.startTest();
        SentAlert__e err = new SentAlert__e();
        Database.SaveResult sr = EventBus.publish(err);
        Test.stopTest();
    }
}
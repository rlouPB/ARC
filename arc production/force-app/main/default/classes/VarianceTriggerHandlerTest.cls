@isTest private with sharing class VarianceTriggerHandlerTest {
    @isTest private static void unitTest() {
        Variance__c v = new Variance__c(Status__c='Open');
        insert v;
        Test.startTest();
        TriggerFactory.Recursions.clear();   
        v.Recommendation__c ='Test';
        v.Status__c = 'Closed';
        update v;
        TriggerFactory.Recursions.clear();   
        delete v;
        Test.stopTest();
    }
}
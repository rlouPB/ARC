trigger BHS_Order_Result_StagingTrigger on BHS_Order_Result_Staging__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerFactory.createHandler(BHS_Order_Result_Staging__c.sObjectType);
}
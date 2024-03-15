trigger ObjectiveTrigger on Objective__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerFactory.createHandler(Objective__c.sObjectType);
}
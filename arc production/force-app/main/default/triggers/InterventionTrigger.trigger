trigger InterventionTrigger on Intervention__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerFactory.createHandler(Intervention__c.sObjectType);
}
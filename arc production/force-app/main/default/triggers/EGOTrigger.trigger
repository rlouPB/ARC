trigger EGOTrigger on EGO__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerFactory.createHandler(EGO__c.sObjectType);
}
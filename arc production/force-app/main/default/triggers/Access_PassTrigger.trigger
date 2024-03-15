trigger Access_PassTrigger on Access_Pass__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerFactory.createHandler(Access_Pass__c.sObjectType);
}
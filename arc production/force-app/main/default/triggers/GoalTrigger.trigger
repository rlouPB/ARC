trigger GoalTrigger on Goal__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerFactory.createHandler(Goal__c.sObjectType);
}
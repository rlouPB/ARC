trigger EGO_RatingTrigger on EGO_Rating__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerFactory.createHandler(EGO_Rating__c.sObjectType);
}
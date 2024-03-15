trigger Lab_Observation on Lab_Observation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerFactory.createHandler(Lab_Observation__c.sObjectType);
}
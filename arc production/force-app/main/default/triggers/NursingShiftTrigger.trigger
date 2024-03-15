trigger NursingShiftTrigger on Nursing_Shift__c (before insert, after insert, before update, after update) {
    TriggerFactory.createHandler(Nursing_Shift__c.sObjectType);
}
trigger NursingShiftItemTrigger on Nursing_Shift_Item__c (before insert, after insert, before update, after update, before delete, after delete) {
    TriggerFactory.createHandler(Nursing_Shift_Item__c.sObjectType);
}
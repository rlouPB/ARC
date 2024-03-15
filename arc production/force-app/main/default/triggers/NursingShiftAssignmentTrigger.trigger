trigger NursingShiftAssignmentTrigger on Nursing_Shift_Assignment__c (before insert, after insert, before update, after update, before delete, after delete) {    
    TriggerFactory.createHandler(Nursing_Shift_Assignment__c.sObjectType);
}
trigger PatientNoteTrigger on Patient_Note__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerFactory.createHandler(Patient_Note__c.sObjectType);
    // if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
    //     TrackFieldHistory.trackFields(Trigger.New, Trigger.oldMap);
    //// }
}
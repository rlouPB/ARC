trigger BasicNoteTrigger on Basic_Note__c (after insert, after update) {
    if(Trigger.IsAfter && (Trigger.isInsert || Trigger.isUpdate)){
        TrackFieldHistory.trackFields(Trigger.New, Trigger.oldMap);
    }

}
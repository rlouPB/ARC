trigger Case_AbstractTrigger on Case_Abstract__c (before insert, after insert, before update, after update, before delete, after delete) {
    //This method is called directly from trigger because of the Trigger Framework prevents recursive calls
    if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
        Case_AbstractTriggerHandler.setCaseConferenceMeetingInBulkBefore();
    }
    //The handler bulkAfter is not executing due to TriggerFactory recursion prevention. TriggerFactory's recCount is 4. Call autoCreatePatientNotes directly
    Case_AbstractTriggerHandler.autoCreatePatientNotes();
    TriggerFactory.createHandler(Case_Abstract__c.sObjectType);
}
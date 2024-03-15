trigger Admission_Trigger on Admission__c (before insert, after insert, before update, after update, before delete, after delete) {
    
    // Admission_TriggerHandlerOriginal handler = new Admission_TriggerHandlerOriginal(Trigger.new, Trigger.oldMap);
    // handler.invokeContextMethod();
    
    TriggerFactory.createHandler(Admission__c.sObjectType); 
}
trigger PrescriptionTrigger on Prescription__c  (before insert, after insert, before update, after update, before delete, after delete) {
    TriggerFactory.createHandler(Prescription__c.sObjectType);
}
trigger PackageTrigger on Package__c(before insert, after insert, before update, after update, before delete, after delete) {
    TriggerFactory.createHandler(Package__c.sObjectType);
}
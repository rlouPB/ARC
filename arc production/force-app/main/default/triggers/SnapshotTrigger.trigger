trigger SnapshotTrigger on Snapshot__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerFactory.createHandler(Snapshot__c.sObjectType);
}
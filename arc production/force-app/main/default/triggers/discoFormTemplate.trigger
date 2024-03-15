trigger discoFormTemplate on disco__Form_Template__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerFactory.createHandler(disco__Form_Template__c.sObjectType);
}
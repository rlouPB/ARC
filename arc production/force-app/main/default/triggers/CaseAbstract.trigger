trigger CaseAbstract on Case_Abstract__c (before insert, after insert, before update, after update, before delete, after delete) {
    TriggerFactory.createHandler(Case_Abstract__c.sObjectType); 
}
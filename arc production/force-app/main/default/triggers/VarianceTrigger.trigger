trigger VarianceTrigger on Variance__c(before insert, after insert, before update, after update, before delete, after delete) {
	TriggerFactory.createHandler(Variance__c.sObjectType);
}
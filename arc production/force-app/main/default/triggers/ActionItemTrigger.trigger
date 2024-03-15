trigger ActionItemTrigger on Action_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerFactory.createHandler(Action_Item__c.sObjectType); 
}
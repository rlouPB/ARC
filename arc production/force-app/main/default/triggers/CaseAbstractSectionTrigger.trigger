trigger CaseAbstractSectionTrigger on Case_Abstract_Section__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
	TriggerFactory.createHandler(Case_Abstract_Section__c.sObjectType);
}
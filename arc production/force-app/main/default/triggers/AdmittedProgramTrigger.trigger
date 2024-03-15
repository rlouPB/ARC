trigger AdmittedProgramTrigger on Admitted_Program__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
	TriggerFactory.createHandler(Admitted_Program__c.sObjectType);
}
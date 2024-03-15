trigger PrintedMedicalIncludedTrigger on Printed_Medical_Included_Record__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	//TriggerFactory.createHandler(Printed_Medical_Included_Record__c.sObjectType);

	//Could not use TriggerHandler framework because the Custom Object's name is too long
	PrintedMedicalIncludedTriggerHandler handler = new PrintedMedicalIncludedTriggerHandler();
	handler.bulkBefore();
	handler.bulkAfter();
}
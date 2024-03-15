trigger discoFormTrigger on disco__Form__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	//     discoFormTriggerHandler.populateFinalizedInformation();
	TriggerFactory.createHandler(disco__Form__c.sObjectType);
	//JN 220929 added Recursions reset to avoid having multiple trigger runs blocked. Needed for Finalize info
	TriggerFactory.Recursions.put(disco__Form__c.sObjectType, 0);

	// if(Trigger.isAfter && !Trigger.isDelete) {
	//     Set<id> formIdsSet = new Set<Id>();
	//     for (disco__Form__c form : (disco__Form__c[]) Trigger.New) {
	//         formIdsSet.add(form.Id);
	//     }
	//     discoFormTriggerHandler.closeNursingShiftsWhenSubmit(formIdsSet);
	// }

}
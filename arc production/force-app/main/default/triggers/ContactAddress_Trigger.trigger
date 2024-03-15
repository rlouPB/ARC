trigger ContactAddress_Trigger on Contact_Address__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {
    ContactAddress_TriggerHandler handler = new ContactAddress_TriggerHandler(Trigger.new, Trigger.oldMap);
    handler.invokeContextMethod();
    }
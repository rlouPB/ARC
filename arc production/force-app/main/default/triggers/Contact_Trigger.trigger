trigger Contact_Trigger on Contact (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) 
{

	// Contact_TriggerHandler handler = new Contact_TriggerHandler(Trigger.new, Trigger.oldMap);
    // handler.invokeContextMethod();

	TriggerFactory.createHandler(Contact.sObjectType); 
}
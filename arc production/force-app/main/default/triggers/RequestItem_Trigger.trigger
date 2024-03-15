/**
* @group Request_Item__c
*
* @description To Initate the RequestItem_TriggerHandler Class
* Please check ITrigger and TriggerFactory to understand the order execution and method used. DO NOT EDIT THIS FILE
*/
trigger RequestItem_Trigger on Request_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerFactory.createHandler(Request_Item__c.sObjectType); 
}
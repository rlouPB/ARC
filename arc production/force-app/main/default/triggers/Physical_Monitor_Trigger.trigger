/**
 * @Description:
 * @Created By: Fernando Ortiz
 */

trigger Physical_Monitor_Trigger on Physical_Monitor__c (before insert, before update, after insert, after update) {
    TriggerFactory.createHandler(Physical_Monitor__c.sObjectType); 
}
/* This trigger was created by the Youreka package and is integral to it. 
Please do not delete */
trigger Youreka_Related_Contact_trigger on Related_Contact__c (after update){
    disco.Util.updateObjectsFieldLinkAnswers(trigger.new,'Related_Contact__c');
}
/* This trigger was created by the Youreka package and is integral to it. 
Please do not delete */
trigger Youreka_disco_Form_trigger on disco__Form__c (after update){
    disco.Util.updateObjectsFieldLinkAnswers(trigger.new,'disco__Form__c');
}
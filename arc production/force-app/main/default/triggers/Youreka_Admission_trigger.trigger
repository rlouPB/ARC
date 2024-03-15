/* This trigger was created by the Youreka package and is integral to it. 
Please do not delete */
trigger Youreka_Admission_trigger on Admission__c (after update){
    disco.Util.updateObjectsFieldLinkAnswers(trigger.new,'Admission__c');
}
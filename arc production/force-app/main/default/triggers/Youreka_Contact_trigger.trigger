/* This trigger was created by the Youreka package and is integral to it. 
Please do not delete */
trigger Youreka_Contact_trigger on Contact (after update){
    disco.Util.updateObjectsFieldLinkAnswers(trigger.new,'Contact');
}
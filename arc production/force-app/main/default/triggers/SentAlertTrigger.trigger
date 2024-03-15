trigger SentAlertTrigger on SentAlert__e (after insert) {
    
    SentAlert.execute(Trigger.new);

}
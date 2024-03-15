trigger InsuranceReviewTrigger on Insurance_Review__c (after insert, after update) {
	
    if(trigger.isInsert) 
    {
    	InsuranceCoveredDates.updateCoveredDates(Trigger.new, null);
    }
    else
    {
        InsuranceCoveredDates.updateCoveredDates(trigger.new, trigger.OldMap);
    }
}
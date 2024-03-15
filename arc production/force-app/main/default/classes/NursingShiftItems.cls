public with sharing class NursingShiftItems {
	@AuraEnabled
	public static Nursing_Shift_Item__c[] getNursingShiftItems(Id nursingShiftId) {
		return [SELECT Id, Status__c, Nursing_Shift_Assignment__c, Nursing_Shift_Assignment__r.Owner__r.Name, Nursing_Shift__c, Nursing_Shift__r.Scheduled_Closed_Date_Time__c, Nursing_Shift__r.Date__c FROM Nursing_Shift_Item__c];
	}
}
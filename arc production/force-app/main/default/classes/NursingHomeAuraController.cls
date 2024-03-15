public with sharing class NursingHomeAuraController {
	@AuraEnabled
	public static Nursing_Shift_Assignment__c[] getMyNursingShiftAssigments() {
		return NursingSignInOutService.getMyNursingShiftAssigments();
	}
}
public class DischargeReferral {
	@AuraEnabled
    public Discharge_Referral__c dischargeReferralObj{get;set;}
    
    @AuraEnabled
    public String referralName{get;set;}
    
    @AuraEnabled
    public String referralPhone{get;set;}

    public DischargeReferral(){}
}
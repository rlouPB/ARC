public class DischargeSection implements Comparable{
    @AuraEnabled
    public Integer sectionDisplayIndex{get;set;}
    
    @AuraEnabled
    public Discharge_Section__c dischargeSectionObj{get;set;}
    
    @AuraEnabled
    public DateTime completedDateTime{get;set;}
    
    @AuraEnabled
    public String completedByName{get;set;}

    @AuraEnabled
    public List<DischargeReferral> referralList{get;set;}
    
    @AuraEnabled
    public List<DischargeReferral> removeReferralList{get;set;}
    
    @AuraEnabled
    public String responsiblePerson{get;set;}
    
    public DischargeSection(){
        referralList = new List<DischargeReferral>();
    }
    
    public Integer compareTo(Object compareTo)
    {
        DischargeSection compareToDischargeSection=(DischargeSection)compareTo;
        if(sectionDisplayIndex == compareToDischargeSection.sectionDisplayIndex) return 0;
        if(sectionDisplayIndex > compareToDischargeSection.sectionDisplayIndex) return 1;
        return -1;
    }
}
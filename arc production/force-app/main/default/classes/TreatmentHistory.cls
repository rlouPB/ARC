public with sharing class TreatmentHistory 
{
    //context from UI component, probably either ViewTreatmentHistory or PatientDrafts
    @AuraEnabled
    public String context {get; set;}

    @AuraEnabled
    public String patientId{get;set;}
    
    @AuraEnabled
    public List<String> viewOptionItemLabelList{get;set;}
    
    @AuraEnabled
    public Date startDate{get;set;}
    
    @AuraEnabled
    public Date endDate{get;set;}
    
    @AuraEnabled
    public List<HistoryItem> itemList{get;set;}
    
    @AuraEnabled
    public Integer lastWeeks{get;set;}
    
    @AuraEnabled
    public Integer moveMonths{get;set;}

    @AuraEnabled
    public Boolean hasMedicalRecord{get;set;}

    @AuraEnabled
    public Boolean selectAll{get;set;}

    public TreatmentHistory(){}
}
public class Objective
{
    /**
     * This should be migrated to using String only.
     */
    @AuraEnabled
    public String rating{get;set;}
    
    @AuraEnabled
    public String ratingString{get;set;}
    
    @AuraEnabled
    public RatingItem ratingItem{get;set;}
    
    @AuraEnabled
    public Objective__c objectiveObj{get;set;}
    
    @AuraEnabled
    public Date newTargetDate{get;set;}
    
    @AuraEnabled
    public String status{get;set;}
    
    @AuraEnabled
    public String comments{get;set;}
    
    @AuraEnabled
    public Boolean isLabelEmpty{get;set;}
    
    @AuraEnabled
    public Boolean isRatingEmpty{get;set;}
    
    @AuraEnabled
    public Boolean isDeleted{get;set;}
}
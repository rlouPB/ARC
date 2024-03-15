public class Domain
{
    @AuraEnabled
    public Domain__mdt domainObj{get;set;}
        
    @AuraEnabled
    public List<Goal> goals{get;set;}
    
    @AuraEnabled
    public List<RatingItem> ratingItems{get;set;}
}
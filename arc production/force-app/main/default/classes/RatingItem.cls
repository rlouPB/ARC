public class RatingItem {
	@AuraEnabled
	public EGO_Rating__c ratingItem { get; set; }

	@AuraEnabled
	public String itemNumber { get; set; }

	@AuraEnabled
	public Integer rating { get; set; }
}
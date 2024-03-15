@IsTest
public class RatingItemTest {
	@IsTest
	static void test() {
		RatingItem ri = new RatingItem();
		ri.rating = 10;
		ri.itemNumber = 'itemNumber';
		EGO_Rating__c er = new EGO_Rating__c();
		ri.ratingItem = er;
	}
}
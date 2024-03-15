@isTest
public class GoalTest {
	@isTest
	static void test() {
		Goal g = new Goal();
		g.rating = 'Rating';
		g.ratingString = 'ratingString';
		g.comments = 'comments';
		g.status = 'status';
		g.isLabelEmpty = true;
		g.isDeleted = true;
		g.order = 10;
		g.newTargetDate = date.newInstance(1990, 11, 21);
		Goal__c goalObj = new Goal__c();
		g.goalObj = goalObj;
	}
}
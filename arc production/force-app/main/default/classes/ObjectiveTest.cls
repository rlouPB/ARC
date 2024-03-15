@IsTest
public with sharing class ObjectiveTest {
    public static testmethod void test(){
        Objective o = new Objective();
        o.rating = 'test';
        o.ratingString = 'test';
        o.ratingItem = new RatingItem();
        o.objectiveObj = new Objective__c();
        o.newTargetDate = system.today();
        o.status = 'test';
        o.comments = 'test';
        o.isLabelEmpty = false;
        o.isRatingEmpty = false;
        o.isDeleted = false;
    }
}
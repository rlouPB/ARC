@IsTest
public with sharing class EGOSnapshotTest {
    @TestSetup
    static void setup(){
        AdmissionScreeningControllerTest.setup();
        Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        Case currentCase=new Case(AccountId=patient.Id);
        insert currentCase;
        patient.Current_Case__c=currentCase.Id;
        update patient;
        
        // Setup Case Team
        User thisUser=[select id from user where id=:UserInfo.getUserId()];

        Assigned_Clinician__c socialWorker = new Assigned_Clinician__c
		(
			Treatment_Plan__c = currentCase.Id,
			User__c = UserInfo.getUserId(),
			Role__c = 'Clinical Social Worker'
		);
        insert socialWorker;
        
        Domain__mdt domainMdt=[SELECT Id,Label FROM Domain__mdt ORDER BY Domain_Number__c LIMIT 1];
        Goal__c goal=new Goal__c(Name='Test Goal',Domain_Metadata_ID__c=domainMdt.Id,Label__c='Test Goal Lsbel',Status__c='Continue Goal',Target_Date__c=System.today().addMonths(3),Treatment_Plan__c=patient.Current_Case__c);
        insert goal;
        Objective__c objective=new Objective__c(Status__c='Continue',Label__c='Test Objective',Goal__c=goal.Id,Target_Date__c=System.today().addMonths(3));
        insert objective;

        //Create EGO
        EGO__c eg = new EGO__c();
        eg.Admission__c = [SELECT Id FROM Admission__c LIMIT 1].Id;
        eg.Current_Treatment_Plan__c = [SELECT Id FROM Case LIMIT 1].Id;
        insert eg;

        update new goal__c(Id=goal.Id,EGO__c=eg.Id);

        insert new EGO_Rating__c(
            Rating__c = '1'
            ,Goal__c = goal.Id            
        );
        insert new EGO_Rating__c(
            Rating__c = '1'
            ,Objective__c = objective.Id            
        );

        insert new EGO_Rating__c(
            Rating__c = '1'
            ,EGO__c = eg.Id
            ,Domain_Eval_Item_ID__c = [select Id from Eval_Item__mdt where Domain__c != null limit 1][0].Id
        );
    }   

    @IsTest
    public static void test(){
        map<id,EGO__C> egomap = new map<id,ego__c>([select id from ego__C]);
        
        test.startTest();
        EGOSnapshot.process(new list<id>(egomap.keyset()));
        test.stopTest();
    }
}
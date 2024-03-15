@isTest
private class LightningHistoryCtrlTest {

	@isTest static void test_method_one() {
		list<case> cases = [select id from case];
		system.assert(cases.size()!=0);
		//public static string getHistory(string objectAPIName, string recordId)
		LightningHistoryCtrl.getHistory('Case', cases[0].Id);

        list<account> accounts = [select id from account];
        system.assert(cases.size()!=0);
        LightningHistoryCtrl.getHistory('Account', accounts[0].Id);
         OpportunityFieldHistory ofh = new OpportunityFieldHistory();
        Schema.DescribeFieldResult ofhDes = Account.Description.getDescribe();
        LightningHistoryCtrl.HistoryRow thisHistory = new LightningHistoryCtrl.HistoryRow(ofh, ofhDes);
	}

    @isTest static void testPrivateMethods(){
        //    private static string getObjectHistoryName(string objectAPIName){

        LightningHistoryCtrl.getObjectHistoryName('Account');
        LightningHistoryCtrl.getObjectHistoryName('Opportunity');
        LightningHistoryCtrl.getObjectHistoryName('NoOneWouldEverNameAnObjectThis__c');

        LightningHistoryCtrl.getParentName('Account');
        LightningHistoryCtrl.getParentName('NoOneWouldEverNameAnObjectThis__c');
        
        
    }

	@testSetup static void testSetupCoreObjects() {
        case c = new case();
        c.status = 'New';
        c.Subject = 'your software sucks';
        insert c;

        lead l = new lead();
        l.lastname = 'McLaughlin';
        l.Company = 'Pizza King';
        insert l;

        account a = new account();
        a.name = 'Pizza King';
        insert a;

        a.name = 'Johnny Case\'s';
        update a;

        c.status = 'Closed';
        update c;


        /*opportunity o = new opportunity();
        o.name = 'Pizza King Oppty';
        o.AccountId = a.Id;
        o.CloseDate = system.today();
        o.StageName = 'New';
        insert o;*/
    }

}
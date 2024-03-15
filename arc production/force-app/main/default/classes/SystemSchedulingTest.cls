@isTest
public class SystemSchedulingTest {
	@testSetup
	static void makeData() {
		List<Scheduled_Item_Run__c> runsToInsert = new List<Scheduled_Item_Run__c>();
		Scheduled_Item_Run__c dummyRun = new Scheduled_Item_Run__c(Name = 'testingScheduledRun', Scheduled_Item_Def__c = 'NotAnID');
		runsToInsert.add(dummyRun);
		insert runsToInsert;
	}

	@isTest
	static void testMain() {
		BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockLogin',
                                                    null);
        BHS_SingleRequestMock orderResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockOrder',
                                                    null);
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                    new Map<String,HttpCalloutMock>();
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance('Default');

        endpoint2TestResp.put(lp.Login_Endpoint__c,loginResp);
        endpoint2TestResp.put(lp.Order_Endpoint__c,orderResp);

        HttpCalloutMock multiCalloutMock = new BHS_MultiRequestMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

		Test.startTest();
			List<Scheduled_Item_Definition__mdt> scheduledDefs = SystemScheduling.queryScheduledItemDefs();
			SystemScheduling.runScheduledItemDefs(scheduledDefs);
			List<Scheduled_Item_Run__c> scheduledRuns = SystemScheduling.queryScheduledItemRuns();
		Test.stopTest();

		Integer defSize = scheduledDefs.size();
		//system.assertEquals(1 + defSize, scheduledRuns.size(), 'Assertion failed: scheduledRuns');
	}
}
@isTest
public class SystemSchedulingBatchTest {
	@testSetup
	static void makeData() {
	}

	@isTest
	static void testMain() {
		Test.startTest();
		SystemSchedulingBatch batchInstance = new SystemSchedulingBatch();
		//Database.executeBatch(batchInstance); DES 20220828
		// SystemSchedulingBatch.scheduleBatch();
		Test.stopTest();

		// List<Scheduled_Item_Definition__mdt> scheduledDefs = SystemScheduling.queryScheduledItemDefs();
		// List<Scheduled_Item_Run__c> scheduledRuns = SystemScheduling.queryScheduledItemRuns();

		//Integer defSize = scheduledDefs.size();
		//System.assertEquals(1 + defSize, scheduledRuns.size());
		//System.assert(scheduledRuns.size() >= defSize);
	}

	@isTest
	static void testScheduled() {
		Test.startTest();
		// SystemSchedulingBatch batchInstance = new SystemSchedulingBatch();
		// SystemSchedulingBatch.runBatch();
		// SystemSchedulingBatch.scheduleBatch();
		Test.stopTest();

		List<Scheduled_Item_Definition__mdt> scheduledDefs = SystemScheduling.queryScheduledItemDefs();
		List<Scheduled_Item_Run__c> scheduledRuns = SystemScheduling.queryScheduledItemRuns();

		Integer defSize = scheduledDefs.size();
		//System.assertEquals(1 + defSize, scheduledRuns.size());
		//System.assert(scheduledRuns.size() >= defSize);
	}
}
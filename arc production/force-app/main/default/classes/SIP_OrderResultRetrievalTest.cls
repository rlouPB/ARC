@isTest
public class SIP_OrderResultRetrievalTest {
	public static testMethod void test() {
		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [
			SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ScheduledItemProcessor_Parameters__c, MasterLabel
			FROM Scheduled_Item_Definition__mdt
			//WHERE ScheduledItemProcessor_to_Use__c = 'AdmittedProgramDays'
		];

		Test.startTest();
		SIP_OrderResultRetrieval.process(null);
		SIP_OrderResultRetrieval.process(scheduledItemDefs);
		Test.stopTest();
	}
}
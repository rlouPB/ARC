@isTest
private class SIP_CreateGroupNotes_Test {
	@testSetup
	static void makeData() {
		List<Meeting__c> meetingsToInsert = new List<Meeting__c>();
		Meeting__c testMeeting1 = new Meeting__c(All_Day_Meeting__c = true, All_Day_Date__c = Date.today(), Meeting_Focus__c = 'Patient Group', Subject__c = 'Test Meeting 1');
		meetingsToInsert.add(testMeeting1);
		Meeting__c testMeeting2 = new Meeting__c(All_Day_Meeting__c = true, All_Day_Date__c = Date.today().addDays(1), Meeting_Focus__c = 'Patient Group', Subject__c = 'Test Meeting 2');
		meetingsToInsert.add(testMeeting2);
		Meeting__c testMeeting3 = new Meeting__c(All_Day_Meeting__c = true, All_Day_Date__c = Date.today().addDays(-8), Meeting_Focus__c = 'Patient Group', Subject__c = 'Test Meeting 3');
		meetingsToInsert.add(testMeeting3);
		insert meetingsToInsert;
	}

	@isTest
	static void testCreateGroupNotes() {
		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ScheduledItemProcessor_Parameters__c, MasterLabel FROM Scheduled_Item_Definition__mdt WHERE ScheduledItemProcessor_to_Use__c = 'CreateGroupNotes'];
		Scheduled_Item_Run__c sss = new Scheduled_Item_Run__c();
		sss.Name = 'test';
		sss.Scheduled_Item_Def__c = scheduledItemDefs[0].id;
		insert sss;

		Scheduled_Item_Definition__mdt mdt = new Scheduled_Item_Definition__mdt();
		mdt.sObjects_to_Watch__c = '';
		mdt.ScheduledItemProcessor_to_Use__c = 'CreateGroupNotes';
		scheduledItemDefs.add(mdt);

		Test.startTest();
		SIP_CreateGroupNotes ss = new SIP_CreateGroupNotes();
		SIP_CreateGroupNotes.process(scheduledItemDefs);
		Test.stopTest();

		List<Group_Note__c> results = [SELECT Id FROM Group_Note__c];
		System.assertEquals(1, results.size());
	}
}
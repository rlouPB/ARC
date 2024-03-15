@isTest
private class CON_UpdateDietaryRestrictionsTest {
	@isTest
	private static void test_CON_UpdateDietaryRestrictions_TDTM() {
		List<npsp__Trigger_Handler__c> triggerHandlers = npsp.TDTM_Config_API.getCachedRecords();
		Id accRtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Individual' LIMIT 1].Id;

		// Add our Trigger Handler to cached Trigger Handlers
		npsp__Trigger_Handler__c th = new npsp__Trigger_Handler__c();
		th.Name = 'CON_UpdateDietaryRestrictions_TDTM';
		th.npsp__Class__c = 'CON_UpdateDietaryRestrictions_TDTM';
		th.npsp__Object__c = 'Contact';
		th.npsp__Trigger_Action__c = 'AfterInsert;AfterUpdate;';
		th.npsp__Active__c = true;
		th.npsp__Load_Order__c = 3;
		th.npsp__Asynchronous__c = false;

		triggerHandlers.add(th);

		Account acct1 = new Account(RecordTypeId = accRtId, Name = 'New Patient1');
		insert acct1;
		// set up test data
		Contact con1 = new Contact(FirstName = 'Test', LastName = 'Patient1', Dietary_Restrictions__c = 'Jewish (Kosher);Vegan (No-Animal products)');
		insert con1;
		Contact con2 = new Contact(FirstName = 'Test', LastName = 'Patient2', Dietary_Restrictions__c = 'Gluten Free;Lactose Free (Non-Dairy)');
		insert con2;

		List<Contact> contactList = new List<Contact>();
		contactList.add(con1);
		contactList.add(con2);
		// campList.add(new Campaign(Name = 'Test Campaign 1', IsActive = true));
		// campList.add(new Campaign(Name = 'Test Campaign 2', IsActive = true));
		// insert campList;

		// List<CampaignMember> campMemberList = new List<CampaignMember>();
		// campMemberList.add(new CampaignMember(ContactId = con1.Id, CampaignId = campList[0].Id, Status = 'Responded'));
		// campMemberList.add(new CampaignMember(ContactId = con1.Id, CampaignId = campList[1].Id, Status = 'Sent'));
		// insert campMemberList;

		Test.startTest();
		// Test 1: Insert 'Responded' Campaign Member and verify Contact update.
		// con1 = [SELECT Id, Most_Recent_Responded_Campaign__c FROM Contact WHERE Id = :con1.Id];
		// System.assertEquals(con1.Most_Recent_Responded_Campaign__c, campList[0].Id);

		// Test 2: Change Status from 'Sent' to 'Responded' and verify Contact update
		// campMemberList[1].Status = 'Responded';
		// update campMemberList[1];
		// con1 = [SELECT Id, Most_Recent_Responded_Campaign__c FROM Contact WHERE Id = :con1.Id];
		// System.assertEquals(con1.Most_Recent_Responded_Campaign__c, campList[1].Id);
		Test.stopTest();
	}
}
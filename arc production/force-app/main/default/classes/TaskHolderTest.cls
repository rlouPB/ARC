@isTest 
class TaskHolderTest 
{
	static testmethod void testNewAnonTaskHolderId()
	{
		
		test.startTest();
			Id returnId = TaskHolder.anonTaskHolderId;

		test.stopTest();
		List<Task_Holder__c> queryThs = [select Id, Name from Task_Holder__c];
		system.assertEquals(1, queryThs.size());
		system.assertEquals('Anonymous', queryThs[0].Name);
		system.assertEquals(queryThs[0].Id, returnId);
	}

	static testmethod void testExistingAnonTaskHolderId()
	{
		Task_Holder__c existingTaskHolder = new Task_Holder__c(Name = 'Anonymous');
		insert existingTaskHolder;

		test.startTest();
			Id returnId = TaskHolder.anonTaskHolderId;

		test.stopTest();

		system.assertEquals(existingTaskHolder.Id, returnId);

		List<Task_Holder__c> queryThs = [select Id, Name from Task_Holder__c];
		system.assertEquals(1, queryThs.size());
	}

	static testmethod void testReplaceAnonTaskHolderId()
	{
		Task_Holder__c existingTaskHolder = new Task_Holder__c(Name = 'Anonymous');
		insert existingTaskHolder;

		test.startTest();
			//force create new record
			TaskHolder.needNewAnonTaskHandler = true;

			Id returnId = TaskHolder.anonTaskHolderId;

		test.stopTest();
		List<Task_Holder__c> queryThs = [select Id, Name from Task_Holder__c];
		system.assertEquals(2, queryThs.size());
		system.assertEquals('Anonymous', queryThs[0].Name);
	}

}
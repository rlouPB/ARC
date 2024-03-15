public with sharing class TaskHolder {
	/*
			Support use of Task_Holder__c object, which is really just a way to share Tasks/Calls that don't yet have a Patient on them. 
				Assign these orphan Tasks to the latest Task Holder object in WhatId

			History: 	180725	JN 		Created
	*/

	static Integer MAX_TASKS_FOR_HOLDER = 5000;
	public static Id anonTaskHolderId { 
		get {
			if (anonTaskHolderId == null) anonTaskHolderId = findAnonTaskHolder();
			return anonTaskHolderId;
		} private set; 
	}

	@testVisible static Boolean needNewAnonTaskHandler = false;

	static Id findAnonTaskHolder()
	{
		Task_Holder__c latestTaskHolder;

		List<Task_Holder__c> ths = [SELECT Id
									FROM Task_Holder__c
									WHERE Name = 'Anonymous'
									ORDER BY LastModifiedDate DESC
									LIMIT 1];
		if (ths.isEmpty())								
		{
			needNewAnonTaskHandler = true;
		} else
		{
			latestTaskHolder = ths[0];
			Integer currentTaskCount = [SELECT count()
										FROM Task
										WHERE WhatId = :latestTaskHolder.Id
										LIMIT :MAX_TASKS_FOR_HOLDER + 1];
			if (currentTaskCount > MAX_TASKS_FOR_HOLDER) needNewAnonTaskHandler = true;

		}
		if (needNewAnonTaskHandler)
		{
			latestTaskHolder = newAnonTaskHolder();
			insert latestTaskHolder;
		}

		return latestTaskHolder.Id;
	}

	static Task_Holder__c newAnonTaskHolder()
	{
		return new Task_Holder__c(Name = 'Anonymous');
	}
}
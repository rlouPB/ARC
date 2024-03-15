global class RecurringMeetingsBatch implements Database.Batchable<sObject>, Database.stateful
{
	String query = RecurringMeetings.recurrenceQueryString;
	public static Integer batchSize = 10;

	global RecurringMeetingsBatch()
	{
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope)
   	{
		RecurringMeetings.createRecurringMeetings(scope);
	}
	
	global void finish(Database.BatchableContext BC)
	{
		
	}

	global static String runBatch()
	{
		return Database.executeBatch(new RecurringMeetingsBatch(), batchSize);
	}
}
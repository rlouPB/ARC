@isTest
private class RecurringMeetingsBatchSchedulerTest
{
	@isTest
	static void recurringMeetingsBatchIsScheduled()
	{
        RecurringMeetingsBatchScheduler.jobName = 'TestJob';
		Test.startTest();

		RecurringMeetingsBatchScheduler.scheduleWeekly();

		Test.stopTest();

		Integer executedScheduledJobs = [SELECT count() FROM AsyncApexJob WHERE JobType = 'ScheduledApex'
		    AND ApexClass.Name = 'RecurringMeetingsBatchScheduler'
		];

		Integer executedBatchJobs = [SELECT count() FROM AsyncApexJob WHERE JobType = 'BatchApex'
		    AND ApexClass.Name = 'RecurringMeetingsBatch'
		];
		
		System.assertEquals(1, executedScheduledJobs, 'The job should be scheduled.');
		System.assertEquals(1, executedBatchJobs, 'The batch job should be executed.');
	}
}
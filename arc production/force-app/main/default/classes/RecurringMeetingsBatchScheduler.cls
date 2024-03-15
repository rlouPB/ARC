global class RecurringMeetingsBatchScheduler implements Schedulable
{
    public static String jobName = 'RecurringMeetingsBatchScheduler';
	public static String scheduleWeekly = '0 0 6 ? * SAT';
	global void execute(SchedulableContext SC)
	{
    	RecurringMeetingsBatch batchable = new RecurringMeetingsBatch();
    	Database.executebatch(batchable);
    }

    public static String scheduleWeekly()
    {
    	String jobId = System.schedule(jobName, scheduleWeekly,
    		new RecurringMeetingsBatchScheduler());
		return jobId;
    }
}
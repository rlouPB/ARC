global class SystemSchedulingBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	public static Integer batchSize = 1;

	//public static String standardScheduleCRONString = '0 0 5 * * ?'; //daily at 5 AM
	public static String everyHourCRONString = '0 20 * * * ?'; //20 minutes past the hour
	public static SystemSchedulingBatch batchInstance = new SystemSchedulingBatch();

	public SystemSchedulingBatch() {
	}

	global void execute(System.SchedulableContext sc) {
		SystemSchedulingBatch.runBatch();
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		String query = SystemScheduling.scheduledItemDefQueryString;

		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext bc, List<Scheduled_Item_Definition__mdt> scope) {
		SystemScheduling.runScheduledItemDefs(scope);
	}

	global void finish(Database.BatchableContext bc) {
		// Query for status of Apex Job
		// Record any uncaught exceptions in Process Logs
		// Commit any Process Logs
		AsyncApexJob currentJob = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE ID = :bc.getJobID()];

		if (currentJob.NumberofErrors > 0) {
			ProcessLogging.addProcessLog('SystemSchedulingBatch', 'finish method', 'SystemSchedulingBatch finished with ' + currentJob.NumberOfErrors + ' unhandled errors. ' + currentJob.JobItemsProcessed + ' items processed out of ' + currentJob.TotalJobItems + ' total items. Job ID: ' + currentJob.ID);
		}
		ProcessLogging.commitProcessLogs();
	}

	public static String runBatch() {
		// Query for existing batch instance of SystemSchedulingBatch
		// if not currently executing
		// execute batchInstance using SystemSchedulingBatch.batchSize
		List<AsyncApexJob> currentJobs = [SELECT ID FROM AsyncApexJob WHERE (Status = 'Processing' OR Status = 'Preparing') AND MethodName = 'SystemSchedulingBatch'];
		String resultString = 'already running';
		if (currentJobs.size() == 0) {
			resultString = Database.executeBatch(batchInstance, batchSize);
		}
		return resultString;
	}

	global static String scheduleBatch() {
		// Query for existing scheduled instance of SystemSchedulingBatch
		// if not currently scheduled
		// schedule batch to run based on SystemSchedulingBatch.standardScheduleCRONString;
		List<CronTrigger> scheduledJobs = [SELECT ID FROM CronTrigger WHERE CronJobDetail.Name = 'SystemScheduling Batch'];
		String resultString = 'already scheduled';
		if (scheduledJobs.size() == 0) {
			//changed to every hour 210216 JN
			resultString = System.schedule('SystemScheduling Batch', everyHourCRONString, new SystemSchedulingBatch());
		}
		return resultString;
	}
}
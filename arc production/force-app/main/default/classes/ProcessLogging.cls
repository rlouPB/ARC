public class ProcessLogging {
	/*
			Description: Basic utility class to centralize and simplify logging from within Apex.

			To Use, these are the typical cases:
				* Bulkified 2-step (Useful for intensive troubleshooting or large data operations where a process running on a data set may partially succeed, but has some errors)
					1. Call ProcessLogging.addProcessLog(String processName, String stackTrace, String message);
						This will create a Process Log, does not insert into SF database, and adds it to a running list of logs to be created
					2. Call ProcessLogging.commitProcessLogs();
						This performs the final DML on the list of Process Logs to create

				* Quick 1-step (Easiest way to go for 95% of cases)
					Call ProcessLogging.quickProcessLog(String processName, String stackTrace, String message);

				* Quick Future 1-step (Runs Asynchronously in @future, if you happen to need to run in a different context)
					Call ProcessLogging.quickProcessLogFuture(String processName, String stackTrace, String message);

			Note: If you want to use Process Logs *temporarily* as part of a troubleshooting process, you can set the boolean variable emailCurrentUserOnly to TRUE.
					DO NOT leave it this way permanently, since this will result in exceptions being missed.
	*/

	//set this to true if you only want emails to send to the current user as opposed to the "Admins" Public Group
	public static Boolean emailCurrentUserOnly = false;

	static List<Process_Log__c> processLogs = new List<Process_Log__c>();

	public ProcessLogging() {
	}

	public static void addProcessLog(String processName, String stackTrace, String message) {
		Process_Log__c newLog = new Process_Log__c(
			Process__c = processName,
			Stack_Trace__c = stackTrace,
			Detail__c = message,
			Email_Current_User_Only__c = emailCurrentUserOnly
		);

		processLogs.add(newLog);
	}

	public static void commitProcessLogs() {
		insert processLogs;
		processLogs = new List<Process_Log__c>();
	}

	public static void quickProcessLog(String processName, String stackTrace, String message) {
		addProcessLog(processName, stackTrace, message);
		commitProcessLogs();
	}

	@future
	public static void quickProcessLogFuture(String processName, String stackTrace, String message) {
		quickProcessLog(processName, stackTrace, message);
	}
}
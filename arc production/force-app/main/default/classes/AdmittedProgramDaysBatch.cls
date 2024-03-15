global class AdmittedProgramDaysBatch implements Schedulable, Database.Batchable<SObject>, Database.Stateful
{
    public static String everyMorningCRONString = '0 0 6 * * ?'; //daily at 6 AM
    public static Date earliestCalculatedDate = System.today();
    public static Integer batchSize = 1;
    public static String admissionQueryString = 'SELECT Id'
                                    + ' FROM Admission__c'
                                    + ' WHERE Stage__c IN (\'Admitted\', \'Discharged\')'
                                        + ' AND Admitted_Date_Set__c != null'
                                        + ' AND (Last_Calculated_Program_Days__c <= :earliestCalculatedDate OR Last_Calculated_Program_Days__c = null)'
                                    + ' ORDER BY Admitted_Date_Set__c ASC NULLS LAST';
    
    global AdmittedProgramDaysBatch() {}

    global void execute(SchedulableContext SC) 
	{		
		runBatch();
	}

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(admissionQueryString);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        Savepoint sp = Database.setSavePoint();
        try 
        {
            Set<Id> admIds = new Map<Id, sObject>(scope).keySet();

            AdmittedProgramDays.deleteExistingProgDays = true;
            //AdmittedProgramDays apd = new AdmittedProgramDays(admIds);
            //apd.commitChanges();
            AdmittedProgramDays.syncAdmittedProgramDays(admIds);
        } catch (Exception e)
        {   Database.rollback(sp);  
            //ProcessLogging.addProcessLog('AdmittedProgramDaysBatch.execute', e.getStackTraceString(), e.getmessage());  

        }
    }

    global void finish(Database.BatchableContext bc)
    {
        AsyncApexJob currentJob = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
									FROM AsyncApexJob
									WHERE ID = :bc.getJobID()];

		if (currentJob.NumberofErrors > 0) 
        {
			ProcessLogging.addProcessLog('AdmittedProgramDaysBatch.finish', 'finish method', 'AdmittedProgramDaysBatch finished with ' + currentJob.NumberOfErrors + ' unhandled errors. ' +
											currentJob.JobItemsProcessed + ' items processed out of ' + currentJob.TotalJobItems + ' total items. Job ID: ' + currentJob.ID);
		}
        ProcessLogging.commitProcessLogs();
    }
    
    public static Id runBatch()
    {
        return Database.executeBatch(new AdmittedProgramDaysBatch(), AdmittedProgramDaysBatch.batchSize);
    }

    public static Id scheduleDaily()
    {
        return System.schedule('Admitted Program Days Batch', everyMorningCRONString, new AdmittedProgramDaysBatch());
    }
}
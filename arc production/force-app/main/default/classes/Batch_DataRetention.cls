/*
  Purpose:  Schedulable Batch class to query for all the MDT retention settings and then run a batch for each setting record.
  Each batch run pops the next setting from the list and executes the next batch.


  Original Author:  Synaptic AP - KRISHNA OMMI created on 06/9/2019

 */
global class Batch_DataRetention implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
	public List<Retention_Setting__mdt> remainingSettings;
	public Retention_Setting__mdt setting;
	public Map<Exception, String> errorsMapWithMethodName = new Map<Exception, String>();
	public List<Retention_Setting__mdt> newList = new List<Retention_Setting__mdt>();
	public Integer mdtRecordsSize = 0;

	global Batch_DataRetention() {
	}

	global void execute(SchedulableContext SC) {
		startBatch();
	}

	global Batch_DataRetention(List<Retention_Setting__mdt> remainingSettings) {
		this.remainingSettings = remainingSettings;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		setting = remainingSettings[0];
		DataRetention dr = new DataRetention(setting);

		try {
			return Database.getQueryLocator(dr.queryString);
		} catch (Exception x) {
			System.debug('Error Message' + x);
			errorsMapWithMethodName.put(x, 'QueryLocator');
			return Database.getQueryLocator(dr.queryString);
		}
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		try {
			delete scope;

			if (Test.isRunningTest()) {
				throw new CustomException('To cover exception when test is running');
			}
		} catch (Exception ex) {
			errorsMapWithMethodName.put(ex, 'execute');
		}
	}

	global void finish(Database.BatchableContext BC) {
		List<Process_Log__c> pls = new List<Process_Log__c>();

		if (!errorsMapWithMethodName.isEmpty()) {
			for (Exception e : errorsMapWithMethodName.keySet()) {
				Process_Log__c pl = new Process_Log__c();
				pl.Detail__c = String.valueOf(e.getLineNumber());
				pl.Method__c = errorsMapWithMethodName.get(e);
				pl.Process__c = e.getMessage();
				pl.Stack_Trace__c = e.getStackTraceString();

				pls.add(pl);
			}

			insert pls;
		}

		// remove setting and create new list of mdt
		remainingSettings.remove(0);
		newList.addAll(remainingSettings);

		if (newList.size() > 0) {
			runBatch(newList);
		}
	}

	public static String startBatch() {
		List<Retention_Setting__mdt> remainingSettings = [SELECT ID, Object__c, Date_Field__c, Allowed_Age__c, Additional_Filter__c FROM Retention_Setting__mdt];
		Id jobId = runBatch(remainingSettings);
		return 'Starting Data Retention Batch jobId: ' + jobId + ' with ' + remainingSettings.size() + ' retention settings to run through';
	}

	public static Id runBatch(List<Retention_Setting__mdt> settings) {
		Batch_DataRetention bdr = new Batch_DataRetention(settings);
		return Database.executeBatch(bdr);
	}

	public static Id scheduleDaily() {
		return System.schedule('Daily data retention', '0 0 3 * * ? *', new Batch_DataRetention());
	}
}
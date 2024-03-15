global class ScriptSureBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator('SELECT Id, External_Patient_Id__c FROM Account WHERE External_Patient_Id__c != null AND Current_Admission__r.Stage__c = \'Admitted\'');
	}

	global void execute(Database.BatchableContext bc, List<Account> scope) {
		if (scope.size() > 1) {
			throw new CustomException('We can only process prescriptions one patient at a time. Update the batch size to 1.');
		}

		if (scope.size() == 1) {
			Account account = scope.get(0);
			String sessionToken = ScriptSure_ServiceUtil.authenticate(true);
			ScriptSure_ServiceUtil.getPrescriptions(account.External_Patient_Id__c, account.Id, sessionToken, true);
		}
	}

	global void finish(Database.BatchableContext bc) {
		ScriptSureBatchDeleteProcessSets sspsToDeleteBatch = new ScriptSureBatchDeleteProcessSets();
		Id sspsToDeleteBatchProcessId = Database.executeBatch(sspsToDeleteBatch, 1);
	}
}
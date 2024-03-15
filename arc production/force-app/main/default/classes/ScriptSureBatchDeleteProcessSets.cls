global class ScriptSureBatchDeleteProcessSets implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	List<ScriptSure_Process_Sets__c> sspsToDelete = new List<ScriptSure_Process_Sets__c>();

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator('SELECT Id, Name, Process_Set_ID__c FROM ScriptSure_Process_Sets__c');
	}

	global void execute(Database.BatchableContext bc, List<ScriptSure_Process_Sets__c> scope) {
		if (scope.size() > 1) {
			throw new CustomException('We can only process one at a time. Update the batch size to 1.');
		}

		if (scope.size() == 1) {
			ScriptSure_Process_Sets__c ssps = scope.get(0);
			String sessionToken = ScriptSure_ServiceUtil.authenticate(true);
			ScriptSure_ServiceUtil.deleteScriptSureProcessSetFromBatch(ssps.Process_Set_ID__c, sessionToken);
			sspsToDelete.add(ssps);
		}
	}

	global void finish(Database.BatchableContext bc) {
		if (!sspsToDelete.isEmpty()) {
			delete sspsToDelete;
		}
	}
}
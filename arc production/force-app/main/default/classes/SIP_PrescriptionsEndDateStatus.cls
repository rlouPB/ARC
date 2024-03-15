public with sharing class SIP_PrescriptionsEndDateStatus implements SystemScheduling.ScheduledItemProcessor {
	public static void process(List<Scheduled_Item_Definition__mdt> scheduledItemDefs) {
		Map<String, Scheduled_Item_Run__c> scheduledRunByDefinitionID = new Map<String, Scheduled_Item_Run__c>();
		try {
			List<String> scheduledDefIDs = new List<String>();
			for (Scheduled_Item_Definition__mdt currentDef : scheduledItemDefs) {
				scheduledDefIDs.add(currentDef.ID);
			}

			List<Scheduled_Item_Run__c> scheduledRuns = [SELECT Next_Run_Datetime__c, Retry_Count__c, Retry_Detail__c, Scheduled_Item_Def__c, Scheduled_Item_Def_Status__c FROM Scheduled_Item_Run__c WHERE Scheduled_Item_Def__c IN :scheduledDefIDs];
			for (Scheduled_Item_Run__c currentRun : scheduledRuns) {
				scheduledRunByDefinitionID.put(currentRun.Scheduled_Item_Def__c, currentRun);
			}

			for (Scheduled_Item_Definition__mdt currentDef : scheduledItemDefs) {
				Scheduled_Item_Run__c relatedRun = scheduledRunByDefinitionID.get(currentDef.ID);
				if (null != relatedRun) {
					try {
						if (relatedRun.Next_Run_Datetime__c <= DateTime.now() && 'Active' == relatedRun.Scheduled_Item_Def_Status__c) {
							List<Prescription__c> prescriptionsToUpdate = [SELECT Id, End_Date__c, Status__c FROM Prescription__c WHERE End_Date__c < :Date.today() AND Inactive_Datetime__c = NULL];
							for (Prescription__c prescription : prescriptionsToUpdate) {
								prescription.Inactive_Datetime__c = System.now();
								prescription.Status__c = 'Discontinued';
							}
							update prescriptionsToUpdate;

							// SIP info for when to run next.
							Date tomorrow = Date.today().addDays(1);
							relatedRun.Next_Run_Datetime__c = DateTime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day(), 0, 0, 0);
						}
					} catch (Exception ex) {
						relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
						relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);

						ProcessLogging.addProcessLog('SIP_PrescriptionsEndDateStatus', ex.getStackTraceString(), ex.getMessage());
					}
				}
			}

			upsert scheduledRunByDefinitionID.values();
		} catch (Exception ex) {
			for (Scheduled_Item_Run__c relatedRun : scheduledRunByDefinitionID.values()) {
				relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
				relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
			}
			ProcessLogging.addProcessLog('SIP_PrescriptionsEndDateStatus', ex.getStackTraceString(), ex.getMessage());
		}
	}
}
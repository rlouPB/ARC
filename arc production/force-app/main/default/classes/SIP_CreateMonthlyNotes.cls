public class SIP_CreateMonthlyNotes implements SystemScheduling.ScheduledItemProcessor {
	public SIP_CreateMonthlyNotes() {
	}

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
				if (relatedRun == null) {
					relatedRun = new Scheduled_Item_Run__c(Name = currentDef.MasterLabel, Scheduled_Item_Def__c = currentDef.ID, Scheduled_Item_Def_Status__c = 'Inactive', Retry_Count__c = 0);

					scheduledRunByDefinitionID.put(currentDef.ID, relatedRun);
				} else {
					if (relatedRun.Scheduled_Item_Def_Status__c == 'Active') {
						relatedRun.Scheduled_Item_Def_Status__c = 'Inactive';
					}

					if (relatedRun.Next_Run_Datetime__c == null || relatedRun.Next_Run_Datetime__c < Date.today()) {
						relatedRun.Next_Run_Datetime__c = null;
					}
				}

				try {
				} catch (Exception ex) {
					relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
					relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);

					ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
				}
			}

			upsert scheduledRunByDefinitionID.values();
		} catch (Exception ex) {
			for (Scheduled_Item_Run__c relatedRun : scheduledRunByDefinitionID.values()) {
				relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
				relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
			}

			ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
		}
	}
}
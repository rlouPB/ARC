public class SIP_AutoGroupMemberships implements SystemScheduling.ScheduledItemProcessor {
	// public SIP_AutoGroupMemberships() {}

	public static void process(List<Scheduled_Item_Definition__mdt> scheduledItemDefs) {
		Map<String, Scheduled_Item_Run__c> scheduledRunByDefinitionID = new Map<String, Scheduled_Item_Run__c>();
		try {
			Set<Id> scheduledDefIds = new Map<Id, Scheduled_Item_Definition__mdt>(scheduledItemDefs).keySet();

			List<Scheduled_Item_Run__c> scheduledRuns = SystemScheduling.queryScheduledItemRuns(scheduledDefIds);
			for (Scheduled_Item_Run__c currentRun : scheduledRuns) {
				scheduledRunByDefinitionID.put(currentRun.Scheduled_Item_Def__c, currentRun);
			}

			for (Scheduled_Item_Definition__mdt currentDef : scheduledItemDefs) {
				Scheduled_Item_Run__c relatedRun = scheduledRunByDefinitionID.get(currentDef.ID);
				if (relatedRun == null) {
					relatedRun = new Scheduled_Item_Run__c(Name = currentDef.MasterLabel, Scheduled_Item_Def__c = currentDef.ID, Scheduled_Item_Def_Status__c = 'Inactive', Retry_Count__c = 0);

					scheduledRunByDefinitionID.put(currentDef.ID, relatedRun);
				} else if (relatedRun.Scheduled_Item_Def_Status__c == 'Inactive' || relatedRun.Next_Run_Datetime__c > System.now()) {
					//skip run
				} else {
					if (relatedRun.Scheduled_Item_Def_Status__c == 'Active') {
						relatedRun.Scheduled_Item_Def_Status__c = 'Inactive';
					}

					if (relatedRun.Next_Run_Datetime__c == null || relatedRun.Next_Run_Datetime__c < System.now()) {
						relatedRun.Next_Run_Datetime__c = null;
					}
				}

				Savepoint sp = Database.setSavepoint();
				try {
					AutoGroupMemberships.syncToGroupMemberships();

					//On success, clear out the retry fields
					relatedRun.Retry_Count__c = 0;
					relatedRun.Retry_Detail__c = null;
					relatedRun.Scheduled_Item_Def_Status__c = 'Active';
				} catch (Exception ex) {
					handleDefCatch(sp, relatedRun, ex);
				}
			}

			upsert scheduledRunByDefinitionID.values();
		} catch (Exception ex) {
			handleFinalCatch(scheduledRunByDefinitionID.values(), ex);
		}
	}

	@TestVisible
	static void handleDefCatch(Savepoint sp, Scheduled_Item_Run__c relatedRun, Exception ex) {
		Database.rollback(sp);
		//relatedRun =
		incrementRetry(relatedRun, ex);
		ProcessLogging.addProcessLog('SystemScheduling.SIP_AutoGroupMemberships.defCatch', ex.getStackTraceString(), ex.getMessage());
	}

	@TestVisible
	static void handleFinalCatch(List<Scheduled_Item_Run__c> scheduledRuns, Exception ex) {
		for (Scheduled_Item_Run__c relatedRun : scheduledRuns) {
			incrementRetry(relatedRun, ex);
		}
		upsert scheduledRuns;
		ProcessLogging.addProcessLog('SystemScheduling.SIP_AutoGroupMemberships.finalCatch', ex.getStackTraceString(), ex.getMessage());
	}

	static void incrementRetry(Scheduled_Item_Run__c relatedRun, Exception ex) {
		relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
		relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
	}
}
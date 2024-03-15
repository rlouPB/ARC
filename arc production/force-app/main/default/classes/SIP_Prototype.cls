public class SIP_Prototype implements SystemScheduling.ScheduledItemProcessor {
	//Probably don't need a constructor
	// public SIP_Prototype() {}

	public static void process(List<Scheduled_Item_Definition__mdt> scheduledItemDefs) {
		Map<String, Scheduled_Item_Run__c> scheduledRunByDefinitionID = new Map<String, Scheduled_Item_Run__c>();
		try {
			Set<Id> scheduledDefIds = new Map<Id, Scheduled_Item_Definition__mdt>(scheduledItemDefs).keySet();

			// for (Scheduled_Item_Definition__mdt currentDef: scheduledItemDefs)
			// {
			//     scheduledDefIDs.add(currentDef.ID);
			// }

			List<Scheduled_Item_Run__c> scheduledRuns = SystemScheduling.queryScheduledItemRuns(scheduledDefIds);

			// [SELECT Next_Run_Datetime__c, Retry_Count__c, Retry_Detail__c, Scheduled_Item_Def__c,
			//                                                     Scheduled_Item_Def_Status__c
			//                                                 FROM Scheduled_Item_Run__c
			//                                                 WHERE Scheduled_Item_Def__c IN: scheduledDefIDs];

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

					//if Next_Run_Datetime__c is null on the Run record,
					if (relatedRun.Next_Run_Datetime__c == null || relatedRun.Next_Run_Datetime__c < System.now()) {
						relatedRun.Next_Run_Datetime__c = null;
					}
				}

				try {
					// main processing here, nothing for Prototype
					//MainProcessorClass.runMyJob();

					//On success, clear out the retry fields
					relatedRun.Retry_Count__c = 0;
					relatedRun.Retry_Detail__c = null;
				} catch (Exception ex) {
					relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
					relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
					ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
				}
				relatedRun.Scheduled_Item_Def_Status__c = 'Active';
				// Date tomorrow = Date.today().addDays(1);
				// relatedRun.Next_Run_Datetime__c = DateTime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day(), 0, 0, 0);
				// relatedRun.Next_Run_Datetime__c = null; //run every time
			}

			upsert scheduledRunByDefinitionID.values();
		} catch (Exception ex) {
			for (Scheduled_Item_Run__c relatedRun : scheduledRunByDefinitionID.values()) {
				relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
				relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
			}

			upsert scheduledRunByDefinitionID.values();
			ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
		}
	}
}
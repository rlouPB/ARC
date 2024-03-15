public class SIP_CreateGroupNotes implements SystemScheduling.ScheduledItemProcessor {
	public SIP_CreateGroupNotes() {
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
					List<Meeting__c> meetingsNeedGroupNote = [
						SELECT Name, (SELECT Id FROM Group_Notes__r)
						FROM Meeting__c
						// removed Staff Group, will likely add it back to query in future JN 210212
						// WHERE (Meeting_Focus__c = 'Patient Group'
						// 	OR Meeting_Focus__c = 'Staff Group')
						WHERE
							Meeting_Focus__c = 'Patient Group'
							// AND ((Start_Date_Time__c >= :Date.today().addDays(-7)
							//         AND Start_Date_Time__c <= :Date.today())
							//     OR (All_Day_Date__c >= :Date.today().addDays(-7)
							//         AND All_Day_Date__c <= :Date.today()))
							AND (Start_Date_Time__c = LAST_N_DAYS:7
							OR All_Day_Date__c = LAST_N_DAYS:7)
					];

					List<Group_Note__c> groupNotesToInsert = new List<Group_Note__c>();
					for (Meeting__c currentMeeting : meetingsNeedGroupNote) {
						if (currentMeeting.Group_Notes__r.isEmpty()) {
							Group_Note__c note = new Group_Note__c(Name = currentMeeting.Name + ' Group Note', Meeting__c = currentMeeting.Id);
							groupNotesToInsert.add(note);
						}
					}

					insert groupNotesToInsert;

					relatedRun.Scheduled_Item_Def_Status__c = 'Active';
					Date tomorrow = Date.today().addDays(1);
					relatedRun.Next_Run_Datetime__c = DateTime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day(), 0, 0, 0);
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
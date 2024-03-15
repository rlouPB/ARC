public class SIP_AccessPassExpirations implements SystemScheduling.ScheduledItemProcessor {
	public SIP_AccessPassExpirations() {
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
					Map<Id, Account> accountsMap;
					Map<Id, Case> casesMap;
					Map<Id, Admission__c> admissionsMap;
					Map<Id, Goal__c> goalsMap;
					Map<Id, Ego__c> egosMap;

					Set<Id> relatedAccountIds = new Set<Id>();
					List<Access_Pass__c> expiredAccessPasses = [SELECT Patient__c, Requesting_User__c FROM Access_Pass__c WHERE Access_End_Date__c < :Date.today() AND Access_Removed__c = FALSE];
					for (Access_Pass__c accessPass : expiredAccessPasses) {
						relatedAccountIds.add(accessPass.Patient__c);
					}

					accountsMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Admission_Files__r), (SELECT Id FROM Cases), (SELECT Id FROM Patient_Notes__r) FROM Account WHERE Id IN :relatedAccountIds]);

					Set<Id> relatedCases = new Set<Id>();
					Set<Id> relatedAdmissions = new Set<Id>();
					for (Account acc : accountsMap.values()) {
						for (Case currentCase : acc.Cases) {
							relatedCases.add(currentCase.Id);
						}
						for (Admission__c admission : acc.Admission_Files__r) {
							relatedAdmissions.add(admission.Id);
						}
					}

					casesMap = new Map<Id, Case>([SELECT Id, (SELECT Id FROM Interventions__r), (SELECT Id FROM Goals_Draft_Treatment_Plan__r) FROM Case WHERE Id IN :relatedCases]);

					admissionsMap = new Map<Id, Admission__c>([SELECT Id, (SELECT Id FROM EGOs__r), (SELECT Id FROM Diagnoses__r) FROM Admission__c WHERE Id IN :relatedAdmissions]);

					Set<Id> relatedGoals = new Set<Id>();
					for (Case currentCase : casesMap.values()) {
						for (Goal__c goal : currentCase.Goals_Draft_Treatment_Plan__r) {
							relatedGoals.add(goal.Id);
						}
					}

					goalsMap = new Map<Id, Goal__c>([SELECT Id, (SELECT Id FROM Objectives__r) FROM Goal__c WHERE Id IN :relatedGoals]);

					Set<Id> relatedEGOs = new Set<Id>();
					for (Admission__c admission : admissionsMap.values()) {
						for (Ego__c ego : admission.EGOs__r) {
							relatedEGOs.add(ego.Id);
						}
					}

					egosMap = new Map<Id, Ego__c>([SELECT Id, (SELECT Id FROM Ego_Ratings__r) FROM EGO__c WHERE Id IN :relatedEGOs]);

					for (Access_Pass__c accessPass : expiredAccessPasses) {
						Account patient = accountsMap.get(accessPass.Patient__c);

						List<Id> allRecordIds = new List<Id>{ patient.Id };
						// Get related Admission Files and related objects Ids for the chosen Patient
						for (Admission__c admission : patient.Admission_Files__r) {
							for (EGO__c ego : admission.EGOs__r) {
								allRecordIds.add(ego.Id);
								for (EGO_Rating__c egoRating : ego.EGO_Ratings__r) {
									allRecordIds.add(egoRating.Id);
								}
							}
							for (Diagnosis__c diagnosis : admission.Diagnoses__r) {
								allRecordIds.add(diagnosis.Id);
							}
						}

						// Get related Cases and related objects Ids for chosen Patient
						for (Case currentCase : patient.Cases) {
							allRecordIds.add(currentCase.Id);
							for (Intervention__c intervention : currentCase.Interventions__r) {
								allRecordIds.add(intervention.Id);
							}
							for (Goal__c goal : currentCase.Goals_Draft_Treatment_Plan__r) {
								allRecordIds.add(goal.Id);
								for (Objective__c objective : goal.Objectives__r) {
									allRecordIds.add(objective.Id);
								}
							}
						}

						// Get related Patient Notes Ids for chosen Patient
						for (Patient_Note__c pNote : patient.Patient_Notes__r) {
							allRecordIds.add(pNote.Id);
						}

						Database.delete([SELECT Id FROM Snapshot__share WHERE UserOrGroupId = :accessPass.Requesting_User__c AND RowCause = 'Manual']);
						String result = SharingRecord_Utils.deleteSharingRecords(allRecordIds, new List<String>{ accessPass.Requesting_User__c });
						accessPass.Access_Removed__c = true;
					}

					update expiredAccessPasses;

					// SIP info for when to run next.
					relatedRun.Scheduled_Item_Def_Status__c = 'Active';
					Date tomorrow = Date.today().addDays(1);
					relatedRun.Next_Run_Datetime__c = DateTime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day(), 5, 0, 0);
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
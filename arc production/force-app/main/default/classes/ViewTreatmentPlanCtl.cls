/**
 * A controller for ViewTreatmentPlan Component.
 */
public without sharing class ViewTreatmentPlanCtl {
	public class latestFinalized {
		@AuraEnabled
		public EGO__c ego;

		@AuraEnabled
		public Case treatmentplan;

		public latestFinalized() {
			this.ego = new EGO__c();
			this.treatmentplan = new Case();
		}
	}
	@AuraEnabled
	public static latestFinalized getLatestFinalized(String caseId) {
		latestFinalized result = new latestFinalized();
		//get latest 'Finalized' TP related to this Case or Admission

		//get latest 'Finalized' EGO related to this Case or Admission
		//Admission__c

		Case tp = [SELECT Id, AccountId, Admission__c, Status, Account.Current_Case__c FROM Case WHERE Id = :caseId LIMIT 1];
		// && tp.Account.Current_Case__r != null
		// && tp.Account.Current_Case__r.AccountId != null )
		if (tp.AccountId != null) {
			// for( Case ftp : [SELECT Finalized_Date_Time__c, Finalized_By__c
			//                 FROM Case
			//                 WHERE AccountId =:tp.Account.Current_Case__r.AccountId
			//                         AND Status = 'Finalized'
			//                 ORDER BY Finalized_Date_Time__c DESC
			//                 LIMIT 1] )
			for (Case ftp : [SELECT Id, Admission__c, Admission__r.Medical_Care_Plan__c, Finalized_Date_Time__c, Finalized_By__c, Finalized_By_User__c, Finalized_By_Professional_Name__c FROM Case WHERE Status = 'Finalized' AND Admission__c = :tp.Admission__c ORDER BY Finalized_Date_Time__c DESC LIMIT 1]) {
				result.treatmentplan = ftp;
			}
			// for( EGO__c ego : [SELECT Finalized_Date_Time__c, Finalized_By__c
			//                 FROM EGO__c
			//                 WHERE Current_Treatment_Plan__r.AccountId =:tp.Account.Current_Case__r.AccountId
			//                     AND Status__c = 'Finalized'
			//                 ORDER BY Finalized_Date_Time__c DESC
			//                 LIMIT 1] )
			for (EGO__c ego : [SELECT Id, Admission__c, Finalized_Date_Time__c, Finalized_By__c, Finalized_By_Professional_Name__c, Finalized_By_User__c FROM EGO__c WHERE Status__c = 'Finalized' AND Admission__c = :tp.Admission__c ORDER BY Finalized_Date_Time__c DESC LIMIT 1]) {
				result.ego = ego;
			}
		}
		return result;
	}

	/**
	 * Get Current Treatment Plan.  If this is a Draft Treatment Plan, it will determine to show Save as Complete button.
	 */
	@AuraEnabled
	public static TreatmentPlan getTreatmentPlan(String caseId) {
		TreatmentPlan tPlan = TreatmentPlan.getTreatmentPlan(caseId);
		return tPlan;
	}

	@AuraEnabled
	public static string createDraftTreatmentPlanTeamEdit(String currentTreatmentPlanId) {
		TreatmentPlan tPlan = TreatmentPlan.getTreatmentPlan(currentTreatmentPlanId);
		tPlan.ego = null;
		tPlan.domains = TreatmentPlan.buildDomains(false, true, null, currentTreatmentPlanId);
		return TreatmentPlan.finalizeEGOToDraftTreatmentPlan(tPlan);
	}

	/**
	 * Save Draft Treatment Plan.  This is different than EGO as this is saving draft Treatment Plan without saving any new EGO.
	 */
	@AuraEnabled
	public static String saveTreatmentPlan(String draftTreatmentPlanString) {
		String retval = 'SUCCESS';
		Map<String, String> errorMap = new Map<String, String>();
		System.SavePoint sp = Database.setSavepoint();
		try {
			// As of January 17, 2020, it is odd that auto-serialization suddenly worked.  Reverted back to TreatmentPlan without serialization.
			TreatmentPlan draftTreatmentPlan = (TreatmentPlan) JSON.deserialize(draftTreatmentPlanString, TreatmentPlan.class);
			update draftTreatmentPlan.currentTreatmentPlan;
			//EGO__c ego=[SELECT Id,Current_Treatment_Plan__c FROM EGO__c WHERE Id=:draftTreatmentPlan.ego.Id];
			List<Goal> allGoalList = new List<Goal>();
			List<Goal__c> upsertGoalList = new List<Goal__c>();
			List<Objective__c> upsertObjectiveList = new List<Objective__c>();
			for (Domain domainObj : draftTreatmentPlan.domains) {
				for (Goal goal : domainObj.goals) {
					if (String.isBlank(goal.goalObj.Id)) {
						goal.goalObj.Domain_Metadata_ID__c = domainObj.domainObj.Id;
						goal.goalObj.Domain_Name__c = domainObj.domainObj.Label__c;
						goal.goalObj.Domain_Number__c = domainObj.domainObj.Domain_Number__c;
						goal.goalObj.Draft_Treatment_Plan__c = draftTreatmentPlan.currentTreatmentPlan.Id;
						goal.goalObj.Treatment_Plan__c = draftTreatmentPlan.currentTreatmentPlan.Id;
						//goal.goalObj.Treatment_Plan__c=ego.Current_Treatment_Plan__c;
					}
					if (String.isBlank(goal.goalObj.Continued_From_Goal__c)) {
						goal.goalObj.Date_Added__c = system.today();
					}
					allGoalList.add(goal);
					upsertGoalList.add(goal.goalObj);
				}
			}
			if (upsertGoalList != null && !upsertGoalList.isEmpty()) {
				upsert upsertGoalList;
				integer totalGoals = allGoalList.size();
				for (integer index = 0; index < totalGoals; index++) {
					Goal__c goalObj = upsertGoalList.get(index);
					Goal goal = allGoalList.get(index);
					for (Objective objective : goal.objectives) {
						if (String.isBlank(objective.objectiveObj.Id)) {
							objective.objectiveObj.Goal__c = goalObj.Id;
						}
						if (String.isBlank(objective.objectiveObj.Continued_From_Objective__c)) {
							objective.objectiveObj.Date_Added__c = system.today();
						}
						upsertObjectiveList.add(objective.objectiveObj);
					}
				}
			}
			if (upsertObjectiveList != null && !upsertObjectiveList.isEmpty()) {
				upsert upsertObjectiveList;
			}
		} catch (Exception e) {
			Database.rollback(sp);
			errorMap.put(e.getMessage(), e.getStackTraceString());
		}
		if (!errorMap.isEmpty()) {
			retval = JSON.serialize(errorMap);
		}
		return retval;
	}

	/**
    * DEPRECATED - Save Draft Treatment Plan as Complete.  This is different than EGO as this is saving draft Treatment Plan without saving any new EGO.

    @AuraEnabled
    public static String saveTreatmentPlanAsComplete(String draftTreatmentPlanString){
        TreatmentPlan draftTreatmentPlan=(TreatmentPlan)JSON.deserialize(draftTreatmentPlanString, TreatmentPlan.class);
        draftTreatmentPlan.currentTreatmentPlan.Status='Completed';
        return saveTreatmentPlan(draftTreatmentPlanString);
    }*/

	/**
	 * Finalize Draft Treatment Plan.
	 *
	 * Unlink existing Goals from current treatment plan
	 * Update Current Treatment Plan Overall Goal from Draft Treatment Plan Overall Goal
	 * Update Draft Treatment Plan with Status = 'Finalized'
	 * Update Draft Treatment Plan's EGO date (for View Treatmeent Plan to see Last EGO Finalized)
	 * Link only Continue draft Goals to current Treatment Plan
	 */
	@AuraEnabled
	//public static String finalizeTreatmentPlan(TreatmentPlan draftTreatmentPlan){
	public static String finalizeTreatmentPlan(String draftTreatmentPlanString) {
		String retval = '{"status":"SUCCESS","draftTreatmentPlanId":"{DraftTreatmentPlanId}","currentTreatmentPlanId":"{CurrentTreatmentPlanId}"}';

		Map<String, String> errorMap = new Map<String, String>();
		System.SavePoint sp = Database.setSavepoint();
		try {
			TreatmentPlan draftTreatmentPlan = (TreatmentPlan) JSON.deserialize(draftTreatmentPlanString, TreatmentPlan.class);

			Id userId = Userinfo.getUserId();
			String userProfessionalName = [SELECT Professional_Name__c FROM User WHERE Id = :userId].Professional_Name__c;
			// List<Contact> staffContacts = [SELECT Professional_Name__c
			//                                 FROM Contact
			//                                 WHERE Staff_User__c = :userId
			//                                 ORDER BY CreatedDate DESC
			//                                 LIMIT 1];
			// if (!staffContacts.isEmpty())
			// {
			//     userProfessionalName = staffContacts[0].Professional_Name__c;
			// }

			draftTreatmentPlan.currentTreatmentPlan.Status = 'Finalized';
			draftTreatmentPlan.currentTreatmentPlan.Finalized_By_User__c = userId;
			draftTreatmentPlan.currentTreatmentPlan.Finalized_By__c = userProfessionalName;
			draftTreatmentPlan.currentTreatmentPlan.Finalized_By_Professional_Name__c = userProfessionalName;
			draftTreatmentPlan.currentTreatmentPlan.Finalized_Date_Time__c = system.now();
			update draftTreatmentPlan.currentTreatmentPlan;

			// //-----FOR DEBUG----
			// IF (userinfo.getUserName().contains('danny.robles')){
			//     integer goalCount = [select count() from Goal__c where Draft_Treatment_Plan__c != null and Draft_Treatment_Plan__c = :draftTreatmentPlan.currentTreatmentPlan.Id ];
			//     system.assert(false, 'Found: ' + goalCount);
			// }
			// //-----/FOR DEBUG----

			//Creating Snapshot
			TreatmentPlanSnapshot.process(new List<id>{ draftTreatmentPlan.currentTreatmentPlan.Id });

			Case currentTreatmentPlan;
			if (draftTreatmentPlan.ego == null) {
				currentTreatmentPlan = [SELECT Id, Goal__c, Status FROM Case WHERE Id = :draftTreatmentPlan.currentTreatmentPlan.Account.Current_Case__c];
			} else {
				currentTreatmentPlan = [SELECT Id, Goal__c, Status FROM Case WHERE Id = :draftTreatmentPlan.ego.Current_Treatment_Plan__c];
			}
			retval = retval.replace('{DraftTreatmentPlanId}', draftTreatmentPlan.currentTreatmentPlan.Id);
			retval = retval.replace('{CurrentTreatmentPlanId}', currentTreatmentPlan.Id);
			List<Goal__c> existingGoalList = [SELECT Id, Domain_Name__c, Domain_Number__c, Treatment_Plan__c, Met_Discontinued_Date__c FROM Goal__c WHERE Treatment_Plan__c = :currentTreatmentPlan.Id];
			for (Goal__c existingGoal : existingGoalList) {
				existingGoal.Treatment_Plan__c = null;
			}
			update existingGoalList;

			currentTreatmentPlan.Goal__c = draftTreatmentPlan.currentTreatmentPlan.Goal__c;
			currentTreatmentPlan.Status = 'Active';
			update currentTreatmentPlan;

			// String userProfessionalName = [SELECT Name
			//                                 FROM User
			//                                 WHERE Id = :Userinfo.getUserId()].Name;
			// List<Contact> staffContacts = [SELECT Professional_Name__c
			//                                 FROM Contact
			//                                 WHERE Staff_User__c = :Userinfo.getUserId()
			//                                 ORDER BY CreatedDate DESC
			//                                 LIMIT 1];
			// if (!staffContacts.isEmpty())
			// {
			//     userProfessionalName = staffContacts[0].Professional_Name__c;
			// }
			// draftTreatmentPlan.currentTreatmentPlan.Status='Finalized';
			// draftTreatmentPlan.currentTreatmentPlan.Finalized_By__c = userProfessionalName;
			// draftTreatmentPlan.currentTreatmentPlan.Finalized_Date_Time__c=system.now();
			// update draftTreatmentPlan.currentTreatmentPlan;

			if (draftTreatmentPlan.ego != null) {
				draftTreatmentPlan.ego.Date__c = system.today();
				update draftTreatmentPlan.ego;
			}
			List<Goal> allGoalList = new List<Goal>();
			List<Goal__c> upsertGoalList = new List<Goal__c>();
			List<Objective__c> upsertObjectiveList = new List<Objective__c>();
			Map<Id, String> metDiscontinuedGoalIdStatusMap = new Map<Id, String>();
			Map<Id, Goal__c> metDiscontinuedGoalId2GoalMap = new Map<Id, Goal__c>();
			Set<Id> removeMetDiscontinuedNewGoalIdSet = new Set<Id>();
			Map<Id, String> metDiscontinuedObjectiveIdStatusMap = new Map<Id, String>();
			Map<Id, Objective__c> metDiscontinuedObjectiveId2ObjectiveMap = new Map<Id, Objective__c>();
			Set<Id> removeMetDiscontinuedNewObjectiveIdSet = new Set<Id>();
			for (Domain domainObj : draftTreatmentPlan.domains) {
				for (Goal goal : domainObj.goals) {
					if (String.isNotBlank(goal.goalObj.Status__c)) {
						if (String.isBlank(goal.goalObj.Continued_From_Goal__c)) {
							goal.goalObj.Date_Added__c = system.today();
						}
						if (goal.goalObj.Status__c.equalsIgnoreCase('continue goal')) {
							if (String.isBlank(goal.goalObj.Id)) {
								goal.goalObj.Source__c = 'Patient';
								goal.goalObj.Domain_Metadata_ID__c = domainObj.domainObj.Id;
								goal.goalObj.Domain_Name__c = domainObj.domainObj.Label__c;
								goal.goalObj.Domain_Number__c = domainObj.domainObj.Domain_Number__c;
								goal.goalObj.Draft_Treatment_Plan__c = draftTreatmentPlan.currentTreatmentPlan.Id;
							}
							goal.goalObj.Treatment_Plan__c = currentTreatmentPlan.Id;
							allGoalList.add(goal);
							upsertGoalList.add(goal.goalObj);
						} else if (goal.goalObj.Status__c.containsIgnoreCase('met') || goal.goalObj.Status__c.containsIgnoreCase('discontinued')) {
							if (String.isNotBlank(goal.goalObj.Continued_From_Goal__c)) {
								metDiscontinuedGoalIdStatusMap.put(goal.goalObj.Continued_From_Goal__c, goal.goalObj.Status__c);
								metDiscontinuedGoalId2GoalMap.put(goal.goalObj.Continued_From_Goal__c, goal.goalObj);
								if (String.isNotBlank(goal.goalObj.Id)) {
									removeMetDiscontinuedNewGoalIdSet.add(goal.goalObj.Id);
								}
							}
						}
						for (Objective objective : goal.objectives) {
							if (String.isNotBlank(objective.objectiveObj.Status__c) && objective.objectiveObj.Status__c.equalsIgnoreCase('continue')) {
								if (String.isBlank(objective.objectiveObj.Continued_From_Objective__c)) {
									objective.objectiveObj.Date_Added__c = system.today();
								}
								if (String.isBlank(objective.objectiveObj.Id)) {
									objective.objectiveObj.Goal__c = goal.goalObj.Id;
								}
								upsertObjectiveList.add(objective.objectiveObj);
							} else if (objective.objectiveObj.Status__c.containsIgnoreCase('met') || objective.objectiveObj.Status__c.containsIgnoreCase('discontinued')) {
								if (String.isNotBlank(objective.objectiveObj.Continued_From_Objective__c) || draftTreatmentPlan.isFirstEgoOnCurrentTreatmentPlan) {
									metDiscontinuedObjectiveIdStatusMap.put(objective.objectiveObj.Continued_From_Objective__c, objective.objectiveObj.Status__c);
									metDiscontinuedObjectiveId2ObjectiveMap.put(objective.objectiveObj.Continued_From_Objective__c, objective.objectiveObj);

									if (String.isNotBlank(objective.objectiveObj.Id)) {
										removeMetDiscontinuedNewObjectiveIdSet.add(objective.objectiveObj.Id);
									}
								}
							}
						}
					} else {
						// System.debug('Goal ' + goal.goalObj.Id + ' label :' + goal.goalObj.Label__c + ' status (' + goal.goalObj.Status__c + ') must be "Coninue Goal".');
					}
				}
			}

			if (upsertGoalList != null && !upsertGoalList.isEmpty()) {
				upsert upsertGoalList;
			}
			/*
                integer totalGoals=allGoalList.size();
                for(integer index=0;index<totalGoals;index++){
                    Goal__c goalObj=upsertGoalList.get(index);
                    Goal goal=allGoalList.get(index);
                    for(Objective objective:goal.objectives)
                    {
                        if(String.isNotBlank(objective.objectiveObj.Status__c) && objective.objectiveObj.Status__c.containsIgnoreCase('continue')){
                            if(String.isBlank(objective.objectiveObj.Id))
                            {
                                objective.objectiveObj.Goal__c=goalObj.Id;
                            }
                            upsertObjectiveList.add(objective.objectiveObj);
                        }else if(objective.objectiveObj.Status__c.containsIgnoreCase('met') || objective.objectiveObj.Status__c.containsIgnoreCase('discontinued')){
                            if(String.isNotBlank(objective.objectiveObj.Continued_From_Objective__c)){
                                metDiscontinuedObjectiveIdStatusMap.put(objective.objectiveObj.Continued_From_Objective__c,objective.objectiveObj.Status__c);
                                if(String.isNotBlank(objective.objectiveObj.Id)){
                                    removeMetDiscontinuedNewObjectiveIdSet.add(objective.objectiveObj.Id);
                                }
                            }
                        }
                    }
                }
            }
*/
			if (upsertObjectiveList != null && !upsertObjectiveList.isEmpty()) {
				upsert upsertObjectiveList;
			}
			// Stamp and Discontinued this goal and associated objectives, stamp previous goal and associated objectives.
			if (!metDiscontinuedObjectiveIdStatusMap.isEmpty()) {
				Map<Id, String> goalIdStatusMap = new Map<Id, String>();
				List<Goal__c> continuedFromGoalList = [SELECT Id, Domain_Name__c, Domain_Number__c, Status__c, Met_Discontinued_Date__c FROM Goal__c WHERE Id = :metDiscontinuedGoalId2GoalMap.keySet()];
				for (Goal__c continuedFromGoal : continuedFromGoalList) {
					Goal__c newGoal = metDiscontinuedGoalId2GoalMap.get(continuedFromGoal.Id);
					continuedFromGoal.Met_Discontinued_Date__c = newGoal.Met_Discontinued_Date__c;
					continuedFromGoal.Status__c = newGoal.Status__c;
					continuedFromGoal.Team_Goal_Comments__c = newGoal.Team_Goal_Comments__c;
					continuedFromGoal.Treatment_Plan__c = null;
					goalIdStatusMap.put(continuedFromGoal.Id, continuedFromGoal.Status__c);
				}
				update continuedFromGoalList;
				Map<Id, Goal__c> continuedFromGoalIdMap = new Map<Id, Goal__c>(continuedFromGoalList);
				String goalStatus;
				List<Objective__c> metDiscontinuedObjectiveFromGoalList = [SELECT Id, Goal__c, Status__c, Met_Discontinued_Date__c FROM Objective__c WHERE Goal__c = :continuedFromGoalList];
				for (Objective__c metDiscontinuedObjectiveFromGoal : metDiscontinuedObjectiveFromGoalList) {
					Goal__c continuedFromGoal = continuedFromGoalIdMap.get(metDiscontinuedObjectiveFromGoal.Goal__c);
					metDiscontinuedObjectiveFromGoal.Met_Discontinued_Date__c = continuedFromGoal.Met_Discontinued_Date__c;
					goalStatus = continuedFromGoal.Status__c;
					//goalStatus=goalIdStatusMap.get(metDiscontinuedObjectiveFromGoal.Goal__c);
					if (goalStatus.containsIgnoreCase('met')) {
						metDiscontinuedObjectiveFromGoal.Status__c = 'Met';
					} else if (goalStatus.equalsIgnoreCase('continue goal')) {
						metDiscontinuedObjectiveFromGoal.Status__c = 'Continue';
					} else {
						metDiscontinuedObjectiveFromGoal.Status__c = 'Discontinued';
					}
				}
				update metDiscontinuedObjectiveFromGoalList;
			}
			// Remove all cloned objectives and goals that are met or discontinued.
			if (!removeMetDiscontinuedNewGoalIdSet.isEmpty()) {
				List<Goal__c> removeMetDiscontinuedNewGoalList = [SELECT Id, Domain_Name__c, Domain_Number__c, Met_Discontinued_Date__c FROM Goal__c WHERE Id = :removeMetDiscontinuedNewGoalIdSet];
				List<Objective__c> removeMetDiscontinuedNewObjectiveList = [SELECT Id FROM Objective__c WHERE Goal__c = :removeMetDiscontinuedNewGoalList];

				for (Goal__c g : removeMetDiscontinuedNewGoalList) {
					g.OwnerId = UserInfo.getUserId();
				}
				update removeMetDiscontinuedNewGoalList;

				for (Objective__c o : removeMetDiscontinuedNewObjectiveList) {
					o.OwnerId = UserInfo.getUserId();
				}
				update removeMetDiscontinuedNewObjectiveList;

				delete removeMetDiscontinuedNewObjectiveList;
				delete removeMetDiscontinuedNewGoalList;
			}
			// Stamp and Discontinued this objective, stamp previous objective.
			if (!metDiscontinuedObjectiveIdStatusMap.isEmpty()) {
				List<Objective__c> continuedFromObjectiveList = [SELECT Id, Status__c, Met_Discontinued_Date__c FROM Objective__c WHERE Id = :metDiscontinuedObjectiveIdStatusMap.keySet()];
				for (Objective__c continuedFromObjective : continuedFromObjectiveList) {
					continuedFromObjective.Met_Discontinued_Date__c = system.today();
					continuedFromObjective.Status__c = metDiscontinuedObjectiveIdStatusMap.get(continuedFromObjective.Id);
				}
				update continuedFromObjectiveList;
			}
			// Remove all continued objectives that are met or discontinued.
			if (!removeMetDiscontinuedNewObjectiveIdSet.isEmpty()) {
				List<Objective__c> removeMetDiscontinuedNewObjectiveList = [SELECT Id FROM Objective__c WHERE Id = :removeMetDiscontinuedNewObjectiveIdSet];
				for (Objective__c o : removeMetDiscontinuedNewObjectiveList) {
					o.OwnerId = UserInfo.getUserId();
				}
				update removeMetDiscontinuedNewObjectiveList;
				delete removeMetDiscontinuedNewObjectiveList;
			}
			ActionItem_Util.createInterventionChangeActionItems(new List<id>{ currentTreatmentPlan.Id });

			// //Creating Snapshot
			// TreatmentPlanSnapshot.process( new id[]{ draftTreatmentPlan.currentTreatmentPlan.Id } );
		} catch (Exception e) {
			Database.rollback(sp);
			errorMap.put(e.getMessage(), e.getStackTraceString());
		}
		if (!errorMap.isEmpty()) {
			retval = JSON.serialize(errorMap);
		}
		return retval;
	}
}
/**
TreatmentPlan is a case where a treatment is created after EGO assessment.

New EGO will have case associated, which is Account's Current_Case__c.

A Treatment Plan is considered Current if there is no EGO__c but a list of EGO__c.

A draft treatment plan is considered Draft if there is EGO__c but no list of EGO__c.  A draft treatment plan
MUST have a current plan associated with the EGO and thus EGO ratings.
 */
public with sharing class TreatmentPlan {
	//REFERENCE
	//6 months for default target date on Goals and Objectives
	public static Integer DEFAULT_TARGET_DATE_DURATION = 6;
	public static String egoBaseQueryString = 'SELECT Id, Admission__c, Completed_By__c, Current_Treatment_Plan__c, Draft_Treatment_Plan__c, Draft_Treatment_Plan__r.Status,' + ' Finalized_By__c, Finalized_By_Professional_Name__c, Finalized_By_User__c, Finalized_Date_Time__c, Overall_Goal__c,' + ' Patient_Name__c, Program__c, Snapshot__c, Status__c, Print_Link__c' + ' FROM EGO__c';

	@TestVisible
	private static Id currentUserId = Userinfo.getUserId();
	@TestVisible
	private static Date todayDate {
		get {
			if (todayDate == null) {
				todayDate = System.today();
			}
			return todayDate;
		}
		set;
	}

	//NOTE: This is not necessarily the Patient's "Current Treatment Plan" as of today. In this class, currentTreatmentPlan is just the Case that matches the Id you passed in
	@AuraEnabled
	public Case currentTreatmentPlan { get; set; }

	@AuraEnabled
	public EGO__c ego { get; set; }

	//may not be needed 210521 JN
	@AuraEnabled
	public Map<String, Assigned_Clinician__c> assignedClinicians {
		get {
			if (assignedClinicians == null) {
				queryAssignedClinicians();
			}
			return assignedClinicians;
		}
		set;
	}

	@AuraEnabled
	public String patientId { get; set; }
	@AuraEnabled
	public String patientName { get; set; }

	@AuraEnabled
	public String program { get; set; }

	//EGO stuff
	@AuraEnabled
	public List<Domain> domains { get; set; }
	@AuraEnabled
	public Date newTargetDate { get; set; }
	@AuraEnabled
	public Integer overallRating { get; set; }

	// If there is more than one EGO for the Current Treatment Plan for this patient, then we'll be dealing with an "EGO-R" rather than just an "EGO"
	@AuraEnabled
	public Boolean isEGOR { get; set; }

	//This will be TRUE if this EGO record is the first EGO for the patients current Treatment Plan (patientAccount.Current_Case__c)
	@AuraEnabled
	public Boolean isFirstEgoOnCurrentTreatmentPlan { get; set; }

	// If this is first draft treatment plan, it should not show Goal Comments.
	//NOTE: This actually applies to the EGO, not the Treatment Plan
	@AuraEnabled
	public Boolean isFirstDraftTreatmentPlan { get; set; }

	@AuraEnabled
	public Boolean userCanFinalizeTreatmentPlan { get; set; }

	// This is to determeine if there is unfinalized Draft Treatment Plan
	@AuraEnabled
	public String unfinalizedDraftTreatmentPlanId { get; set; }

	// Determine if there is Draft EGO
	@AuraEnabled
	public Boolean hasDraftEGO { get; set; }

	// Determine if there is a Draft EGO or Draft Treatment Plan, if none, allow create Draft Treatment
	// Plan from Current Treatment Plan without going through EGO. ARC-861
	@AuraEnabled
	public Boolean isCreateDraftTreatmentPlanTeamEditAllowed { get; set; }

	/**
	 * The following three variables for showing Save as Complete button.  These are not initialized except in ViewTreatmentPlanCtl
	 * for optimizing performance because other treatement plan pages do not have Save as Complete button.
	 */
	@AuraEnabled
	public Boolean requiresCoSignature { get; set; }

	/**
	 * Default no-arg constructor, for client->server as per documentation in Returning Data from Apex Server-Side Controller.
	 */
	public TreatmentPlan() {
	}
	/**
	 * Load goals and objectives from current Case but clear all IDs.
	 */
	public TreatmentPlan(Id treatmentPlanId) {
		Set<Id> domainIdSet = new Set<Id>();
		Set<Id> goalIdSet = new Set<Id>();
		Map<Id, List<Integer>> domainEvalItemIndexMap = new Map<Id, List<Integer>>();
		Map<Id, List<Integer>> domainMetadataGoalIndexMap = new Map<Id, List<Integer>>();
		Map<Id, List<Integer>> goalObjectiveIndexMap = new Map<Id, List<Integer>>();
		List<EGO_Rating__c> EGORatingList = new List<EGO_Rating__c>();

		domains = new List<Domain>();

		currentTreatmentPlan = queryTreatmentPlanById(treatmentPlanId);

		userCanFinalizeTreatmentPlan = false;
		if (currentTreatmentPlan.Status == 'Draft' || currentTreatmentPlan.Status == 'Completed') {
			userCanFinalizeTreatmentPlan = checkCanFinalize(treatmentPlanId, currentUserId);
		}

		isFirstDraftTreatmentPlan = false;
		isFirstEgoOnCurrentTreatmentPlan = false;
		isEGOR = false;
		hasDraftEGO = false;
		isCreateDraftTreatmentPlanTeamEditAllowed = false;

		Boolean hasEGO = false;

		// New Target Date is set to be 6 months from today
		newTargetDate = todayDate.addMonths(DEFAULT_TARGET_DATE_DURATION);
		List<Domain__mdt> domainList = queryDomainList();
		domainIdSet = new Map<Id, Domain__mdt>(domainList).keySet();

		List<Eval_Item__mdt> evalItemList = queryEvalItemList(domainIdSet);
		String goalRelatedTo = ((currentTreatmentPlan.Status == 'Draft' || currentTreatmentPlan.Status == 'Finalized') ? 'DraftTreatmentPlan' : 'CurrentTreatmentPlan');

		List<Goal__c> goalList = new List<Goal__c>();

		//This is to create rating mappings
		Map<Id, List<Integer>> goalIdRatingMap = new Map<Id, List<Integer>>();
		Map<Id, List<Integer>> objectiveIdRatingMap = new Map<Id, List<Integer>>();

		// If this is a draft Treatment Plan, EGO__c is not null and will be able to get the ratings for previous Goals and Objectives
		if (String.isNotBlank(currentTreatmentPlan.EGO__c)) {
			ego = queryEGO(currentTreatmentPlan.EGO__c);

			isFirstDraftTreatmentPlan = getIsFirstTreatmentPlan(ego.Current_Treatment_Plan__c);
			isFirstEgoOnCurrentTreatmentPlan = getIsFirstEgoOnCurrentTreatmentPlan(ego.Current_Treatment_Plan__c);
			//JNTODO isFirstEgoOnCurrentTreatmentPlan

			patientId = ego.Current_Treatment_Plan__r.AccountId;
			patientName = ego.Current_Treatment_Plan__r.Account.Name;
			// try
			// {
			//     //therapist=queryTherapist(ego.Current_Treatment_Plan__c);
			//     therapist=queryTherapist(currentTreatmentPlan.AccountId);
			// }
			// catch(QueryException qe)
			// {
			//     // Do nothing, this could be thrown when being used by ViewTreatmentPlan
			// }
			// try
			// {
			//     teamLeader=getTeamLeader(currentTreatmentPlan.AccountId);
			// }
			// catch(QueryException qe)
			// {
			//     // Do nothing, this could be thrown when being used by ViewTreatmentPlan
			// }
			EGORatingList = getEGORatingByEGO(currentTreatmentPlan.EGO__c);
			if (EGORatingList != null && !EGORatingList.isEmpty()) {
				Integer egoRatingIndex = 0;
				for (EGO_Rating__c egoRating : EGORatingList) {
					if (String.isNotBlank(egoRating.Goal__c)) {
						List<Integer> goalRatingIndex = goalIdRatingMap.get(egoRating.Goal__c);
						if (goalRatingIndex == null) {
							goalRatingIndex = new List<Integer>();
						}
						goalRatingIndex.add(egoRatingIndex);
						goalIdRatingMap.put(egoRating.Goal__c, goalRatingIndex);
					}
					if (String.isNotBlank(egoRating.Objective__c)) {
						List<Integer> objectiveRatingIndex = objectiveIdRatingMap.get(egoRating.Objective__c);
						if (objectiveRatingIndex == null) {
							objectiveRatingIndex = new List<Integer>();
						}
						objectiveRatingIndex.add(egoRatingIndex);
						objectiveIdRatingMap.put(egoRating.Objective__c, objectiveRatingIndex);
					}
					egoRatingIndex++;
				}
			}
		} else {
			// integer numNonActiveTreatmentPlans=[SELECT count()
			//                                     FROM EGO__c
			//                                     WHERE Current_Treatment_Plan__c=:treatmentPlanId];
			// isFirstDraftTreatmentPlan=(numNonActiveTreatmentPlans < 1 ? true : false);
			isFirstDraftTreatmentPlan = getIsFirstTreatmentPlan(treatmentPlanId);
			isFirstEgoOnCurrentTreatmentPlan = getIsFirstEgoOnCurrentTreatmentPlan(treatmentPlanId);

			// Viewing Current Treatment Plan
			patientId = currentTreatmentPlan.AccountId;
			patientName = currentTreatmentPlan.Account.Name;
			try {
				Case unfinalizedDraftTreatmentPlan = [SELECT Id FROM Case WHERE Status NOT IN ('Active', 'Finalized', 'Inactive') AND (EGO__r.Current_Treatment_Plan__c = :treatmentPlanId OR (EGO__c = NULL AND AccountId = :patientId AND Admission__c = :currentTreatmentPlan.Admission__c)) ORDER BY CreatedDate DESC LIMIT 1];
				unfinalizedDraftTreatmentPlanId = unfinalizedDraftTreatmentPlan.Id;
			} catch (QueryException qe) {
				system.debug(qe.getMessage());
			}

			List<EGO__c> egoList = queryEGOList(currentTreatmentPlan.Id);

			if (egoList != null && !egoList.isEmpty()) {
				hasEGO = true;
				if (egoList.size() > 1) {
					isEGOR = true;
				} else if (egoList.size() == 1) {
					if (egoList[0].Status__c == 'Finalized') {
						isEGOR = true;
					}
				}

				for (EGO__c ego : egoList) {
					// if(ego.Draft_Treatment_Plan__c!=null
					//         && String.isNotBlank(ego.Draft_Treatment_Plan__r.Status)
					//         && ego.Draft_Treatment_Plan__r.Status.equalsIgnoreCase('Finalized'))
					// {
					//     lastEGOFinalized=ego.Date__c;
					// }
					if ('draft'.equalsIgnoreCase(ego.Status__c)) {
						hasDraftEGO = true;
					}
				}
			}
			// Viewing Current Treatment Plan
			//
			// Loading the latest EGO that's empty and if there is No EGO ready
			/**
             * Defect - Will create empty EGO when there is a draft treatment plan already
             *
            try
            {
                ego=[SELECT Id,Current_Treatment_Plan__c,Current_Treatment_Plan__r.Account.Name,Completed_By__c,Date__c,Draft_Treatment_Plan__c FROM EGO__c WHERE Current_Treatment_Plan__c=:treatmentPlanId AND Draft_Treatment_Plan__c=null limit 1];
            }catch(QueryException qe){
                system.debug('Exception No EGO Found, creating new EGO for draft treatment plan');
                ego=new EGO__c(Current_Treatment_Plan__c=treatmentPlanId);
                insert ego;
            }*/
		}
		if (!hasDraftEGO && hasEGO && String.isBlank(unfinalizedDraftTreatmentPlanId)) {
			isCreateDraftTreatmentPlanTeamEditAllowed = true;
		}

		goalList = queryGoalList(goalRelatedTo, treatmentPlanId);

		// Build Domain Metadata ID - Goal List Index.  Can be refactored in a Util class for generic usage.
		Integer index = 0;
		for (Eval_Item__mdt evalItem : evalItemList) {
			List<Integer> evalItemIndexList = domainEvalItemIndexMap.get(evalItem.Domain__c);
			if (evalItemIndexList == null) {
				evalItemIndexList = new List<Integer>();
			}
			evalItemIndexList.add(index);
			domainEvalItemIndexMap.put(evalItem.Domain__c, evalItemIndexList);
			index++;
		}
		index = 0;
		for (Goal__c goal : goalList) {
			goalIdSet.add(goal.Id);
			List<Integer> goalIndex = domainMetadataGoalIndexMap.get(goal.Domain_Metadata_ID__c);
			if (goalIndex == null) {
				goalIndex = new List<Integer>();
			}
			goalIndex.add(index);
			domainMetadataGoalIndexMap.put(goal.Domain_Metadata_ID__c, goalIndex);
			index++;
		}

		List<Objective__c> objectiveList = getObjectiveList(goalIdSet);
		index = 0;
		for (Objective__c objective : objectiveList) {
			goalIdSet.add(objective.Id);
			List<Integer> objectiveIndex = goalObjectiveIndexMap.get(objective.goal__c);
			if (objectiveIndex == null) {
				objectiveIndex = new List<Integer>();
			}
			objectiveIndex.add(index);
			goalObjectiveIndexMap.put(objective.goal__c, objectiveIndex);
			index++;
		}

		Boolean hasEGORatingList = !EGORatingList.isEmpty();

		for (Domain__mdt domainMdt : domainList) {
			Domain domainObj = new Domain();
			domainObj.domainObj = domainMdt;
			domainObj.ratingItems = getDomainRatingItemList(domainEvalItemIndexMap.get(domainMdt.Id), evalItemList);
			domainObj.goals = new List<Goal>();
			List<Integer> domainGoalList = domainMetadataGoalIndexMap.get(domainMdt.Id);
			if (domainGoalList != null) {
				for (Integer domainGoalIndex : domainGoalList) {
					Goal goalObj = new Goal();
					goalObj.goalObj = goalList.get(domainGoalIndex);
					goalObj.newTargetDate = newTargetDate;
					goalObj.status = goalObj.goalObj.Status__c;
					if (hasEGORatingList) {
						List<Integer> ratingIndexList = goalIdRatingMap.get(goalObj.goalObj.Id);

						if (ratingIndexList != null) {
							for (Integer ratingIndex : ratingIndexList) {
								EGO_Rating__c egoRating = EGORatingList.get(ratingIndex);
								goalObj.rating = egoRating.Rating__c;
								goalObj.comments = egoRating.Comments__c;
								goalObj.goalObj.Domain_Name__c = domainMdt.Label__c;
								goalObj.goalObj.DOmain_Number__c = domainMdt.DOmain_Number__c;
							}
						}
					}
					goalObj.objectives = new List<Objective>();
					List<Integer> goalObjectiveList = goalObjectiveIndexMap.get(goalObj.goalObj.Id);
					if (goalObjectiveList != null) {
						for (Integer goalObjectiveIndex : goalObjectiveList) {
							Objective objectiveObj = new Objective();
							objectiveObj.isDeleted = false;
							objectiveObj.objectiveObj = objectiveList.get(goalObjectiveIndex);
							objectiveObj.newTargetDate = newTargetDate;
							objectiveObj.status = objectiveObj.objectiveObj.Status__c;
							if (hasEGORatingList) {
								List<Integer> ratingIndexList = objectiveIdRatingMap.get(objectiveObj.objectiveObj.Id);
								if (ratingIndexList != null) {
									for (Integer ratingIndex : ratingIndexList) {
										EGO_Rating__c egoRating = EGORatingList.get(ratingIndex);
										objectiveObj.rating = egoRating.Rating__c;
									}
								}
							}
							goalObj.objectives.add(objectiveObj);
						}
					}
					domainObj.goals.add(goalObj);
				}
			}
			domains.add(domainObj);
		}
	} //end constructor

	private Case queryTreatmentPlanById(Id treatmentPlanId) {
		String sObjectType = 'Case';
		List<String> treatmentPlanExtraFields = new List<String>{ 'Account.Photo__c', 'Account.Name', 'Account.Current_Case__c', 'Admission__r.Admit_Date__c', 'Admission__r.Team__c', 'Admission__r.Psychotherapist__r.Professional_Name__c', 'Admission__r.Medical_Care_Plan__c', 'Print_Link__c' };
		String mainTPQueryString = QueryUtils.getQueryAll(sObjectType, treatmentPlanExtraFields);
		String treatmentPlanWherePart = 'WHERE Id = \'' + treatmentPlanId + '\'';
		String tpQueryString = mainTPQueryString + ' ' + treatmentPlanWherePart;

		List<Case> cases = (List<Case>) Database.query(tpQueryString);
		Case caseObj;
		if (!cases.isEmpty()) {
			caseObj = cases[0];
			// Case caseObj=[SELECT Id
			// , Status, CaseNumber, Goal__c, Admission__c, AccountId, Account.Photo__c, Account.Name, Account.Current_Case__c,
			// Admission__r.Admit_Date__c, Admission__r.Team__c,
			// CreatedDate, EGO__c, Account.Current_Case__c,
			// Finalized_By__c,Finalized_By_User__c,Finalized_Date_Time__c, Finalized_By_Professional_Name__c
			// FROM Case
			// WHERE Id=:treatmentPlanId];
		}
		return caseObj;
	}

	private Boolean checkCanFinalize(Id treatmentPlanId, Id userId) {
		Set<Id> authSigners = AuthorizedSigners.getSignersByTreatmentPlanId(treatmentPlanId);
		if (authSigners.contains(userId)) {
			return true;
		}
		return false;
	}

	private static List<sObject> querySobject(String sObjectType, List<String> extraFields, String wherePart) {
		String mainQueryString = QueryUtils.getQueryAll(sObjectType, extraFields);
		String fullQueryString = mainQueryString + ' ' + wherePart;

		List<sObject> sObjects = (List<sObject>) Database.query(fullQueryString);
		return sObjects;
	}

	private static List<Domain__mdt> queryDomainList() {
		List<Domain__mdt> domainList = [SELECT Id, DeveloperName, Domain_Number__c, Active__c, Label__c FROM Domain__mdt WHERE Active__c = TRUE ORDER BY Domain_Number__c];
		return domainList;
	}

	private static List<Eval_Item__mdt> queryEvalItemList(Set<Id> domainIdSet) {
		List<Eval_Item__mdt> domainEvalItemList = [
			SELECT Id, DeveloperName, Item_Number__c, Active__c, Label__c, Domain__c, Domain__r.Domain_Number__c
			FROM Eval_Item__mdt
			WHERE Domain__c IN :domainIdSet AND Active__c = TRUE
			//ORDER BY Domain__r.Domain_Number__c ASC, Item_Number__c ASC
			ORDER BY Item_Number__c ASC
		];
		return domainEvalItemList;
	}

	//INSTANCE METHODS

	//NOTE may not be needed 210521 JN
	private Map<String, Assigned_Clinician__c> queryAssignedClinicians() {
		Map<String, Assigned_Clinician__c> role2ClinicianMap = new Map<String, Assigned_Clinician__c>();

		List<String> extraFields = new List<String>{ 'Admission__r.Admit_Date__c', 'Admission__r.Team__c', 'Admission__r.Admit_Date__c', 'Admission__r.Psychotherapist__r.Professional_Name__c' };
		String wherePart = 'WHERE Admission__c = \'' + currentTreatmentPlan.Admission__c + '\'';

		List<Assigned_Clinician__c> assignedClinicians = (List<Assigned_Clinician__c>) querySobject('Assigned_Clinician__c', extraFields, wherePart);

		if (!assignedClinicians.isEmpty()) {
			for (Assigned_Clinician__c clin : assignedClinicians) {
				role2ClinicianMap.put(clin.Role__c, clin);
			}
		}
		return role2ClinicianMap;
	}

	/**
	 * This will get a list of EGO if this is current Treatment Plan
	 * This list of EGOs assumes that the treatmentPlanId is the patient's Current Treatment Plan (patientAccount.Current_Case__c)
	 * If a Draft TP Id is passed in, there should be nothing returned unless the data is bad
	 */
	private List<EGO__c> queryEGOList(Id treatmentPlanId) {
		//egoquery 1
		String queryString = egoBaseQueryString + ' WHERE ';
		List<EGO__c> egoList = [SELECT Id, Admission__c, Completed_By__c, Draft_Treatment_Plan__c, Draft_Treatment_Plan__r.Status, Current_Treatment_Plan__c, Status__c, Print_Link__c FROM EGO__c WHERE Current_Treatment_Plan__c = :treatmentPlanId ORDER BY CreatedDate DESC];
		return egoList;
	}

	/**
	 * This is to retrieve single EGO, which will only happen when a DRAFT Treatment Plan is loaded.
	 */
	private EGO__c queryEGO(Id EGOId) {
		EGO__c returnEgo;

		String sObjectType = 'EGO__c';
		List<String> extraFields = new List<String>{ 'Admission__r.Admit_Date__c', 'Admission__r.Team__c', 'Admission__r.Admit_Date__c', 'Admission__r.Psychotherapist__r.Professional_Name__c', 'Current_Treatment_Plan__r.Status', 'Current_Treatment_Plan__r.AccountId', 'Current_Treatment_Plan__r.Account.Name', 'Current_Treatment_Plan__r.Account.Current_Case__c', 'Current_Treatment_Plan__r.Account.Current_Admission__c', 'Draft_Treatment_Plan__r.Status', 'Print_Link__c' };
		String mainQueryString = QueryUtils.getQueryAll(sObjectType, extraFields);
		String wherePart = 'WHERE Id = \'' + EGOId + '\'';

		String fullQueryString = mainQueryString + ' ' + wherePart;

		List<EGO__c> egos = (List<EGO__c>) Database.query(fullQueryString);

		if (!egos.isEmpty()) {
			returnEgo = egos[0];
		}

		return returnEgo;
	}

	private List<Goal__c> queryGoalList(String queryFrom, String fromRecordId) {
		String query = 'SELECT Id, Domain_Metadata_ID__c, Label__c, Status__c,Target_Date__c,EGO__c, Treatment_Plan__c,' + ' Domain_Name__c,Domain_Number__c,Draft_Treatment_Plan__c,Date_Added__c,Team_Goal_Comments__c,Source__c,Continued_From_Goal__c,Met_Discontinued_Date__c,' + ' Continued_From_Goal__r.Target_Date__c, Order__c' + ' FROM Goal__c' + ' WHERE';
		//extraFields: Continued_From_Goal__r.Target_Date__c

		if (queryFrom.equalsIgnoreCase('ego')) {
			query += ' EGO__c';
		} else if (queryFrom.equalsIgnoreCase('drafttreatmentplan')) {
			query += ' Draft_Treatment_Plan__c';
		} else {
			query += ' Treatment_Plan__c';
		}
		query += '=:fromRecordId ORDER BY Order__c';

		List<Goal__c> goalList = Database.query(query);
		return goalList;
	}
	private List<Objective__c> getObjectiveList(Set<Id> goalIdSet) {
		List<Objective__c> objectiveList = [SELECT Id, GoaL__c, Label__c, Status__c, Date_Added__c, Target_Date__c, Source__c, Continued_From_Objective__c, Continued_From_Objective__r.Target_Date__c, Met_Discontinued_Date__c, Order__c FROM Objective__c WHERE Goal__c IN :goalIdSet ORDER BY Order__c];
		return objectiveList;
	}
	private List<RatingItem> getDomainRatingItemList(List<Integer> indexList, List<Eval_Item__mdt> evalItemList) {
		List<RatingItem> retval = new List<RatingItem>();
		if (indexList != null) {
			for (Integer index : indexList) {
				Eval_Item__mdt evalItem = evalItemList.get(index);
				RatingItem domainRatingItem = new RatingItem();
				domainRatingItem.itemNumber = Integer.valueOf(evalItem.Item_Number__c).format();
				domainRatingItem.ratingItem = new EGO_Rating__c(Domain_Eval_Item_ID__c = evalItem.Id, Label__c = evalItem.Label__c, Type__c = 'Domain Item');
				retval.add(domainRatingItem);
			}
		}
		return retval;
	}
	private List<EGO_Rating__c> getEGORatingByEGO(Id EGOId) {
		return [SELECT Id, Order__c, Comments__c, Domain_Eval_Item_ID__c, EGO__c, Name, Goal__c, Label__c, Objective__c, Rating__c, Type__c FROM EGO_Rating__c WHERE EGO__c = :EGOId ORDER BY Print_Order__c, Name];
	}

	//JNTODO 210526: believe no longer needed
	// public static TreatmentPlan getCurrentTreatmentPlan(Id patientId)
	// {
	//     Account patient=[SELECT ID, Current_Case__c
	//                     FROM Account
	//                     WHERE ID=:patientId];
	//     return new TreatmentPlan(patient.Current_Case__c);
	// }

	public static TreatmentPlan getTreatmentPlan(Id treatmentPlanId) {
		return new TreatmentPlan(treatmentPlanId);
	}

	public static TreatmentPlan getTreatmentPlanByEGOId(String egoId) {
		// if (Userinfo.getUserId() == [select Id from User where Name = 'Jeremy Nottingham' and IsActive = true].Id)
		// {
		//     try
		//     {
		//         throw new CustomException();
		//     } catch (Exception e)
		//     {
		//         ProcessLogging.quickProcessLog('Jeremy Test TreatmentPlan getTreatmentPlanByEGOId', e.getStackTraceString(), 'querying for ego ' + egoId);
		//     }
		// }

		//egoquery 2
		//JNTODO:
		EGO__c ego = [SELECT Id, Admission__c, Current_Treatment_Plan__c, Draft_Treatment_Plan__c, Overall_Goal__c, Finalized_By__c, Finalized_Date_Time__c, Finalized_By_User__c, Finalized_By_Professional_Name__c, Print_Link__c, Status__c FROM EGO__c WHERE Id = :egoId];
		Id currentTreatmentPlanId = ego.Current_Treatment_Plan__c; //WARNING: Not if this ego is from a previous Admission JN
		Id admissionID = ego.Admission__c; //W: same as line above: we are not necessarily using today's current treatment plan or admission for this patient

		TreatmentPlan treatmentPlanObj = new TreatmentPlan();
		treatmentPlanObj.currentTreatmentPlan = [SELECT Id, CaseNumber, Goal__c, Admission__c, AccountId, Account.Photo__c, Account.Name, Admission__r.Admit_Date__c, Admission__r.team__c, Admission__r.Psychotherapist__r.Professional_Name__c, CreatedDate, EGO__c, Status, Finalized_By__c, Finalized_Date_Time__c FROM Case WHERE Id = :currentTreatmentPlanId];

		List<Goal__c> goalList = new List<Goal__c>();
		List<Objective__c> objectiveList = new List<Objective__c>();

		String query = 'SELECT Id, Domain_Metadata_ID__c, Label__c, Status__c, Target_Date__c, EGO__c, Treatment_Plan__c,' + ' Domain_Name__c, Domain_Number__c, Draft_Treatment_Plan__c, Date_Added__c, Team_Goal_Comments__c, Source__c, Continued_From_Goal__c, Met_Discontinued_Date__c,' + ' Continued_From_Goal__r.Target_Date__c' + ' FROM Goal__c' + ' WHERE EGO__c = :egoId' + ' ORDER BY Order__c';

		goalList = (List<Goal__c>) Database.query(query);

		if (goalList != null && !goalList.isEmpty()) {
			Set<Id> goalIdSet = new Map<Id, Goal__c>(goalList).keySet();
			//Set<Id> goalIdSet=new Set<Id>();
			// for(Goal__c goal:goalList)
			// {
			//     goalIdSet.add(goal.Id);
			// }

			objectiveList = [SELECT Id, GoaL__c, Label__c, Status__c, Date_Added__c, Target_Date__c, Source__c, Continued_From_Objective__c, Met_Discontinued_Date__c FROM Objective__c WHERE Goal__c IN :goalIdSet ORDER BY Order__c, Name];
		}
		treatmentPlanObj.ego = ego;
		treatmentPlanObj.newTargetDate = todayDate.addMonths(DEFAULT_TARGET_DATE_DURATION);
		treatmentPlanObj.domains = getDomains(egoId, treatmentPlanObj.newTargetDate, goalList, objectiveList);

		// treatmentPlanObj.isFirstDraftTreatmentPlan=false;
		// integer numNonActiveTreatmentPlans=[SELECT count()
		//                                     FROM EGO__c
		//                                     WHERE Current_Treatment_Plan__c = :currentTreatmentPlanId];
		// treatmentPlanObj.isFirstDraftTreatmentPlan=(numNonActiveTreatmentPlans < 1 ? true : false);
		treatmentPlanObj.isFirstDraftTreatmentPlan = getIsFirstTreatmentPlan(currentTreatmentPlanId);
		treatmentPlanObj.isFirstEgoOnCurrentTreatmentPlan = getIsFirstEgoOnCurrentTreatmentPlan(currentTreatmentPlanId);

		// Viewing Current Treatment Plan
		treatmentPlanObj.patientId = treatmentPlanObj.currentTreatmentPlan.AccountId;
		treatmentPlanObj.patientName = treatmentPlanObj.currentTreatmentPlan.Account.Name;
		try {
			Case unfinalizedDraftTreatmentPlan = [SELECT Id FROM Case WHERE EGO__c != NULL AND EGO__r.Current_Treatment_Plan__c = :currentTreatmentPlanId AND Status NOT IN ('Active', 'Finalized', 'Inactive') ORDER BY CreatedDate DESC LIMIT 1];
			treatmentPlanObj.unfinalizedDraftTreatmentPlanId = unfinalizedDraftTreatmentPlan.Id;
		} catch (QueryException qe) {
			//silent failure would be no rows for assignment but only if very bad data
			system.debug(qe.getMessage());
		}
		//JNTODO
		//egoquery 3
		List<EGO__c> egoList = [SELECT Id, Admission__c, Completed_By__c, Draft_Treatment_Plan__c, Draft_Treatment_Plan__r.Status, Current_Treatment_Plan__c, Status__c, Finalized_By__c, Finalized_Date_Time__c, Print_Link__c FROM EGO__c WHERE Current_Treatment_Plan__c = :currentTreatmentPlanId ORDER BY CreatedDate DESC];

		if (egoList != null && !egoList.isEmpty()) {
			if (egoList.size() > 1) {
				treatmentPlanObj.isEGOR = true;
			} else if (egoList.size() == 1) {
				if (egoList[0].Status__c == 'Finalized') {
					treatmentPlanObj.isEGOR = true;
				}
			}
		}
		return treatmentPlanObj;
	}

	//actually refers to EGO, related to whatever tpId is getting passed in
	private static Boolean getIsFirstTreatmentPlan(Id currentTreatmentPlanId) {
		Boolean isFirstDraftTreatmentPlan = false;
		//egoquery 4
		Integer numNonActiveTreatmentPlans = [SELECT COUNT() FROM EGO__c WHERE Current_Treatment_Plan__c = :currentTreatmentPlanId];
		if (numNonActiveTreatmentPlans < 1) {
			isFirstDraftTreatmentPlan = true;
		}
		return isFirstDraftTreatmentPlan;
	}

	//first EGO created, related to whatever tpId is getting passed in
	private static Boolean getIsFirstEgoOnCurrentTreatmentPlan(Id currentTreatmentPlanId) {
		Boolean isFirstEgoOnCurrentTreatmentPlan = false;
		//egoquery 5
		Id currentTpId = [SELECT Account.Current_Case__c FROM Case WHERE Id = :currentTreatmentPlanId].Account.Current_Case__c;
		Integer numNonActiveTreatmentPlans = [SELECT COUNT() FROM EGO__c WHERE Current_Treatment_Plan__c = :currentTpId];
		if (numNonActiveTreatmentPlans <= 1) {
			isFirstEgoOnCurrentTreatmentPlan = true;
		}
		return isFirstEgoOnCurrentTreatmentPlan;
	}

	/**
	 * Populate Domains
	 */
	private static List<Domain> getDomains(String egoId, Date newTargetDate, List<Goal__c> goalList, List<Objective__c> objectiveList) {
		Set<Id> domainIdSet = new Set<Id>();
		Set<Id> goalIdSet = new Set<Id>();
		List<Domain> domains = new List<Domain>();
		Map<Id, List<Integer>> domainEvalItemIndexMap = new Map<Id, List<Integer>>();
		Map<Id, List<Integer>> domainMetadataGoalIndexMap = new Map<Id, List<Integer>>();
		Map<Id, List<Integer>> goalObjectiveIndexMap = new Map<Id, List<Integer>>();
		Map<Id, Integer> domainIdRatingMap = new Map<Id, Integer>();
		Map<Id, Integer> goalIdRatingMap = new Map<Id, Integer>();
		Map<Id, Integer> objectiveIdRatingMap = new Map<Id, Integer>();
		// List<Domain__mdt> domainList=[SELECT Id,DeveloperName,Domain_Number__c,Active__c,Label__c FROM Domain__mdt WHERE Active__c=true order by Domain_Number__c];
		List<Domain__mdt> domainList = queryDomainList();
		domainIdSet = new Map<Id, Domain__mdt>(domainList).keySet();
		// for(Domain__mdt domain:domainList){
		//     domainIdSet.add(domain.Id);
		// }
		// List<Eval_Item__mdt> evalItemList=[SELECT Id,DeveloperName,Item_Number__c,Active__c,Label__c,Domain__c,Domain__r.Domain_Number__c FROM Eval_Item__mdt WHERE Domain__c=:domainIdSet AND Active__c=true order by Item_Number__c];
		List<Eval_Item__mdt> evalItemList = queryEvalItemList(domainIdSet);

		List<EGO_Rating__c> EGORatingList = new List<EGO_Rating__c>();
		if (String.isNotBlank(egoId)) {
			EGORatingList = [SELECT Id, Comments__c, Domain_Eval_Item_ID__c, EGO__c, Name, Goal__c, Label__c, Objective__c, Rating__c, Type__c FROM EGO_Rating__c WHERE EGO__c = :egoId ORDER BY Print_Order__c, Name];

			if (EGORatingList != null && !EGORatingList.isEmpty()) {
				Integer egoRatingIndex = 0;
				for (EGO_Rating__c egoRating : EGORatingList) {
					if (String.isNotBlank(egoRating.Goal__c)) {
						goalIdRatingMap.put(egoRating.Goal__c, egoRatingIndex);
					}
					if (String.isNotBlank(egoRating.Objective__c)) {
						objectiveIdRatingMap.put(egoRating.Objective__c, egoRatingIndex);
					}
					if (String.isNotBlank(egoRating.Domain_Eval_Item_ID__c)) {
						domainIdRatingMap.put(egoRating.Domain_Eval_Item_ID__c, egoRatingIndex);
					}
					egoRatingIndex++;
				}
			}
		}
		Integer index = 0;
		for (Eval_Item__mdt evalItem : evalItemList) {
			List<Integer> evalItemIndexList = domainEvalItemIndexMap.get(evalItem.Domain__c);
			if (evalItemIndexList == null) {
				evalItemIndexList = new List<Integer>();
			}
			evalItemIndexList.add(index);
			domainEvalItemIndexMap.put(evalItem.Domain__c, evalItemIndexList);
			index++;
		}
		index = 0;
		goalIdSet.clear();
		if (goalList != null && !goalList.isEmpty()) {
			for (Goal__c goal : goalList) {
				goalIdSet.add(goal.Id);
				List<Integer> goalIndex = domainMetadataGoalIndexMap.get(goal.Domain_Metadata_ID__c);
				if (goalIndex == null) {
					goalIndex = new List<Integer>();
				}
				goalIndex.add(index);
				domainMetadataGoalIndexMap.put(goal.Domain_Metadata_ID__c, goalIndex);
				index++;
			}
			/*
            if(objectiveList != null && objectiveList.isEmpty()){
                objectiveList=[SELECT Id,GoaL__c,Label__c,Status__c,Date_Added__c,Target_Date__c,Source__c,Continued_From_Objective__c,Continued_From_Objective__r.Target_Date__c,Met_Discontinued_Date__c FROM Objective__c WHERE Goal__c=:goalIdSet];
            }*/
			index = 0;
			for (Objective__c objective : objectiveList) {
				List<Integer> objectiveIndex = goalObjectiveIndexMap.get(objective.goal__c);
				if (objectiveIndex == null) {
					objectiveIndex = new List<Integer>();
				}
				objectiveIndex.add(index);
				goalObjectiveIndexMap.put(objective.goal__c, objectiveIndex);
				index++;
			}
		}
		Boolean hasEGORatingList = !EGORatingList.isEmpty();
		for (Domain__mdt domainMdt : domainList) {
			Domain domainObj = new Domain();
			domainObj.domainObj = domainMdt;

			//domainObj.ratingItems=getDomainRatingItemList(domainEvalItemIndexMap.get(domainMdt.Id),evalItemList);
			domainObj.ratingItems = new List<RatingItem>();
			List<Integer> indexList = domainEvalItemIndexMap.get(domainMdt.Id);
			if (indexList != null) {
				for (Integer indexInteger : indexList) {
					Eval_Item__mdt evalItem = evalItemList.get(indexInteger);
					RatingItem domainRatingItem = new RatingItem();
					domainRatingItem.itemNumber = Integer.valueOf(evalItem.Item_Number__c).format();
					if (hasEGORatingList) {
						Integer ratingIndex = domainIdRatingMap.get(evalItem.Id);
						if (ratingIndex != null) {
							EGO_Rating__c egoRating = EGORatingList.get(ratingIndex);
							domainRatingItem.ratingItem = egoRating;
							domainRatingItem.ratingItem.Order__c = evalItem.Item_Number__c;
							domainRatingItem.ratingItem.Domain_Name__c = domainObj.domainObj.Label__c;
							domainRatingItem.ratingItem.Domain_Number__c = domainObj.domainObj.Domain_Number__c;
						}
					} else {
						domainRatingItem.ratingItem = new EGO_Rating__c(Domain_Eval_Item_ID__c = evalItem.Id, Label__c = evalItem.Label__c, Type__c = 'Domain Item', Domain_Name__c = domainObj.domainObj.Label__c, Domain_Number__c = domainObj.domainObj.Domain_Number__c, Order__c = evalItem.Item_Number__c);
					}
					domainObj.ratingItems.add(domainRatingItem);
				}
			}
			domainObj.goals = new List<Goal>();
			List<Integer> domainGoalList = domainMetadataGoalIndexMap.get(domainMdt.Id);
			if (domainGoalList != null) {
				for (Integer domainGoalIndex : domainGoalList) {
					Goal goalObj = new Goal();
					goalObj.isDeleted = false;
					goalObj.goalObj = goalList.get(domainGoalIndex);
					goalObj.newTargetDate = goalObj.goalObj.Target_Date__c;
					if (goalObj.newTargetDate == null) {
						goalObj.newTargetDate = newTargetDate;
					}
					goalObj.status = goalObj.goalObj.Status__c;
					goalObj.ratingItem = new RatingItem();
					if (hasEGORatingList) {
						Integer ratingIndex = goalIdRatingMap.get(goalObj.goalObj.Id);
						if (ratingIndex != null) {
							EGO_Rating__c egoRating = EGORatingList.get(ratingIndex);
							goalObj.ratingItem.ratingItem = egoRating;
							goalObj.rating = egoRating.Rating__c;
							goalObj.comments = egoRating.Comments__c;
						}
					}
					goalObj.objectives = new List<Objective>();
					List<Integer> goalObjectiveList = goalObjectiveIndexMap.get(goalObj.goalObj.Id);
					if (goalObjectiveList != null) {
						for (Integer goalObjectiveIndex : goalObjectiveList) {
							Objective objectiveObj = new Objective();
							objectiveObj.isDeleted = false;
							objectiveObj.objectiveObj = objectiveList.get(goalObjectiveIndex);
							objectiveObj.newTargetDate = objectiveObj.objectiveObj.Target_Date__c;
							if (objectiveObj.newTargetDate == null) {
								objectiveObj.newTargetDate = newTargetDate;
							}
							objectiveObj.status = objectiveObj.objectiveObj.Status__c;
							objectiveObj.ratingItem = new RatingItem();
							if (hasEGORatingList) {
								Integer ratingIndex = objectiveIdRatingMap.get(objectiveObj.objectiveObj.Id);
								if (ratingIndex != null) {
									EGO_Rating__c egoRating = EGORatingList.get(ratingIndex);
									objectiveObj.ratingItem.ratingItem = egoRating;
									objectiveObj.rating = egoRating.Rating__c;
								}
								/*
                                List<Integer> ratingIndexList=objectiveIdRatingMap.get(objectiveObj.objectiveObj.Id);
                                if(ratingIndexList!=null){
                                    for(Integer ratingIndex:ratingIndexList){
                                        EGO_Rating__c egoRating=EGORatingList.get(ratingIndex);
                                        objectiveObj.rating=Integer.valueOf(egoRating.Rating__c);
                                    }
                                }*/
							}
							goalObj.objectives.add(objectiveObj);
						}
					}
					domainObj.goals.add(goalObj);
				}
			}
			domains.add(domainObj);
		}
		return domains;
	}

	/**
	 * Take current Treatment Plan and clone Goals and Objectives
	 * @recordId could be EGO ID or Current Treatment Plan ID
	 */
	public static List<Domain> buildDomains(Boolean isNewEGO, Boolean cloneGoalsObjectives, String egoId, String currentTreatmentPlanId) {
		List<Domain> domains = new List<Domain>();

		List<Goal__c> goalList = new List<Goal__c>();
		List<Objective__c> objectiveList = new List<Objective__c>();
		List<Goal__c> clonedGoalList = new List<Goal__c>();
		List<Objective__c> clonedObjectiveList = new List<Objective__c>();

		String query = 'SELECT Id,Order__c,Domain_Metadata_ID__c,Label__c,Status__c,Target_Date__c,EGO__c, Treatment_Plan__c,' + ' Domain_Name__c,Domain_Number__c,Draft_Treatment_Plan__c,Date_Added__c,Team_Goal_Comments__c,Source__c,' + ' Continued_From_Goal__c,Continued_From_Goal__r.Target_Date__c' + ' FROM Goal__c' + ' WHERE';

		/**
		 * 1. New draft EGO
		 * 2. Draft EGO but no Goals
		 * 3. Draft EGO with Goals
		 * 4. New draft EGO-R
		 *    - Draft EGO-R without Goals (need clone from current treatment plan goals)
		 * 5. Edit Draft EGO-R without Goals (need clone from current treatment plan goals)
		 */
		if (isNewEGO) {
			query += ' Treatment_Plan__c = :currentTreatmentPlanId' + ' ORDER BY Order__c, Name';
			goalList = (List<Goal__c>) Database.query(query);
		} else {
			String EGOQuery;
			if (String.isNotBlank(egoId)) {
				EGOQuery = query + ' EGO__c = :egoId ORDER BY Name';
				goalList = (List<Goal__c>) Database.query(EGOQuery);
			}
			if (goalList == null || goalList.isEmpty()) {
				EGOQuery = query + ' Treatment_Plan__c = :currentTreatmentPlanId ORDER BY Order__c,Name';
				goalList = (List<Goal__c>) Database.query(EGOQuery);
			}
		}
		if (goalList != null && !goalList.isEmpty()) {
			Set<Id> goalIdSet = new Set<Id>();
			goalIdSet = new Map<Id, Goal__c>(goalList).keySet();
			objectiveList = [SELECT Id, Order__c, Goal__c, Label__c, Status__c, Date_Added__c, Target_Date__c, Source__c, Continued_From_Objective__c, Met_Discontinued_Date__c FROM Objective__c WHERE Goal__c IN :goalIdSet ORDER BY Order__c, Name];
		}
		/**
		 * Deep Clone Goals & Objectives
		 *
		 * If existing Draft EGO, get EGO.  But if it is brand new EGO-R, then gets Goals from Current Treatment Plan, clone Goals and Objectives.
		 */
		if (cloneGoalsObjectives) {
			if (!goalList.isEmpty()) {
				Map<String, Integer> goalIdIndexMap = new Map<String, Integer>();
				Goal__c clonedGoal;
				Objective__c clonedObjective;
				Integer goalIndex = 0;
				for (Goal__c goal : goalList) {
					goalIdIndexMap.put(goal.Id, goalIndex);
					clonedGoal = goal.clone(false, true, false, false);
					if (String.isNotBlank(egoId)) {
						clonedGoal.EGO__c = egoId;
					} else {
						clonedGoal.EGO__c = null;
					}
					clonedGoal.Continued_From_Goal__c = goal.Id;
					clonedGoal.Draft_Treatment_Plan__c = null;
					clonedGoal.Treatment_Plan__c = null;
					clonedGoal.Team_Goal_Comments__c = null;
					clonedGoalList.add(clonedGoal);
					goalIndex++;
				}
				insert clonedGoalList;

				for (Objective__c objective : objectiveList) {
					clonedObjective = objective.clone(false, true, false, false);
					clonedObjective.Goal__c = clonedGoalList.get(goalIdIndexMap.get(objective.Goal__c)).Id;
					clonedObjective.Continued_From_Objective__c = objective.Id;
					clonedObjectiveList.add(clonedObjective);
				}
				insert clonedObjectiveList;

				goalList = clonedGoalList;
				objectiveList = clonedObjectiveList;
			}
		}
		return getDomains(egoId, todayDate.addMonths(DEFAULT_TARGET_DATE_DURATION), goalList, objectiveList);
	}

	/**
	 * Create EGO or EGO-R if no EGO with Draft status is found.
	 *
	 * When creating EGO-R, clone Goals and Objectives.
	 */
	public static TreatmentPlan conductEGO(Id currentTreatmentPlanId) {
		TreatmentPlan treatmentPlanObj = new TreatmentPlan();
		treatmentPlanObj.currentTreatmentPlan = [SELECT Id, CaseNumber, Goal__c, Admission__c, AccountId, Account.Photo__c, Account.Name, Admission__r.Admit_Date__c, Admission__r.team__c, Admission__r.Psychotherapist__r.Professional_Name__c, CreatedDate, EGO__c, Status FROM Case WHERE Id = :currentTreatmentPlanId];

		boolean isNewEGO = false;
		Boolean cloneGoalsObjectives = false;
		EGO__c ego;
		try {
			// Try searching for existing empty EGO that could be created for Draft Treatment Plan but the EGO got cancelled on UI.
			//egoquery 6
			ego = [SELECT Id, Admission__c, Overall_Goal__c, Current_Treatment_Plan__c, Draft_Treatment_Plan__c, Program__c, Status__c, Finalized_By__c, Finalized_Date_Time__c, Print_Link__c FROM EGO__c WHERE Current_Treatment_Plan__c = :currentTreatmentPlanId AND Draft_Treatment_Plan__c = NULL AND Status__c = 'Draft' LIMIT 1];
		} catch (exception e) {
			// No empty EGO to be reused, create new EGO.
			ego = new EGO__c(Current_Treatment_Plan__c = currentTreatmentPlanId, Overall_Goal__c = treatmentPlanObj.currentTreatmentPlan.Goal__c, Admission__c = treatmentPlanObj.currentTreatmentPlan.Admission__c, Status__c = 'Draft');
			insert ego;
			isNewEGO = true;
			cloneGoalsObjectives = true;
		}
		treatmentPlanObj.ego = ego;
		String egoId = ego.Id;
		ID admissionID = ego.Admission__c;

		treatmentPlanObj.domains = TreatmentPlan.buildDomains(isNewEGO, cloneGoalsObjectives, egoId, currentTreatmentPlanId);

		// New Target Date is set to be 6 months from today
		treatmentPlanObj.newTargetDate = todayDate.addMonths(DEFAULT_TARGET_DATE_DURATION);
		treatmentPlanObj.isFirstDraftTreatmentPlan = getIsFirstTreatmentPlan(currentTreatmentPlanId);
		treatmentPlanObj.isFirstEgoOnCurrentTreatmentPlan = getIsFirstEgoOnCurrentTreatmentPlan(currentTreatmentPlanId);

		// Viewing Current Treatment Plan
		treatmentPlanObj.patientId = treatmentPlanObj.currentTreatmentPlan.AccountId;
		treatmentPlanObj.patientName = treatmentPlanObj.currentTreatmentPlan.Account.Name;
		try {
			Case unfinalizedDraftTreatmentPlan = [SELECT Id FROM Case WHERE EGO__c != NULL AND EGO__r.Current_Treatment_Plan__c = :currentTreatmentPlanId AND Status NOT IN ('Active', 'Finalized', 'Inactive') ORDER BY CreatedDate DESC LIMIT 1];
			treatmentPlanObj.unfinalizedDraftTreatmentPlanId = unfinalizedDraftTreatmentPlan.Id;
		} catch (QueryException qe) {
			//exception would be no rows for query
			system.debug(qe.getMessage());
		}

		//JNTODO: deal with this elsewhere
		//egoquery 7
		List<EGO__c> egoList = [
			SELECT Id, Admission__c, Completed_By__c, Draft_Treatment_Plan__c, Draft_Treatment_Plan__r.Status, Current_Treatment_Plan__c, Status__c, Print_Link__c
			//,Date__c
			FROM EGO__c
			WHERE Current_Treatment_Plan__c = :currentTreatmentPlanId
			ORDER BY CreatedDate DESC
		];

		if (egoList != null && !egoList.isEmpty()) {
			if (egoList.size() > 1) {
				treatmentPlanObj.isEGOR = true;
			} else if (egoList.size() == 1) {
				if (egoList[0].Status__c == 'Finalized') {
					treatmentPlanObj.isEGOR = true;
				}
			}
		}

		return treatmentPlanObj;
	}
	/**
	 * #1 - Clean out all record IDs before inserting, always save it as new records
	 * #2 - Copy New Target Date to the Target Date field in Goal and Objective before inserting new records.
	 * #3 - Only save ratings when there are ratings in Goal and Objective
	 */

	public static String saveDraftEGO(TreatmentPlan treatmentPlan) {
		/**
		 * May 19, 2021 : Dave Avery : We were experiencing a platform issue on save of an EGO-R. When the EGOActionEvent was fired
		 * it was still registering the last version of the TreatmentPlan_EGO.cmp in the local cache for the previous EGO. This caused
		 * two instances of the handler to call this method, one for the current, correct, EGO and another for the previous EGO which we
		 * definitely don't want to save again. The check below ensures only the latest EGO get's updated. The downside of this approach
		 * is users will never be able to edit a previous EGO using the components. They could via the page layout though; this is probably
		 * how they would do it anyway if needed.
		 */
		Id accountId = Id.valueOf(treatmentPlan.currentTreatmentPlan.AccountId);
		//egoquery 8
		EGO__c latestEGO = [SELECT Id FROM EGO__c WHERE Admission__c IN (SELECT Current_Admission__c FROM Account WHERE Id = :accountId) ORDER BY CreatedDate DESC LIMIT 1];

		if (null != treatmentPlan.ego && latestEGO.Id != Id.valueOf(treatmentPlan.ego.Id)) {
			return 'SKIPPED';
		}

		String retval = 'SUCCESS';
		Map<String, String> errorMap = new Map<String, String>();
		System.SavePoint sp = Database.setSavepoint();
		try {
			treatmentPlan.ego.Admission__c = treatmentPlan.currentTreatmentPlan.Admission__c;
			treatmentPlan.ego.Completed_By__c = currentUserId;
			treatmentPlan.ego.Date__c = todayDate;
			treatmentPlan.ego.Status__c = 'Draft';
			update treatmentPlan.ego;

			List<Goal> allGoalList = new List<Goal>();
			List<Objective> allObjectiveList = new List<Objective>();
			List<Goal__c> upsertGoalList = new List<Goal__c>();
			List<Objective__c> upsertObjectiveList = new List<Objective__c>();
			List<Goal__c> deleteGoalList = new List<Goal__c>();
			List<Objective__c> deleteObjectiveList = new List<Objective__c>();
			List<EGO_Rating__c> upsertEGORatingList = new List<EGO_Rating__c>();
			List<EGO_Rating__c> deleteEgoRatingList = new List<EGO_Rating__c>();

			map<id, Domain__mdt> domainMap = new Map<id, Domain__mdt>([SELECT Id, Label__c, Domain_Number__c FROM Domain__mdt]);
			set<id> goalIds = new Set<id>();
			for (Domain domainObj : treatmentPlan.domains) {
				//domainMap.put(domainObj.domainObj.Id, domainObj.domainObj);
				for (RatingItem rItem : domainObj.ratingItems) {
					rItem.ratingItem.EGO__c = treatmentPlan.ego.Id;

					upsertEGORatingList.add(rItem.ratingItem);
				}

				for (Goal goalObj : domainObj.goals) {
					if (goalObj.isDeleted) {
						if (String.isNotBlank(goalObj.goalObj.Id)) {
							deleteGoalList.add(goalObj.goalObj);
						}
						if (goalObj.ratingItem != null && goalObj.ratingItem.ratingItem != null && String.isNotBlank(goalObj.ratingItem.ratingItem.Id)) {
							deleteEgoRatingList.add(goalObj.ratingItem.ratingItem);
						}
						if (goalObj.objectives != null) {
							for (Objective objectiveObj : goalObj.objectives) {
								if (String.isNotBlank(objectiveObj.objectiveObj.Id)) {
									deleteObjectiveList.add(ObjectiveObj.objectiveObj);
								}
								if (objectiveObj.ratingItem != null && objectiveObj.ratingItem.ratingItem != null && String.isNotBlank(objectiveObj.ratingItem.ratingItem.Id)) {
									deleteEgoRatingList.add(objectiveObj.ratingItem.ratingItem);
								}
							}
						}
					} else {
						goalIds.add(treatmentPlan.ego.Id);
						goalObj.goalObj.Ego__c = treatmentPlan.ego.Id;
						goalObj.goalObj.Domain_Name__c = domainObj.domainObj.Label__c;
						goalObj.goalObj.Domain_Number__c = domainObj.domainObj.Domain_Number__c;
						goalObj.goalObj.Domain_Metadata_ID__c = domainObj.domainObj.Id;
						goalObj.goalObj.Target_Date__c = goalObj.newTargetDate;
						goalObj.goalObj.Status__c = 'Continue Goal';
						allGoalList.add(goalObj);
						upsertGoalList.add(goalObj.goalObj);
					}
				}
			}
			if (upsertGoalList != null && !upsertGoalList.isEmpty()) {
				upsert upsertGoalList;

				Integer totalGoals = allGoalList.size();
				for (Integer index = 0; index < totalGoals; index++) {
					Goal__c goalObj = upsertGoalList.get(index);
					Goal goal = allGoalList.get(index);
					if (!goal.isDeleted) {
						goalIds.add(goal.goalObj.Id);
						Domain__mdt domainObj = domainMap.get(goal.goalObj.Domain_Metadata_ID__c);
						if (String.isNotBlank(goal.rating)) {
							if (goal.ratingItem != null && goal.ratingItem.ratingItem != null && String.isNotBlank(goal.ratingItem.ratingItem.Id)) {
								goal.ratingItem.ratingItem.Comments__c = goal.comments;
								goal.ratingItem.ratingItem.EGO__c = treatmentPlan.ego.Id;
								goal.ratingItem.ratingItem.Label__c = goal.goalObj.Label__c;
								goal.ratingItem.ratingItem.Goal__c = goalObj.Id;
								goal.ratingItem.ratingItem.Rating__c = goal.rating;
								goal.ratingItem.ratingItem.Type__c = 'Goal';
								goal.ratingItem.ratingItem.Domain_Number__c = domainObj.Domain_Number__c;
								goal.ratingItem.ratingItem.Domain_Name__c = domainObj.Label__C;
								upsertEGORatingList.add(goal.ratingItem.ratingItem);
							} else {
								EGO_Rating__c goalRating = new EGO_Rating__c(Comments__c = goal.comments, EGO__c = treatmentPlan.ego.Id, Label__c = goal.goalObj.Label__c, Goal__c = goalObj.Id, Rating__c = goal.rating, Order__c = goal.goalObj.Order__c, Domain_Number__c = domainObj.Domain_Number__c, Domain_Name__c = domainObj.Label__C, Type__c = 'Goal');
								upsertEGORatingList.add(goalRating);
							}
						}
						for (Objective objectiveObj : goal.objectives) {
							if (objectiveObj.isDeleted) {
								if (String.isNotBlank(objectiveObj.objectiveObj.Id)) {
									deleteObjectiveList.add(ObjectiveObj.objectiveObj);
								}
								if (objectiveObj.ratingItem != null && objectiveObj.ratingItem.ratingItem != null && String.isNotBlank(objectiveObj.ratingItem.ratingItem.Id)) {
									deleteEgoRatingList.add(objectiveObj.ratingItem.ratingItem);
								}
							} else {
								goalIds.add(goalObj.Id);
								objectiveObj.objectiveObj.Goal__c = goalObj.Id;
								objectiveObj.objectiveObj.Target_Date__c = objectiveObj.newTargetDate;
								objectiveObj.objectiveObj.Status__c = 'Continue';
								allObjectiveList.add(objectiveObj);
								upsertObjectiveList.add(objectiveObj.objectiveObj);
							}
						}
					}
				}
			}

			map<id, Goal__c> goalMap = new Map<id, Goal__c>([SELECT Id, Domain_Metadata_ID__c FROM Goal__c WHERE Id IN :goalIds]);

			if (upsertObjectiveList != null && !upsertObjectiveList.isEmpty()) {
				upsert upsertObjectiveList;

				Integer totalObjectives = allObjectiveList.size();
				for (Integer index = 0; index < totalObjectives; index++) {
					Objective__c objectiveObj = upsertObjectiveList.get(index);
					Objective objective = allObjectiveList.get(index);
					if (String.isNotBlank(objective.rating)) {
						Domain__mdt domainObj = domainMap.get(goalMap.get(objective.objectiveObj.Goal__c).Domain_Metadata_ID__c);

						//could be: if (objective?.ratingItem?.ratingItem?.Id != null)
						if (objective.ratingItem != null && objective.ratingItem.ratingItem != null && String.isNotBlank(objective.ratingItem.ratingItem.Id)) {
							objective.ratingItem.ratingItem.Comments__c = objective.comments;
							objective.ratingItem.ratingItem.EGO__c = treatmentPlan.ego.Id;
							objective.ratingItem.ratingItem.Label__c = objective.objectiveObj.Label__c;
							objective.ratingItem.ratingItem.Objective__c = objectiveObj.Id;
							objective.ratingItem.ratingItem.Rating__c = objective.rating;
							objective.ratingItem.ratingItem.Type__c = 'Objective';
							objective.ratingItem.ratingItem.Domain_Number__c = domainObj.Domain_Number__c;
							objective.ratingItem.ratingItem.Domain_Name__c = domainObj.Label__c;
							upsertEGORatingList.add(objective.ratingItem.ratingItem);
						} else {
							EGO_Rating__c objectiveRating = new EGO_Rating__c(Comments__c = objective.comments, EGO__c = treatmentPlan.ego.Id, Label__c = objective.objectiveObj.Label__c, Objective__c = objectiveObj.Id, Rating__c = objective.rating, Domain_Number__c = domainObj.Domain_Number__c, Domain_Name__c = domainObj.Label__c, Type__c = 'Objective');
							upsertEGORatingList.add(objectiveRating);
						}
					}
				}
			}
			delete deleteGoalList;
			delete deleteObjectiveList;
			delete deleteEgoRatingList;
			upsert upsertEGORatingList;
		} catch (Exception e) {
			system.debug(e.getMessage());
			system.debug(e.getStackTraceString());
			Database.rollback(sp);
			ProcessLogging.quickProcessLog('TreatmentPlan.saveDraftEGO()', e.getStackTraceString(), e.getMessage());
			errorMap.put(e.getMessage(), e.getStackTraceString());
		}
		if (!errorMap.isEmpty()) {
			retval = JSON.serialize(errorMap);
		}
		return retval;
	}
	/**
	 * ARC-894, method is being reused for creating Draft Treatment Plan.  Ultimate this method name
	 * should be changed to be more generic.
	 *
	 * #1 - Clean out all record IDs before inserting, always save it as new records
	 * #2 - Copy New Target Date to the Target Date field in Goal and Objective before inserting new records.
	 * #3 - Only save ratings when there are ratings in Goal and Objective
	 */
	public static String finalizeEGOToDraftTreatmentPlan(TreatmentPlan treatmentPlan) {
		/**
		 * May 19, 2021 : Dave Avery : We were experiencing a platform issue on finalize of an EGO-R. When the EGOActionEvent was fired
		 * it was still registering the last version of the TreatmentPlan_EGO.cmp in the local cache for the previous EGO. This caused
		 * two instances of the handler to call this method, one for the current, correct, EGO and another for the previous EGO which we
		 * definitely don't want to finalize again. The check below ensures only the latest EGO get's updated. The downside of this approach
		 * is users will never be able to edit a previous EGO using the components. They could via the page layout though; this is probably
		 * how they would do it anyway if needed.
		 */
		Id accountId = Id.valueOf(treatmentPlan.currentTreatmentPlan.AccountId);
		//egoquery 9
		EGO__c latestEGO = [SELECT Id FROM EGO__c WHERE Admission__c IN (SELECT Current_Admission__c FROM Account WHERE Id = :accountId) ORDER BY CreatedDate DESC LIMIT 1];
		if (null != treatmentPlan.ego && latestEGO.Id != Id.valueOf(treatmentPlan.ego.Id)) {
			return '{"status":"SKIPPED","draftTreatmentPlanId":"{TreatmentPlanId}","currentTreatmentPlanId":"' + treatmentPlan.currentTreatmentPlan.Id + '"}';
		}

		if (null != treatmentPlan.ego) {
			saveDraftEGO(treatmentPlan);
		}

		String retval = '{"status":"SUCCESS","draftTreatmentPlanId":"{TreatmentPlanId}","currentTreatmentPlanId":"' + treatmentPlan.currentTreatmentPlan.Id + '"}';

		Map<String, String> errorMap = new Map<String, String>();
		System.SavePoint sp = Database.setSavepoint();
		try {
			Map<Id, Domain__mdt> domainMap = new Map<Id, Domain__mdt>(queryDomainList());

			Set<id> goalIds = new Set<id>();

			Case draftTreatmentPlan = new Case(AccountId = treatmentPlan.currentTreatmentPlan.AccountId, Admission__c = treatmentPlan.currentTreatmentPlan.Admission__c, Status = 'Draft');
			if (treatmentPlan.ego != null) {
				draftTreatmentPlan.EGO__c = treatmentPlan.ego.Id;
				draftTreatmentPlan.Goal__c = treatmentPlan.ego.Overall_Goal__c;
			} else {
				draftTreatmentPlan.Goal__c = treatmentPlan.currentTreatmentPlan.Goal__c;
			}
			insert draftTreatmentPlan;

			User thisUser = [SELECT Id, Name, Professional_Name__c FROM User WHERE Id = :currentUserId];
			String userProfessionalName = thisUser.Professional_Name__c;

			if (treatmentPlan.ego != null) {
				treatmentPlan.ego.Draft_Treatment_Plan__c = draftTreatmentPlan.Id;
				treatmentPlan.ego.Date__c = todayDate;
				treatmentPlan.ego.Completed_By__c = currentUserId;
				treatmentPlan.ego.Finalized_By_User__c = currentUserId;
				treatmentPlan.ego.Finalized_By__c = userProfessionalName;
				treatmentPlan.ego.Finalized_By_Professional_Name__c = userProfessionalName;
				treatmentPlan.ego.Finalized_Date_Time__c = System.now();
				treatmentPlan.ego.Status__c = 'Finalized';
				update treatmentPlan.ego;
			}
			List<Goal> allGoalList = new List<Goal>();
			List<Objective> allObjectiveList = new List<Objective>();
			List<Goal__c> upsertGoalList = new List<Goal__c>();
			List<Objective__c> upsertObjectiveList = new List<Objective__c>();
			List<EGO_Rating__c> egoRatingList = new List<EGO_Rating__c>();
			for (Domain domainObj : treatmentPlan.domains) {
				//domainMap.put(domainObj.domainObj.Id,domainObj.domainObj);
				if (treatmentPlan.ego != null) {
					for (RatingItem rItem : domainObj.ratingItems) {
						rItem.ratingItem.EGO__c = treatmentPlan.ego.Id;
						egoRatingList.add(rItem.ratingItem);
					}
				}
				for (Goal goal : domainObj.goals) {
					if (!goal.isDeleted) {
						if (String.isBlank(goal.goalObj.Continued_From_Goal__c)) {
							goal.goalObj.Date_Added__c = todayDate;
						}
						goalIds.add(goal.goalObj.Id);
						goal.goalObj.Domain_Name__c = domainObj.domainObj.Label__C;
						//goal.goalObj.Order__C  =domainObj.domainObj.Domain_Number__c;
						goal.goalObj.Domain_Number__c = domainObj.domainObj.Domain_Number__c;
						goal.goalObj.Domain_Metadata_ID__c = domainObj.domainObj.Id;
						goal.goalObj.Draft_Treatment_Plan__c = draftTreatmentPlan.Id;
						goal.goalObj.Target_Date__c = goal.newTargetDate;
						goal.goalObj.Treatment_Plan__c = null;
						goal.goalObj.Status__c = 'Continue Goal';
						allGoalList.add(goal);
						upsertGoalList.add(goal.goalObj);
					}
				}
			}
			if (upsertGoalList != null && !upsertGoalList.isEmpty()) {
				upsert upsertGoalList;
				map<id, Goal__c> goalMap = new Map<id, Goal__c>([SELECT Id, Domain_Metadata_ID__c FROM Goal__c WHERE id IN :goalIds]);
				integer totalGoals = allGoalList.size();
				EGO_Rating__c goalRating;
				for (integer index = 0; index < totalGoals; index++) {
					Goal__c goalObj = upsertGoalList.get(index);
					Goal goal = allGoalList.get(index);
					if (treatmentPlan.ego != null) {
						if (String.isNotBlank(goal.rating)) {
							if (goal.ratingItem != null && goal.ratingItem.ratingItem != null && String.isNotBlank(goal.ratingItem.ratingItem.Id)) {
								goalRating = goal.ratingItem.ratingItem;
							} else {
								goalRating = new EGO_Rating__c(Comments__c = goal.comments, EGO__c = treatmentPlan.ego.Id, Label__c = goalObj.Label__c, Goal__c = goalObj.Id, Rating__c = goal.rating, Type__c = 'Goal');
							}
							egoRatingList.add(goalRating);
						}
					}
					for (Objective objective : goal.objectives) {
						if (!objective.isDeleted && !goal.isDeleted) {
							if (String.isBlank(objective.objectiveObj.Continued_From_Objective__c)) {
								objective.objectiveObj.Date_Added__c = todayDate;
							}
							objective.objectiveObj.Goal__c = goalObj.Id;
							objective.objectiveObj.Target_Date__c = objective.newTargetDate;
							objective.objectiveObj.Status__c = 'Continue';
							allObjectiveList.add(objective);
							upsertObjectiveList.add(objective.objectiveObj);
						}
					}
				}
			}
			if (upsertObjectiveList != null && !upsertObjectiveList.isEmpty()) {
				upsert upsertObjectiveList;
				integer totalObjectives = allObjectiveList.size();
				EGO_Rating__c objectiveRating;
				for (integer index = 0; index < totalObjectives; index++) {
					Objective__c objectiveObj = upsertObjectiveList.get(index);
					Objective objective = allObjectiveList.get(index);
					if (treatmentPlan.ego != null) {
						if (String.isNotBlank(objective.rating)) {
							if (objective.ratingItem != null && objective.ratingItem.ratingItem != null && String.isNotBlank(objective.ratingItem.ratingItem.Id)) {
								objectiveRating = objective.ratingItem.ratingItem;
							} else {
								objectiveRating = new EGO_Rating__c(EGO__c = treatmentPlan.ego.Id, Comments__c = objective.comments, Label__c = objectiveObj.Label__c, Objective__c = objectiveObj.Id, Rating__c = objective.rating, Type__c = 'Objective');
							}
							egoRatingList.add(objectiveRating);
						}
					}
				}
			}
			if (!egoRatingList.isEmpty()) {
				upsert egoRatingList;
			}
			retval = retval.replace('{TreatmentPlanId}', draftTreatmentPlan.Id);

			//CreateSnapshot
			if (treatmentPlan.ego != null) {
				EGOSnapshot.process(new List<id>{ treatmentPlan?.ego?.Id });
			}
		} catch (Exception e) {
			Database.rollback(sp);
			system.debug(e.getMessage());
			system.debug(e.getStackTraceString());
			errorMap.put(e.getMessage(), e.getStackTraceString());
			ProcessLogging.quickProcessLog('TreatmentPlan.finalizeEGOToDraftTreatmentPlan', e.getStackTraceString(), e.getMessage());
		}
		if (!errorMap.isEmpty()) {
			retval = JSON.serialize(errorMap);
		}

		return retval;
	}
}
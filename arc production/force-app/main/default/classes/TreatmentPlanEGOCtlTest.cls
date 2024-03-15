@isTest
private class TreatmentPlanEGOCtlTest {
	@testSetup
	private static void doSetup() {
		AdmissionScreeningControllerTest.setup();
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Case currentCase = new Case(AccountId = patient.Id);
		insert currentCase;
		patient.Current_Case__c = currentCase.Id;
		update patient;

		// Setup Case Team
		User thisUser = [SELECT id FROM user WHERE id = :UserInfo.getUserId()];
		// CaseTeamRole socialWorkerRole;
		// try
		// {
		//     socialWorkerRole=[SELECT Id FROM CaseTeamRole WHERE Name='Clinical Social Worker'];
		// }
		// catch(QueryException qe)
		// {
		//     socialWorkerRole=new CaseTeamRole(AccessLevel='Edit',Name='Clinical Social Worker',PreferencesVisibleInCSP=false);
		//     insert socialWorkerRole;
		// }
		// CaseTeamMember socialWorker=new CaseTeamMember(parentId=currentCase.Id,memberId=UserInfo.getUserId(),TeamRoleId=socialWorkerRole.Id);
		Assigned_Clinician__c socialWorker = new Assigned_Clinician__c(Treatment_Plan__c = currentCase.Id, User__c = UserInfo.getUserId(), Role__c = 'Clinical Social Worker');
		insert socialWorker;

		Domain__mdt domainMdt = [SELECT Id FROM Domain__mdt ORDER BY Domain_Number__c LIMIT 1];
		Goal__c goal = new Goal__c(Name = 'Test Goal', Domain_Metadata_ID__c = domainMdt.Id, Label__c = 'Test Goal Lsbel', Status__c = 'Continue Goal', Target_Date__c = System.today().addMonths(3), Treatment_Plan__c = patient.Current_Case__c);
		insert goal;
		Objective__c objective = new Objective__c(Status__c = 'Continue', Label__c = 'Test Objective', Goal__c = goal.Id, Target_Date__c = System.today().addMonths(3));
		insert objective;

		//Create EGO
		EGO__c eg = new EGO__c();
		eg.Admission__c = [SELECT Id FROM Admission__c LIMIT 1].Id;
		eg.Current_Treatment_Plan__c = [SELECT Id FROM Case LIMIT 1].Id;

		insert eg;

		EGO_Rating__c egr = new EGO_Rating__c();
		egr.Rating__c = '3';

		insert egr;
	}

	/**
	 * Get current TreatmentPlan
	 */
	@isTest
	private static void testGetTreatmentPlanEGO() {
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Test.startTest();
		TreatmentPlanEGOCtl.getTreatmentPlanById(patient.Current_Case__c);
		Test.stopTest();
	}
	/**
	 * Test save draft treatment plan
	 */
	@isTest
	private static void testFinalizeEGOtoTreatmentPlan() {
		Account patient = [SELECT Id, Current_Case__c, Current_Case__r.Subject FROM Account LIMIT 1];
		TreatmentPlan tPlan = TreatmentPlanEGOCtl.getTreatmentPlanById(patient.Current_Case__c);
		tPlan.currentTreatmentPlan.Id = null;
		for (Domain domain : tPlan.domains) {
			for (Goal goal : domain.goals) {
				goal.goalObj.Id = null;
				for (Objective objective : goal.objectives) {
					objective.objectiveObj.Id = null;
				}
			}
		}
		Test.startTest();
		TreatmentPlan newTPlan = TreatmentPlanEGOCtl.conductEGO(patient.Current_Case__c);
		TreatmentPlanEGOCtl.finalizeEGOToDraftTreatmentPlan(newTPlan);
		Test.stopTest();
	}
	/**
	 * Conduct an EGO.
	 */
	@isTest
	private static void testConductEGO() {
		Account patient = [SELECT Id, Current_Case__c, Current_Case__r.Subject FROM Account LIMIT 1];
		TreatmentPlan tPlan = TreatmentPlanEGOCtl.getTreatmentPlanById(patient.Current_Case__c);
		tPlan.currentTreatmentPlan.Id = null;
		for (Domain domain : tPlan.domains) {
			for (Goal goal : domain.goals) {
				goal.goalObj.Id = null;
				for (Objective objective : goal.objectives) {
					objective.objectiveObj.Id = null;
				}
			}
		}
		Test.startTest();
		TreatmentPlan newTPlan = TreatmentPlanEGOCtl.conductEGO(patient.Current_Case__c);
		TreatmentPlanEGOCtl.getTreatmentPlanById(patient.Current_Case__c);
		TreatmentPlanEGOCtl.saveDraftEGO(newTPlan);
		List<Goal> goalList = new List<Goal>();
		List<Objective> newObjectiveList = new List<Objective>();
		Objective newObj = new Objective();
		newObj.objectiveObj = new Objective__c();
		newObj.rating = '1';
		newObj.newTargetDate = System.today();
		newObj.isDeleted = false;
		Objective deleteObj = new Objective();
		deleteObj.objectiveObj = new Objective__c();
		deleteObj.rating = '1';
		deleteObj.newTargetDate = System.today();
		deleteObj.isDeleted = true;
		newObjectiveList.add(newObj);
		newObjectiveList.add(deleteObj);
		List<Objective> deleteObjectiveList = new List<Objective>();
		newObj = new Objective();
		newObj.objectiveObj = new Objective__c();
		newObj.rating = '1';
		newObj.newTargetDate = System.today();
		newObj.isDeleted = false;
		deleteObj = new Objective();
		deleteObj.objectiveObj = new Objective__c();
		deleteObj.rating = '1';
		deleteObj.newTargetDate = System.today();
		deleteObj.isDeleted = true;
		deleteObjectiveList.add(newObj);
		deleteObjectiveList.add(deleteObj);
		Goal newGoal = new Goal();
		newGoal.rating = '1';
		newGoal.goalObj = new Goal__c();
		newGoal.goalObj.Domain_Metadata_ID__c = newTPlan.domains[0].domainObj.Id;
		newGoal.goalObj.Label__c = 'New Goal Testing';
		newGoal.isDeleted = false;
		newGoal.objectives = newObjectiveList;
		//Create rating item
		RatingItem ri = new RatingItem();
		ri.ratingItem = [SELECT Id, Comments__c, EGO__c, Label__c, Goal__c, Rating__c, Type__c FROM EGO_Rating__c LIMIT 1];
		newGoal.ratingItem = ri;

		Goal deleteGoal = new Goal();
		deleteGoal.rating = '1';
		deleteGoal.goalObj = new Goal__c();
		deleteGoal.goalObj.Domain_Metadata_ID__c = newTPlan.domains[0].domainObj.Id;
		deleteGoal.goalObj.Label__c = 'Delete Goal Testing';
		deleteGoal.isDeleted = true;
		deleteGoal.objectives = deleteObjectiveList;
		goalList.add(newGoal);
		goalList.add(deleteGoal);
		newTPlan.domains[0].goals = goalList;
		TreatmentPlanEGOCtl.saveDraftEGO(newTPlan);
		for (Goal goal : newTPlan.domains[0].goals) {
			goal.rating = '1';
			if (goal.objectives != null) {
				for (Objective obj : goal.objectives) {
					obj.rating = '1';
				}
			}
		}
		TreatmentPlanEGOCtl.saveDraftEGO(newTPlan);
		newTPlan = TreatmentPlanEGOCtl.conductEGO(patient.Current_Case__c);
		Test.stopTest();
	}

	// @isTest
	// private static void getCurrentTreatmentPlan() {
	//     Account patient = [SELECT Id FROM Account LIMIT 1];
	//     Test.startTest();
	//     TreatmentPlan tp = TreatmentPlan.getCurrentTreatmentPlan(patient.Id);
	//     Test.stopTest();

	//     System.assert( tp != null);
	// }

	@isTest
	private static void getTreatmentPlanByEGOId() {
		EGO__c eg = [SELECT Id FROM EGO__c LIMIT 1];
		Test.startTest();
		TreatmentPlan tp = TreatmentPlan.getTreatmentPlanByEGOId(eg.Id);
		Test.stopTest();

		System.assert(tp != null);
	}
}
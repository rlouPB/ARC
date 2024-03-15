@isTest
private class NoteViewTreatmentPlanCtlTest {
	@testSetup
	private static void doSetup() {
		AdmissionScreeningControllerTest.setup();
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Admission__c admission = [SELECT Id, Team__c FROM Admission__c WHERE Patient_Account__c = :patient.Id LIMIT 1];
		Case currentCase = new Case(AccountId = patient.Id, Admission__c = admission.Id);
		insert currentCase;
		patient.Current_Case__c = currentCase.Id;
		update patient;
		admission.Team__c = 'A';
		update admission;

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

		// Setup Team A
		//Staff_Group_Member__c teamLeader=[SELECT Staff_Member__c,Staff_Member__r.Name FROM Staff_Group_Member__c WHERE Group_Name__r.Name=:teamName AND Role__c='Team Leader' AND (Planned_End_Date__c=NULL OR (Planned_End_Date__c!=NULL AND Planned_End_Date__c>TODAY)) LIMIT 1];
		//Group__c teamGroup=new Group__c(Active__c=true,Type__c='Team');

		Domain__mdt domainMdt = [SELECT Id FROM Domain__mdt ORDER BY Domain_Number__c LIMIT 1];
		Goal__c goal = new Goal__c(Name = 'Test Goal', Domain_Metadata_ID__c = domainMdt.Id, Label__c = 'Test Goal Lsbel', Status__c = 'Continue Goal', Target_Date__c = System.today().addMonths(3), Treatment_Plan__c = patient.Current_Case__c);
		insert goal;
		Objective__c objective = new Objective__c(Status__c = 'Continue', Label__c = 'Test Objective', Goal__c = goal.Id, Target_Date__c = System.today().addMonths(3));
		insert objective;

		ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();
	}

	@isTest
	private static void viewTreatmentPlan() {
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		Test.startTest();
		TreatmentPlan tPlan = TreatmentPlanEGOCtl.conductEGO(patient.Current_Case__c);
		String savedDraftEGOString = TreatmentPlanEGOCtl.saveDraftEGO(tPlan);
		String finalizedEGOString = TreatmentPlanEGOCtl.finalizeEGOToDraftTreatmentPlan(tPlan);

		Case draftTreatmentPlan = [SELECT Id, Admission__c FROM Case WHERE AccountId = :patient.Id AND Status = 'Draft' LIMIT 1];

		// Get Draft Treatment Plan
		tPlan = ViewTreatmentPlanCtl.getTreatmentPlan(draftTreatmentPlan.Id);

		// Save Draft Treatment Plan
		Domain__mdt domainMdt = [SELECT Id FROM Domain__mdt ORDER BY Domain_Number__c LIMIT 1];

		Objective objectiveObj = new Objective();
		objectiveObj.objectiveObj = new Objective__c(Status__c = 'Continue', Label__c = 'Test Objective', Target_Date__c = System.today().addMonths(3));
		objectiveObj.newTargetDate = System.today().addMonths(3);
		objectiveObj.status = 'Continue';

		Goal goalObj = new Goal();
		goalObj.goalObj = new Goal__c(Name = 'Test Goal', Label__c = 'Test Goal Lsbel', Status__c = 'Continue Goal', Target_Date__c = System.today().addMonths(3), Treatment_Plan__c = patient.Current_Case__c);
		goalObj.newTargetDate = System.today().addMonths(3);
		goalObj.status = 'Continue Goal';
		goalObj.objectives = new List<Objective>();
		goalObj.objectives.add(objectiveObj);

		tPlan.domains.get(0).goals.add(goalObj);

		String treatmentPlanString = ViewTreatmentPlanCtl.saveTreatmentPlan(JSON.serialize(tPlan));

		// Finalize Treatment Plan
		tPlan = ViewTreatmentPlanCtl.getTreatmentPlan(draftTreatmentPlan.Id);

		objectiveObj = new Objective();
		objectiveObj.objectiveObj = new Objective__c(Status__c = 'Continue', Label__c = 'Test Objective', Target_Date__c = System.today().addMonths(3));
		objectiveObj.newTargetDate = System.today().addMonths(3);
		objectiveObj.status = 'Continue';

		goalObj = new Goal();
		goalObj.goalObj = new Goal__c(Name = 'Test Goal', Label__c = 'Test Goal Lsbel', Status__c = 'Continue Goal', Target_Date__c = System.today().addMonths(3), Treatment_Plan__c = patient.Current_Case__c);
		goalObj.newTargetDate = System.today().addMonths(3);
		goalObj.status = 'Continue Goal';
		goalObj.objectives = new List<Objective>();
		goalObj.objectives.add(objectiveObj);

		tPlan.domains.get(0).goals.add(goalObj);

		Goal metGoal = tPlan.domains.get(0).goals.get(0);
		metGoal.status = 'Goal Met';
		metGoal.goalObj.Status__c = 'Goal Met';
		Objective metObjective = metGoal.objectives.get(0);
		metObjective.status = 'Met';
		metObjective.objectiveObj.Status__c = 'Met';

		treatmentPlanString = ViewTreatmentPlanCtl.finalizeTreatmentPlan(JSON.serialize(tPlan));
		String patientId = patient.Id;
		patient = [SELECT Id, Current_Case__c FROM Account WHERE Id = :patientId];
		/*
        List<Case> caseList = [SELECT Id,casenumber,Status FROM Case WHERE AccountId =: patientId];
        Case currentTreatmentPlan = [SELECT Id FROM Case WHERE Status = 'Active' AND AccountId =: patientId LIMIT 1];
*/
		NoteViewTreatmentPlanCtl.getTreatmentPlan(patient.Current_Case__c);
		Test.stopTest();
	}
}
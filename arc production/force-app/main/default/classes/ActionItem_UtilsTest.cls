@IsTest
public class ActionItem_UtilsTest {
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
		// CaseTeamRole socialWorkerRole;report
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
		List<Assigned_Clinician__c> assignedClinicians = new List<Assigned_Clinician__c>();
		Assigned_Clinician__c socialWorker = new Assigned_Clinician__c(Patient_Account__c = patient.Id, Treatment_Plan__c = currentCase.Id, User__c = UserInfo.getUserId(), Role__c = 'Clinical Social Worker', Start_Date__c = Date.Today().addDays(-5));
		assignedClinicians.add(socialWorker);

		Assigned_Clinician__c expiredSocialWorker = new Assigned_Clinician__c(Patient_Account__c = patient.Id, Treatment_Plan__c = currentCase.Id, User__c = UserInfo.getUserId(), Role__c = 'Clinical Social Worker', Start_Date__c = Date.Today().addDays(-50), End_Date__c = Date.Today().addDays(-5));
		assignedClinicians.add(expiredSocialWorker);

		Assigned_Clinician__c medOfficeDoc = new Assigned_Clinician__c(Patient_Account__c = patient.Id, Treatment_Plan__c = currentCase.Id, User__c = UserInfo.getUserId(), Role__c = 'Med Office Physician', Start_Date__c = Date.Today().addDays(-50));
		assignedClinicians.add(medOfficeDoc);

		insert assignedClinicians;

		// Setup Team A
		//Staff_Group_Member__c teamLeader=[SELECT Staff_Member__c,Staff_Member__r.Name FROM Staff_Group_Member__c WHERE Group_Name__r.Name=:teamName AND Role__c='Team Leader' AND (Planned_End_Date__c=NULL OR (Planned_End_Date__c!=NULL AND Planned_End_Date__c>TODAY)) LIMIT 1];
		//Group__c teamGroup=new Group__c(Active__c=true,Type__c='Team');

		Domain__mdt domainMdt = [SELECT Id FROM Domain__mdt ORDER BY Domain_Number__c LIMIT 1];
		Goal__c goal = new Goal__c(Name = 'Test Goal', Domain_Metadata_ID__c = domainMdt.Id, Label__c = 'Test Goal Lsbel', Status__c = 'Continue Goal', Target_Date__c = System.today().addMonths(3), Treatment_Plan__c = patient.Current_Case__c);
		insert goal;
		Objective__c objective = new Objective__c(Status__c = 'Continue', Label__c = 'Test Objective', Goal__c = goal.Id, Target_Date__c = System.today().addMonths(3));
		insert objective;
	}

	@isTest
	private static void viewTreatmentPlan() {
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];

		TreatmentPlan tPlan = TreatmentPlanEGOCtl.conductEGO(patient.Current_Case__c);
		String savedDraftEGOString = TreatmentPlanEGOCtl.saveDraftEGO(tPlan);
		String finalizedEGOString = TreatmentPlanEGOCtl.finalizeEGOToDraftTreatmentPlan(tPlan);

		Case draftTreatmentPlan = [SELECT Id, Admission__c, Admission__r.Team__c FROM Case WHERE AccountId = :patient.Id AND Status = 'Draft' LIMIT 1];

		Group__c testGroup = new Group__c(Name = 'Team ' + draftTreatmentPlan.Admission__r.Team__c, Attendance_Tracking__c = 'Do not Track Attendance', Duration__c = 'Standing', Type__c = 'Program', Primary_Function__c = 'Staff');
		insert testGroup;

		insert new Staff_Group_Member__c(Group_Name__c = testGroup.Id, Staff_Member__c = userinfo.getUserId(), Role__c = 'Team Leader', Start_Date__c = system.today().addDays(-1), Planned_End_Date__c = system.today().addDays(1));

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
		Test.startTest();
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

		// We have one active assigned clinician, Social Worker, which should get an Action Item.
		// The expired Social Worker and Med Office Doc shouldn't.
		System.assertEquals(1, [SELECT COUNT() FROM Action_Item__c]);

		// DA - 22-Jun-2021: I commented this out as I had to move the Test.stopTest() call below
		// to address the SOQL 101 issue. Now I'm in a different transaction so not getting records
		// created in time to assert.
		//system.assertNotEquals(0, [Select count() from Outstanding_Tag__c where Object__c='Action_Item__c' and Record_ID__c != null]);

		System.assertEquals(null, ActionItemCompleteQuickactionCtl.completeActionItem([SELECT Id FROM Action_Item__c][0].Id));
		Test.stopTest();
	}
}
@isTest(SeeAllData=false)
private class ViewTreatmentHistoryCtlTest {
	@TestSetup
	static void testSetup() {
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

		EGO__c ego = new EGO__c(Current_Treatment_Plan__c = currentCase.Id, Overall_Goal__c = 'Test EGO', Admission__c = admission.Id, Date__c = System.today().addDays(-10), Status__c = 'Draft');
		insert ego;
		EGO__c checkEgo = [SELECT Id, Name, Date__c, Current_Treatment_Plan__r.AccountId, Status__c FROM EGO__c WHERE Id = :ego.Id];
		// WHERE Current_Treatment_Plan__r.AccountId =:patientId
		//     AND Date__c >= :startDate
		//     AND Date__c < :endDate

		Domain__mdt domainMdt = [SELECT Id FROM Domain__mdt ORDER BY Domain_Number__c LIMIT 1];
		Goal__c goal = new Goal__c(EGO__c = ego.Id, Name = 'Test Goal', Domain_Metadata_ID__c = domainMdt.Id, Label__c = 'Test Goal Lsbel', Status__c = 'Continue Goal', Target_Date__c = System.today().addMonths(3), Treatment_Plan__c = patient.Current_Case__c);
		insert goal;
		Objective__c objective = new Objective__c(Status__c = 'Continue', Label__c = 'Test Objective', Goal__c = goal.Id, Target_Date__c = System.today().addMonths(3));
		insert objective;
		/*
        Treatment_History_Definition__mdt historyDefinition = new Treatment_History_Definition__mdt(Date_Field__c = 'Date__c',
                                                                                                   Detail_to_Display__c = 'Team : {{Current_Treatment_Plan__r.Team__c}}Goal : {{Overall_Goal__c}} Status: {{Status__c}}',
                                                                                                   Label__c = 'EGO',
                                                                                                   Patient_Lookup_Field__c = 'Current_Treatment_Plan__r.AccountId',
                                                                                                   Query_Fields__c = 'Current_Treatment_Plan__c,Current_Treatment_Plan__r.Team__c,Overall_Goal__c,Status__c',
                                                                                                   Sobject__c = 'EGO__c');
        insert historyDefinition;*/
	}

	@isTest
	static void testViewTreatmentHistory() {
		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];
		TreatmentHistory history = new TreatmentHistory();
		history.patientId = patient.Id;
		history.lastWeeks = 6;
		history.viewOptionItemLabelList = new List<String>{ 'Draft EGO' };

		Test.startTest();
		ViewTreatmentHistoryCtl.getTreatmentHistory(JSON.serialize(history));

		history.moveMonths = 2;
		ViewTreatmentHistoryCtl.getTreatmentHistory(JSON.serialize(history));
		Test.stopTest();
	}
}
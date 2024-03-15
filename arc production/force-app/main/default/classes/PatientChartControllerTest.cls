@isTest
private class PatientChartControllerTest {
	@testSetup
	static void initiateData() {
		AdmissionScreeningControllerTest.setup();

		Account patient = [SELECT Id, Name, Current_Case__c FROM Account LIMIT 1];

		Schema.RecordTypeInfo userParticipantRecordTypeInfo = Participant__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('User_Participant');
		Schema.DescribeFieldResult patientMeetingTypeResult = Meeting__c.Patient_Meeting_Type__c.getDescribe();
		List<Schema.PicklistEntry> patientMeetingTypePicklist = patientMeetingTypeResult.getPicklistValues();
		Schema.DescribeFieldResult patientAttendanceResult = Meeting__c.Patient_Attendance__c.getDescribe();
		List<Schema.PicklistEntry> patientAttendancePickList = patientAttendanceResult.getPicklistValues();

		List<Participant__c> participantList = new List<Participant__c>();
		List<Meeting__c> meetingList = new List<Meeting__c>();
		Integer patientAttendanceChoice = 0;

		for (Schema.PicklistEntry entry : patientMeetingTypePicklist) {
			if (patientAttendanceChoice > 2) {
				patientAttendanceChoice = 0;
			}
			Meeting__c meeting = new Meeting__c(Subject__c = entry.getLabel(), Start_Date_Time__c = system.now(), End_Date_Time__c = system.now().addHours(1), Patient_Account__c = patient.Id, Patient_Attendance__c = patientAttendancePickList[patientAttendanceChoice].getLabel(), Patient_Meeting_Type__c = entry.getLabel());
			meetingList.add(meeting);
			patientAttendanceChoice++;
		}

		Meeting__c tomorrowMeeting = new Meeting__c(Subject__c = patientMeetingTypePicklist[0].getLabel(), Start_Date_Time__c = system.now().addDays(1), End_Date_Time__c = system.now().addDays(1).addHours(1), Patient_Account__c = patient.Id, Patient_Attendance__c = patientAttendancePickList[0].getLabel(), Patient_Meeting_Type__c = patientMeetingTypePicklist[0].getLabel());
		meetingList.add(tomorrowMeeting);
		insert meetingList;

		for (Meeting__c meeting : meetingList) {
			Participant__c participant = new Participant__c(RecordTypeId = userParticipantRecordTypeInfo.getRecordTypeId(), Meeting__c = meeting.Id, User__c = UserInfo.getUserId());
			participantList.add(participant);
		}

		insert participantList;

		Datetime reportingDate = Datetime.now();
		List<Physical_Monitor__c> physicalMonitors = new List<Physical_Monitor__c>();

		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 150, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-180);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 160, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-160);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 170, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-140);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 180, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-120);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 170, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-100);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 160, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-80);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 150, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-60);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 140, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-40);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 150, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		reportingDate = Datetime.now().addDays(-20);
		physicalMonitors.add(new Physical_Monitor__c(Weight_lbs__c = 140, Height_in__c = 80, BP_Cuff_Size__c = 'Large', Status__c = 'Finalized', Account__c = patient.Id, Performed_Date_Time__c = reportingDate));
		insert physicalMonitors;
	}

	@isTest
	static void TestChartMetricData1() {
		Account account = [SELECT Id, Name, RecordTypeId FROM Account LIMIT 1];

		System.Test.startTest();
		List<Object> monitors = PatientChartController.getChartMetricData('Physical_Monitor__c', 'Weight_lbs__c', null, null, null, 'Account__c', '2022-11-01', 'Reporting_Date__c', account.Id);
		List<Object> monitors2 = PatientChartController.getChartMetricData('Physical_Monitor__c', 'Weight_lbs__c', 'Weight_kg__c', null, null, 'Account__c', '2022-11-01', 'Reporting_Date__c', account.Id);
		System.Test.stopTest();
	}

	@isTest
	static void TestChartMetricData2() {
		Account account = [SELECT Id, Name, RecordTypeId FROM Account LIMIT 1];

		System.Test.startTest();
		List<Object> monitors = PatientChartController.getChartMetricData('Physical_Monitor__c', 'Weight_lbs__c', 'Weight_kg__c', 'Height_in__c', null, 'Account__c', '2022-11-01', 'Reporting_Date__c', account.Id);
		Physical_Monitor__c physicalMonitor = [SELECT Id, Name, Account__c FROM Physical_Monitor__c LIMIT 1];
		String accountId = PatientChartController.getAccountId(physicalMonitor.Id, 'Account__c');
		List<Object> monitors2 = PatientChartController.getChartMetricData('Physical_Monitor__c', 'Weight_lbs__c', 'Weight_kg__c', 'Height_in__c', 'Height_cm__c', 'Account__c', null, 'Reporting_Date__c', account.Id);
		String label = PatientChartController.getFieldLabel('Physical_Monitor__c', 'Weight_lbs__c');
		List<String> labels = PatientChartController.getFieldLabels('Physical_Monitor__c', 'Weight_lbs__c', 'Weight_kg__c', 'Height_in__c', 'Height_cm__c');
		System.Test.stopTest();
	}

	@isTest
	static void TestChartAggregateData() {
		Account account = [SELECT Id, Name, RecordTypeId FROM Account LIMIT 1];

		System.Test.startTest();
		List<PatientChartController.ObjectWrapper> aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'This Year', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'This Quarter', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'This Month', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'Last Year', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'Last Quarter', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'Last Month', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'Last 6 Months', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', 'Last 12 Months', 'Start_Date_Time__c', 'true', account.Id);
		aggregates = PatientChartController.getAggregateChartData('Meeting__c', 'Patient_Attendance__c', 'Patient_Account__c', null, 'Start_Date_Time__c', 'true', account.Id);
		System.Test.stopTest();
	}
}
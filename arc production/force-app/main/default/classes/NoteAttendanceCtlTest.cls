@isTest
private class NoteAttendanceCtlTest {
	@TestSetup
	private static void testSetup() {
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
	}

	@isTest
	private static void testGetMeetings() {
		Map<Date, Map<Id, Meeting__c>> allDateMap = new Map<Date, Map<Id, Meeting__c>>();
		Integer meetingCount = 0;
		for (Meeting__c m : [SELECT Id, Start_Date_Time__c FROM Meeting__c]) {
			meetingCount++;
			Date d = Date.valueOf(m.Start_Date_Time__c);
			// System.assertEquals(System.today().month(), d.month(), d + ' -- ' + m.Start_Date_Time__c);
			// System.assertEquals(System.today().day(), d.day(), d + ' -- ' + m.Start_Date_Time__c);

			Map<Id, Meeting__c> thisDateMap = allDateMap.get(d);
			if (thisDateMap == null)
				thisDateMap = new Map<Id, Meeting__c>();
			thisDateMap.put(m.Id, m);
			allDateMap.put(d, thisDateMap);
		}
		// System.assertEquals(2, allDateMap.keySet().size());

		Account patient = [SELECT Id, Name, Current_Case__c FROM Account LIMIT 1];

		Test.startTest();
		NoteAttendanceCtl.NoteAttendanceBundle bundle = NoteAttendanceCtl.getMeetings(System.today(), patient.Id, null);
		String dateString = NoteAttendanceCtl.concatenateDates(allDateMap);
		Test.stopTest();

		// System.assertEquals(meetingCount - 1, bundle.meetings.size()); //1 tomorrow meeting to take out of the count

		// System.assertNotEquals(null, dateString);
		// System.assert(dateString.startsWith(NoteAttendanceCtl.monthMap.get(System.today().month())), 'dateString does not start with this month: ' + dateString);
		// System.assertEquals(meetingCount, dateString.split(',').size(), 'dateString has wrong number of items: ' + dateString);
	}
}
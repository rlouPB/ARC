@isTest
private class RecurringMeetingsTest {
	@isTest
	static void createRecurringMeetingsEveryTuAndWedEndByTwoWeeks() {
		Date today = System.today();
		Date weekStart = today.toStartOfWeek();
		Date tuesdayDate = weekStart.addDays(9);
		System.assertEquals('Tuesday', DateUtils.getDayOfWeek(tuesdayDate));

		// Create a Recurrence for every Tuesday and Wednesday
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Weekly';
		recurrence.Recur_every__c = 1;
		recurrence.Weekdays__c = 'Tuesday;Wednesday';
		recurrence.Start_Date__c = tuesdayDate;
		recurrence.End_Type__c = 'End By Date';
		recurrence.End_By__c = tuesdayDate.addDays(14);

		insert recurrence;

		// Create a Meeting for a Tuesday at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(tuesdayDate, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(tuesdayDate, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		insert participant1;

		List<Participant__c> participantList = [SELECT Id, Meeting__c FROM Participant__c];
		System.assertEquals(1, participantList.size());

		Test.startTest();

		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = false;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c, (SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participants__r) FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(4, meetingList.size(), meetingList);

		// Validate that the dates for the created Meetings are only Tuesday and Wednesday
		for (Meeting__c currentMeeting : meetingList) {
			String dayOfWeek = DateUtils.getDayOfWeek(currentMeeting.Start_Date_Time__c.dateGMT());
			System.assertEquals(true, dayOfWeek == 'Tuesday' || dayOfWeek == 'Wednesday');
		}

		// Validate that each Meeting has the correct participant
		for (Meeting__c currentMeeting : meetingList) {
			System.assertEquals(1, currentMeeting.Participants__r.size());
			System.assertEquals(participant1.RecordTypeId, currentMeeting.Participants__r[0].RecordTypeId);
			System.assertEquals(participant1.Group__c, currentMeeting.Participants__r[0].Group__c);
			System.assertEquals(currentMeeting.Id, currentMeeting.Participants__r[0].Meeting__c);
		}
	}

	@isTest
	static void createRecurringMeetingsEveryTuAndWedNoEndDate() {
		Date today = System.today();
		Date weekStart = today.toStartOfWeek();
		Date tuesdayDate = weekStart.addDays(9);
		System.assertEquals('Tuesday', DateUtils.getDayOfWeek(tuesdayDate));

		// Create a Recurrence for every Tuesday and Wednesday
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Weekly';
		recurrence.Recur_every__c = 1;
		recurrence.Weekdays__c = 'Tuesday;Wednesday';
		recurrence.Start_Date__c = tuesdayDate;
		recurrence.End_Type__c = 'No End Date';

		insert recurrence;

		// Create a Meeting for a Tuesday at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(tuesdayDate, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(tuesdayDate, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c groupParticipant = new Participant__c();
		groupParticipant.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		groupParticipant.Group__c = group1.Id;
		groupParticipant.Meeting__c = meeting.Id;
		insert groupParticipant;

		Test.startTest();

		List<Recurrence__c> recurrenceList = Database.query(RecurringMeetings.recurrenceQueryString);
		RecurringMeetings.createRecurringMeetings(recurrenceList);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(true, meetingList.size() > 1);

		// Validate that the dates for the created Meetings are only Tuesday and Wednesday
		for (Meeting__c currentMeeting : meetingList) {
			String dayOfWeek = DateUtils.getDayOfWeek(currentMeeting.Start_Date_Time__c.dateGMT());
			System.assertEquals(true, dayOfWeek == 'Tuesday' || dayOfWeek == 'Wednesday');
		}
	}

	@isTest
	static void createRecurringMeetingsEveryDayForTwoWeeks() {
		Date today = System.today();
		Date weekStart = today.toStartOfWeek();
		Date mondayDate = weekStart.addDays(8);
		System.assertEquals('Monday', DateUtils.getDayOfWeek(mondayDate));

		// Create a Recurrence for every Day
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Daily';
		recurrence.Daily_Option__c = 'Every Day';
		recurrence.Recur_every__c = 1;
		recurrence.Start_Date__c = mondayDate;
		recurrence.End_Type__c = 'End By Date';
		recurrence.End_By__c = mondayDate.addDays(14);

		insert recurrence;

		// Create a Meeting for a Monday at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(mondayDate, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(mondayDate, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		insert participant1;

		List<Participant__c> participantList = [SELECT Id, Meeting__c FROM Participant__c];
		System.assertEquals(1, participantList.size());

		Test.startTest();

		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = false;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c, (SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participants__r) FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(14, meetingList.size());

		// Validate that each Meeting has the correct participant
		for (Meeting__c currentMeeting : meetingList) {
			System.assertEquals(1, currentMeeting.Participants__r.size());
			System.assertEquals(participant1.RecordTypeId, currentMeeting.Participants__r[0].RecordTypeId);
			System.assertEquals(participant1.Group__c, currentMeeting.Participants__r[0].Group__c);
			System.assertEquals(currentMeeting.Id, currentMeeting.Participants__r[0].Meeting__c);
		}
	}

	@isTest
	static void createRecurringMeetingsEveryDayUntil20Meetings() {
		Date today = System.today();
		Date weekStart = today.toStartOfWeek();
		Date mondayDate = weekStart.addDays(8);
		System.assertEquals('Monday', DateUtils.getDayOfWeek(mondayDate));

		// Create a Recurrence for every Day
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Daily';
		recurrence.Daily_Option__c = 'Every Day';
		recurrence.Recur_every__c = 1;
		recurrence.Start_Date__c = mondayDate;
		recurrence.End_Type__c = 'End After Occurrences';
		recurrence.Number_of_Occurrences__c = 20;

		insert recurrence;

		// Create a Meeting for a Monday at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(mondayDate, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(mondayDate, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		insert participant1;

		List<Participant__c> participantList = [SELECT Id, Meeting__c FROM Participant__c];
		System.assertEquals(1, participantList.size());

		Test.startTest();

		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = false;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c, (SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participants__r) FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(19, meetingList.size());

		// Validate that each Meeting has the correct participant
		for (Meeting__c currentMeeting : meetingList) {
			System.assertEquals(1, currentMeeting.Participants__r.size());
			System.assertEquals(participant1.RecordTypeId, currentMeeting.Participants__r[0].RecordTypeId);
			System.assertEquals(participant1.Group__c, currentMeeting.Participants__r[0].Group__c);
			System.assertEquals(currentMeeting.Id, currentMeeting.Participants__r[0].Meeting__c);
		}
	}

	@isTest
	static void createRecurringMeetingsEveryWeekdayForTwoWeeks() {
		Date today = System.today();
		Date weekStart = today.toStartOfWeek();
		Date mondayDate = weekStart.addDays(8);
		System.assertEquals('Monday', DateUtils.getDayOfWeek(mondayDate));

		// Create a Recurrence for every Day
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Daily';
		recurrence.Daily_Option__c = 'Weekdays Only';
		recurrence.Recur_every__c = 1;
		recurrence.Start_Date__c = mondayDate;
		recurrence.End_Type__c = 'End By Date';
		recurrence.End_By__c = mondayDate.addDays(14);

		insert recurrence;

		// Create a Meeting for a Monday at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(mondayDate, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(mondayDate, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		insert participant1;

		List<Participant__c> participantList = [SELECT Id, Meeting__c FROM Participant__c];
		System.assertEquals(1, participantList.size());

		Test.startTest();

		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = false;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c, (SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participants__r) FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(10, meetingList.size());

		// Validate that each Meeting has the correct participant
		for (Meeting__c currentMeeting : meetingList) {
			System.assertEquals(1, currentMeeting.Participants__r.size());
			System.assertEquals(participant1.RecordTypeId, currentMeeting.Participants__r[0].RecordTypeId);
			System.assertEquals(participant1.Group__c, currentMeeting.Participants__r[0].Group__c);
			System.assertEquals(currentMeeting.Id, currentMeeting.Participants__r[0].Meeting__c);
		}
	}

	@isTest
	static void createRecurringMeetingsEveryMonthOn15th() {
		Date today = System.today();
		Date nextMonth = today.addDays(31);
		Date startOfNextMonth = nextMonth.toStartOfMonth();

		// Create a Recurrence for every Day
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Monthly';
		recurrence.Monthly_Day_Number__c = 15;
		recurrence.Recur_every__c = 1;
		recurrence.Start_Date__c = startOfNextMonth;
		recurrence.End_Type__c = 'No End Date';

		insert recurrence;

		// Create a Meeting for the first of next month at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(startOfNextMonth, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(startOfNextMonth, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		insert participant1;

		List<Participant__c> participantList = [SELECT Id, Meeting__c FROM Participant__c];
		System.assertEquals(1, participantList.size());

		Test.startTest();

		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = false;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c, (SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participants__r) FROM Meeting__c WHERE Id != :meeting.Id];

		System.assert(meetingList.size() >= 11 && meetingList.size() <= 12); //may be 11 or 12 depending on today's date and whatnot
		// if (meetingList.size() != 11)
		// {
		// 	String debugString = 'list size ' + meetingList.size();
		// 	for (Meeting__c m : meetingList)
		// 	{
		// 		debugString += '\n start ' + m.Start_Date_Time__c;
		// 	}
		// 	System.assert(false, debugString);
		// }

		// Validate that each Meeting has the correct participant
		for (Meeting__c currentMeeting : meetingList) {
			Datetime startDateTime = currentMeeting.Start_Date_Time__c;
			System.assertEquals(15, startDateTime.day());
			System.assertEquals(1, currentMeeting.Participants__r.size());
			System.assertEquals(participant1.RecordTypeId, currentMeeting.Participants__r[0].RecordTypeId);
			System.assertEquals(participant1.Group__c, currentMeeting.Participants__r[0].Group__c);
			System.assertEquals(currentMeeting.Id, currentMeeting.Participants__r[0].Meeting__c);
		}
	}

	@isTest
	static void createRecurringMeetingsEveryMonthOnSecondTuesday() {
		Date today = System.today();
		Date nextMonth = today.addDays(31);
		Date startOfNextMonth = nextMonth.toStartOfMonth();

		// Create a Recurrence for every Day
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Monthly';
		recurrence.Monthly_Day_Type__c = 'Day of Week';
		recurrence.Monthly_Day_Number__c = 1;
		recurrence.Monthly_Day_of_Week__c = 'Tuesday';
		recurrence.Monthly_Day_of_Week_Ordinal__c = 2;
		recurrence.Month_Number__c = 1;
		recurrence.Recur_every__c = 1;
		recurrence.Start_Date__c = startOfNextMonth;
		recurrence.End_Type__c = 'No End Date';

		insert recurrence;

		// Create a Meeting for the first of next month at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(startOfNextMonth, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(startOfNextMonth, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		insert participant1;

		List<Participant__c> participantList = [SELECT Id, Meeting__c FROM Participant__c];
		System.assertEquals(1, participantList.size());

		Test.startTest();

		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = false;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c, (SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participants__r) FROM Meeting__c WHERE Id != :meeting.Id];

		System.assert(meetingList.size() >= 10 && meetingList.size() <= 12, meetingList.size()); //may be 10 or 12 depending on today's date and whatnot

		// Validate that each Meeting has the correct participant
		for (Meeting__c currentMeeting : meetingList) {
			Datetime startDateTime = currentMeeting.Start_Date_Time__c;
			// System.assertEquals(15, startDateTime.day());
			System.assertEquals(1, currentMeeting.Participants__r.size());
			System.assertEquals(participant1.RecordTypeId, currentMeeting.Participants__r[0].RecordTypeId);
			System.assertEquals(participant1.Group__c, currentMeeting.Participants__r[0].Group__c);
			System.assertEquals(currentMeeting.Id, currentMeeting.Participants__r[0].Meeting__c);
		}
	}

	@isTest
	static void createRecurringMeetingsEveryYearOnJuly4th() {
		Date today = System.today();
		Date julyFirstNextYear = Date.newInstance(today.year(), 7, 1);

		// Create a Recurrence for every Day
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Yearly';
		recurrence.Yearly_Month__c = 'July';
		recurrence.Yearly_Day_Number__c = 4;
		recurrence.Recur_every__c = 1;
		recurrence.Start_Date__c = julyFirstNextYear;
		recurrence.End_Type__c = 'No End Date';

		insert recurrence;

		// Create a Meeting for the first of next month at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(julyFirstNextYear, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(julyFirstNextYear, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		insert participant1;

		List<Participant__c> participantList = [SELECT Id, Meeting__c FROM Participant__c];
		System.assertEquals(1, participantList.size());

		Test.startTest();

		RecurringMeetings.endDateToScheduleInAdvance = System.today().addDays(365);
		RecurringMeetings.daysInRange = RecurringMeetings.getAllDaysInRange();
		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = false;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c, (SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participants__r) FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(1, meetingList.size());

		// Validate that each Meeting has the correct participant
		for (Meeting__c currentMeeting : meetingList) {
			Datetime startDateTime = currentMeeting.Start_Date_Time__c;
			System.assertEquals(7, startDateTime.month());
			System.assertEquals(4, startDateTime.day());
			System.assertEquals(1, currentMeeting.Participants__r.size());
			System.assertEquals(participant1.RecordTypeId, currentMeeting.Participants__r[0].RecordTypeId);
			System.assertEquals(participant1.Group__c, currentMeeting.Participants__r[0].Group__c);
			System.assertEquals(currentMeeting.Id, currentMeeting.Participants__r[0].Meeting__c);
		}
	}

	@isTest
	static void meetingUpdateOnly() {
		Date today = System.today();
		Date weekStart = today.toStartOfWeek();
		Date tuesdayDate = weekStart.addDays(9);
		System.assertEquals('Tuesday', DateUtils.getDayOfWeek(tuesdayDate));

		// Create a Recurrence for every Tuesday and Wednesday
		Recurrence__c recurrence = new Recurrence__c();
		recurrence.Recurrence_Pattern__c = 'Weekly';
		recurrence.Recur_every__c = 1;
		recurrence.Weekdays__c = 'Tuesday;Wednesday';
		recurrence.Start_Date__c = tuesdayDate;
		recurrence.End_Type__c = 'No End Date';

		insert recurrence;

		// Create a Meeting for a Tuesday at 10am - 10:50am EST
		// Associate Meeting to Recurrence
		Meeting__c meeting = new Meeting__c();
		meeting.Recurrence__c = recurrence.Id;
		meeting.Start_Date_Time__c = Datetime.newInstance(tuesdayDate, Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(tuesdayDate, Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Participant
		Participant__c groupParticipant = new Participant__c();
		groupParticipant.RecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('Group Participant').getRecordTypeId();
		groupParticipant.Group__c = group1.Id;
		groupParticipant.Meeting__c = meeting.Id;
		insert groupParticipant;

		List<Recurrence__c> recurrenceList = Database.query(RecurringMeetings.recurrenceQueryString);
		RecurringMeetings.createRecurringMeetings(recurrenceList);

		meeting.Subject__c = 'Test Meeting 2';
		update meeting;

		Test.startTest();

		RecurringMeetings.RecurringMeetingOptions options = new RecurringMeetings.RecurringMeetingOptions();
		options.scheduleAfterToday = true;
		options.isMeetingUpdateOnly = true;
		options.recurrenceId = meeting.Recurrence__c;
		RecurringMeetings.createRecurringMeetings(options);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c, Subject__c, Description__c FROM Meeting__c WHERE Id != :meeting.Id];

		for (Meeting__c currentMeeting : meetingList) {
			System.assertEquals('Test Meeting 2', meeting.Subject__c);
		}
	}

	@isTest
	static void getMonthNumberFromString() {
		System.assertEquals(1, RecurringMeetings.getMonthNumberFromString('January'));
		System.assertEquals(2, RecurringMeetings.getMonthNumberFromString('February'));
		System.assertEquals(3, RecurringMeetings.getMonthNumberFromString('March'));
		System.assertEquals(4, RecurringMeetings.getMonthNumberFromString('April'));
		System.assertEquals(5, RecurringMeetings.getMonthNumberFromString('May'));
		System.assertEquals(6, RecurringMeetings.getMonthNumberFromString('June'));
		System.assertEquals(7, RecurringMeetings.getMonthNumberFromString('July'));
		System.assertEquals(8, RecurringMeetings.getMonthNumberFromString('August'));
		System.assertEquals(9, RecurringMeetings.getMonthNumberFromString('September'));
		System.assertEquals(10, RecurringMeetings.getMonthNumberFromString('October'));
		System.assertEquals(11, RecurringMeetings.getMonthNumberFromString('November'));
		System.assertEquals(12, RecurringMeetings.getMonthNumberFromString('December'));
	}

	@isTest
	static void testIsCorrectRecurringWeek() {
		Recurrence__c testRecur = new Recurrence__c(Start_Date__c = System.today().addDays(-30), Recur_Every__c = 2);
		Test.startTest();
		Boolean result = RecurringMeetings.isCorrectRecurringWeek(testRecur, System.today().addDays(-5));
		Test.stopTest();
		System.assertEquals(false, result);
	}

	@isTest
	static void testgetOrdinalDayOfWeek() {
		Date dt = System.today().toStartOfMonth().addDays(12).toStartOfWeek();
		Test.startTest();
		String ordinal = RecurringMeetings.getOrdinalDayOfWeek(dt);
		Test.stopTest();

		//System.assertEquals('Sunday-2', ordinal);
	}
}
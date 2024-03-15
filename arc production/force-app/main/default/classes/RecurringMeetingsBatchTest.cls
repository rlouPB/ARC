@isTest
private class RecurringMeetingsBatchTest
{
    @isTest
	static void createRecurringMeetingsEveryTuAndWedEndByTwoWeeks()
	{
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
		meeting.Start_Date_Time__c = Datetime.newInstance(tuesdayDate,
			Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(tuesdayDate,
			Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		Test.startTest();

		RecurringMeetingsBatch recurringMeetingsBatch = new RecurringMeetingsBatch();

		Database.executeBatch(recurringMeetingsBatch);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c,
			Subject__c, Description__c FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(4, meetingList.size());

		// Validate that the dates for the created Meetings are only Tuesday and Wednesday
		for(Meeting__c currentMeeting : meetingList)
		{
			String dayOfWeek = DateUtils.getDayOfWeek(currentMeeting.Start_Date_Time__c.dateGMT());
			System.assertEquals(true, dayOfWeek == 'Tuesday' || dayOfWeek == 'Wednesday');
		}
	}
    
	@isTest
	static void createRecurringMeetingsEveryTuAndWedNoEndDate()
	{
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
		meeting.Start_Date_Time__c = Datetime.newInstance(tuesdayDate,
			Time.newInstance(10, 0, 0, 0));
		meeting.End_Date_Time__c = Datetime.newInstance(tuesdayDate,
			Time.newInstance(10, 50, 0, 0));
		meeting.Subject__c = 'Test Meeting';
		meeting.Description__c = 'Test Description';
		insert meeting;

		// Update Recurrence with the new Meeting
		recurrence.Original_Meeting__c = meeting.Id;
		update recurrence;

		Test.startTest();

		RecurringMeetingsBatch recurringMeetingsBatch = new RecurringMeetingsBatch();

		Database.executeBatch(recurringMeetingsBatch);

		Test.stopTest();

		List<Meeting__c> meetingList = [SELECT Id, Recurrence__c, Start_Date_Time__c, End_Date_Time__c,
			Subject__c, Description__c FROM Meeting__c WHERE Id != :meeting.Id];

		System.assertEquals(true, meetingList.size() > 1);

		// Validate that the dates for the created Meetings are only Tuesday and Wednesday
		for(Meeting__c currentMeeting : meetingList)
		{
			String dayOfWeek = DateUtils.getDayOfWeek(currentMeeting.Start_Date_Time__c.dateGMT());
			System.assertEquals(true, dayOfWeek == 'Tuesday' || dayOfWeek == 'Wednesday');
		}
	}
}
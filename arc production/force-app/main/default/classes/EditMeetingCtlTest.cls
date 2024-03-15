@isTest
private class EditMeetingCtlTest
{
	@isTest
    private static void saveMeetingTest()
    {
        List<User> userForTesting = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' 
        	AND isActive = true LIMIT 1];
        
        EditMeetingCtl.MeetingRequest meetingRequest = new EditMeetingCtl.MeetingRequest();
		meetingRequest.mtg = new Meeting__c();
        meetingRequest.mtg.OwnerId = userForTesting[0].Id;
        meetingRequest.mtg.Subject__c = 'Test';
        meetingRequest.mtg.Description__c = 'Test Description';
        meetingRequest.mtg.Start_Date_Time__c = Datetime.newInstance(System.today(), Time.newInstance(10, 0, 0, 0));
        meetingRequest.mtg.End_Date_Time__c = Datetime.newInstance(System.today(), Time.newInstance(10, 50, 0, 0));
        meetingRequest.recurrenceSelected = 'series';
        meetingRequest.isMeetingUpdateOnly = false;
        
		meetingRequest.recurrenceRecord = new Recurrence__c();
		meetingRequest.recurrenceRecord.OwnerId = userForTesting[0].Id;
        meetingRequest.recurrenceRecord.Recurrence_Pattern__c = 'Daily';
        meetingRequest.recurrenceRecord.Recur_Every__c = 1;
        meetingRequest.recurrenceRecord.Daily_Option__c = 'Weekdays Only';
        meetingRequest.recurrenceRecord.Start_Date__c = System.today();
        meetingRequest.recurrenceRecord.End_Type__c = 'No End Date';
        
        EditMeetingCtl.Recurrence recurrence = new EditMeetingCtl.Recurrence();
        recurrence.ownerId = userForTesting[0].Id;
        recurrence.recurrencePattern = 'Daily';
        recurrence.recurEvery = 1;
        recurrence.dailyOption = 'Weekdays Only';
        recurrence.startDate = System.today();
        recurrence.endType = 'No End Date';
        meetingRequest.recurrence = recurrence;
        
        EditMeetingCtl.Response response = EditMeetingCtl.saveMeeting(JSON.serialize(meetingRequest));
        System.assertEquals('success', response.responseType, response.message);
        System.assertEquals('Success', response.title, response.message);
        System.assertEquals(EditMeetingCtl.recurrenceType2SuccessMessage.get('series-save'), response.message, response.message);
    }
    
    @isTest
    private static void loadMeetingTest()
    {
        List<User> userForTesting = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' 
        	AND isActive = true LIMIT 1];
        
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
        
        List<Participant__c> participantList = new List<Participant__c>();

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Group Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		participantList.add(participant1);
        
        // Create a Contact
        Contact contact1 = new Contact();
        contact1.FirstName = 'Test';
        contact1.LastName = 'Test';
        
        // Create a Contact Participant
        Participant__c participant2 = new Participant__c();
		participant2.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('Contact Participant').getRecordTypeId();
		participant2.Contact__c = contact1.Id;
		participant2.Meeting__c = meeting.Id;
		participantList.add(participant2);
        
        // Create a User Participant
        Participant__c participant3 = new Participant__c();
		participant3.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('User Participant').getRecordTypeId();
		participant3.User__c = userForTesting[0].Id;
		participant3.Meeting__c = meeting.Id;
		participantList.add(participant3);
        
        insert participantList;
        
        Test.startTest();
        
        EditMeetingCtl.MeetingResponse meetingResponse = EditMeetingCtl.loadMeeting_Ctl(String.valueOf(meeting.Id));
        
        Test.stopTest();
        
        System.assertEquals(false, meetingResponse.participantGroupList.isEmpty());
        
        for(EditMeetingCtl.ParticipantGroup participantGroup : meetingResponse.participantGroupList)
        {
            System.assertEquals(1, participantGroup.participants.size());
        }
    }
    
    @isTest
    private static void saveMeetingRequestUpdateOnly()
    {
        List<User> userForTesting = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' 
        	AND isActive = true LIMIT 1];
        
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
        
        List<Participant__c> participantList = new List<Participant__c>();

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Group Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		participantList.add(participant1);
        
        // Create a Contact
        Contact contact1 = new Contact();
        contact1.FirstName = 'Test';
        contact1.LastName = 'Test';
        insert contact1;
        
        // Create a Contact Participant
        Participant__c participant2 = new Participant__c();
		participant2.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('Contact Participant').getRecordTypeId();
		participant2.Contact__c = contact1.Id;
		participant2.Meeting__c = meeting.Id;
		participantList.add(participant2);
        
        // Create a User Participant
        Participant__c participant3 = new Participant__c();
		participant3.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('User Participant').getRecordTypeId();
		participant3.User__c = userForTesting[0].Id;
		participant3.Meeting__c = meeting.Id;
		participantList.add(participant3);
        
        insert participantList;
        
        EditMeetingCtl.MeetingRequest meetingRequest = new EditMeetingCtl.MeetingRequest();
        meetingRequest.meetingId = meeting.Id;
        meetingRequest.staffOwnerId = userForTesting[0].Id;
        meetingRequest.subject = meeting.Subject__c;
        meetingRequest.description = meeting.Description__c;
        meetingRequest.startDateTime = meeting.Start_Date_Time__c;
        meetingRequest.endDateTime = meeting.End_Date_Time__c;
        meetingRequest.recurrenceSelected = 'series';
        meetingRequest.isMeetingUpdateOnly = true;

		meetingRequest.mtg = new Meeting__c();
        meetingRequest.mtg.Id = meeting.Id;
        meetingRequest.mtg.OwnerId = userForTesting[0].Id;
        meetingRequest.mtg.Subject__c = meeting.Subject__c;
        meetingRequest.mtg.Description__c = meeting.Description__c;
        meetingRequest.mtg.Start_Date_Time__c = meeting.Start_Date_Time__c;
        meetingRequest.mtg.End_Date_Time__c = meeting.End_Date_Time__c;

		// meetingRequest.recurrenceRecord = recurrence;
        meetingRequest.recurrenceId = recurrence.Id;
        meetingRequest.recurrence = null;
        
        List<EditMeetingCtl.Participants> participantsList = new List<EditMeetingCtl.Participants>();
        
        EditMeetingCtl.Participants userParticipant = new EditMeetingCtl.Participants();
        userParticipant.objectType = 'User';
        userParticipant.idSet = new Set<Id> {userForTesting[0].Id};
        participantsList.add(userParticipant);
        
        EditMeetingCtl.Participants contactParticipant = new EditMeetingCtl.Participants();
        contactParticipant.objectType = 'Contact';
        contactParticipant.idSet = new Set<Id> {contact1.Id};
        participantsList.add(contactParticipant);
        
        EditMeetingCtl.Participants groupParticipant = new EditMeetingCtl.Participants();
        groupParticipant.objectType = 'Group__c';
        groupParticipant.idSet = new Set<Id> {group1.Id};
        participantsList.add(groupParticipant);
        
        meetingRequest.participantsList = participantsList;
        
        Test.startTest();
        
        EditMeetingCtl.Response response = EditMeetingCtl.saveMeeting(JSON.serialize(meetingRequest));
        
        Test.stopTest();
        
        System.assertEquals('success', response.responseType);
        System.assertEquals('Success', response.title);
		
        System.assertEquals(EditMeetingCtl.recurrenceType2SuccessMessage.get('series-save'), response.message);
    }
    
    @isTest
    private static void saveMeetingRequestUpdate()
    {
        List<User> userForTesting = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' 
        	AND isActive = true LIMIT 1];
        
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
        
        List<Participant__c> participantList = new List<Participant__c>();

		// Create a Group
		Group__c group1 = new Group__c();
		group1.Name = 'Test Group';
		insert group1;

		// Create a Group Participant
		Participant__c participant1 = new Participant__c();
		participant1.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('Group Participant').getRecordTypeId();
		participant1.Group__c = group1.Id;
		participant1.Meeting__c = meeting.Id;
		participantList.add(participant1);
        
        // Create a Contact
        Contact contact1 = new Contact();
        contact1.FirstName = 'Test';
        contact1.LastName = 'Test';
        
        // Create a Contact Participant
        Participant__c participant2 = new Participant__c();
		participant2.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('Contact Participant').getRecordTypeId();
		participant2.Contact__c = contact1.Id;
		participant2.Meeting__c = meeting.Id;
		participantList.add(participant2);
        
        // Create a User Participant
        Participant__c participant3 = new Participant__c();
		participant3.RecordTypeId = Schema.SObjectType.Participant__c
			.getRecordTypeInfosByName()
    		.get('User Participant').getRecordTypeId();
		participant3.User__c = userForTesting[0].Id;
		participant3.Meeting__c = meeting.Id;
		participantList.add(participant3);
        
        insert participantList;
        
        EditMeetingCtl.MeetingRequest meetingRequest = new EditMeetingCtl.MeetingRequest();
        meetingRequest.meetingId = meeting.Id;
        meetingRequest.staffOwnerId = userForTesting[0].Id;
        meetingRequest.subject = meeting.Subject__c;
        meetingRequest.description = meeting.Description__c;
        meetingRequest.startDateTime = meeting.Start_Date_Time__c;
        meetingRequest.endDateTime = meeting.End_Date_Time__c;
        meetingRequest.recurrenceSelected = 'series';
        meetingRequest.isMeetingUpdateOnly = false;

		meetingRequest.mtg = new Meeting__c();
        meetingRequest.mtg.Id = meeting.Id;
        meetingRequest.mtg.OwnerId = userForTesting[0].Id;
        meetingRequest.mtg.Subject__c = meeting.Subject__c;
        meetingRequest.mtg.Description__c = meeting.Description__c;
        meetingRequest.mtg.Start_Date_Time__c = meeting.Start_Date_Time__c;
        meetingRequest.mtg.End_Date_Time__c = meeting.End_Date_Time__c;

        EditMeetingCtl.Recurrence recurrenceRequest = new EditMeetingCtl.Recurrence();
        recurrenceRequest.ownerId = userForTesting[0].Id;
        recurrenceRequest.recurrencePattern = recurrence.Recurrence_Pattern__c;
        recurrenceRequest.recurEvery = (Integer)recurrence.Recur_Every__c;
        recurrenceRequest.weekdays = recurrence.Weekdays__c;
        recurrenceRequest.startDate = recurrence.Start_Date__c;
        recurrenceRequest.endType = recurrence.End_Type__c;
        recurrenceRequest.endDate = recurrence.End_By__c;
        meetingRequest.recurrence = recurrenceRequest;
		meetingRequest.recurrenceRecord = recurrence;
        
        Test.startTest();
        
        EditMeetingCtl.Response response = EditMeetingCtl.saveMeeting(JSON.serialize(meetingRequest));
        
        Test.stopTest();
        
        System.assertEquals('success', response.responseType, response.message);
        System.assertEquals('Success', response.title, response.message);
        System.assertEquals(EditMeetingCtl.recurrenceType2SuccessMessage.get('series-save'), response.message, response.message);
    }
}
@isTest class SchedulingTest 
{

    @TestSetup
    static void makeData()
    {
        Id userId = Userinfo.getUserId();
        
        List<Scheduling_Resource__c> rooms = new List<Scheduling_Resource__c>();
        rooms.add(new Scheduling_Resource__c(Building__c = 'Building0', Name = 'Room0'));
        rooms.add(new Scheduling_Resource__c(Building__c = 'Building0', Name = 'Room1'));
        rooms.add(new Scheduling_Resource__c(Building__c = 'Building0', Name = 'Room2'));
        insert rooms;

        List<Group__c> groupsToInsert = new List<Group__c>();
        groupsToInsert.add(new Group__c(
            Name = 'this group'
        ));

        insert groupsToInsert;
    
        Id patientAccountRtId = [select Id from Recordtype where sObjectType = 'Account' and Name = 'Patient'].Id;
        Id patientContactRtId = [select Id from Recordtype where sObjectType = 'Contact' and Name = 'Patient'].Id;

        List<Account> patientAccounts = new List<Account>();
        patientAccounts.add(new Account(
            Name = 'accname',
            RecordtypeId = patientAccountRtId));
        insert patientAccounts;

        List<Contact> patientContacts = new List<Contact>();
        patientContacts.add(new Contact(
            LastName = 'patientZero',
            RecordtypeId = patientContactRtId,
            AccountId = patientAccounts[0].Id));
        insert patientContacts;

        List<Staff_Group_Member__c> staffGMsToInsert = new List<Staff_Group_Member__c>();
        for (Group__c g : groupsToInsert)
        {
            staffGMsToInsert.add(new Staff_Group_Member__c(
                Group_Name__c = g.Id,
                Staff_Member__c = userId,
                Role__c = 'Member',
                Start_Date__c = system.today().addDays(-100)
            ));
        }
        insert staffGMsToInsert;

        List<Patient_Group_Member__c> patientGMsToInsert = new List<Patient_Group_Member__c>();
        for (Group__c g : groupsToInsert)
        {
            for (Contact ptContact : patientContacts)
            {
                patientGMsToInsert.add(new Patient_Group_Member__c(
                    Group_Name__c = g.Id,
                    Patient__c = ptContact.Id,
                    Role__c = 'Member',
                    Start_Date__c = system.today().addDays(-100)
                ));
            }
        }
        insert patientGMsToInsert;

        Date today = system.today();
        Datetime baseTime = Datetime.newInstance(today.year(), today.month(), today.day(), 12, 0, 0); //noon today

        List<Datetime> meetingTimes = new List<Datetime>
        {
            baseTime.addDays(-100),
            baseTime.addDays(-1),
            baseTime.addDays(1),
            baseTime.addDays(100)
        };
        system.debug('meetingTimes ' + meetingTimes);
        List<Meeting__c> meetingsToInsert = new List<Meeting__c>();
        for (Datetime dt : meetingTimes)
        {
            Meeting__c newMtg = new Meeting__c(Subject__c = 'Case Conference', 
                    Start_Date_Time__c = dt, 
                    End_Date_Time__c = dt.addMinutes(50), 
					Staff_Group_Meeting_Type__c = 'Case Conference',
					Patient_Account__c = patientAccounts[0].Id);
            meetingsToInsert.add(newMtg);
            newMtg = new Meeting__c(Subject__c = 'Doctor on Call', 
                    Start_Date_Time__c = dt, 
                    End_Date_Time__c = dt.addMinutes(50), 
                    Other_Meeting_Type__c = 'Doctor on Call',
					Patient_Account__c = patientAccounts[0].Id);
            meetingsToInsert.add(newMtg);
            newMtg = new Meeting__c(Subject__c = 'Holiday', 
                    Start_Date_Time__c = dt, 
                    End_Date_Time__c = dt.addMinutes(50), 
                    Other_Meeting_Type__c = 'Holiday',
					Patient_Account__c = patientAccounts[0].Id);
            meetingsToInsert.add(newMtg);

        }
        insert meetingsToInsert;   

        List<Participant__c> participants = new List<Participant__c>();
        //for (Meeting__c mtg : meetingsToInsert)
        for (Integer i = 0; i < meetingTimes.size(); i++)
        {
            Participant__c newPart = new Participant__c(
                Meeting__c = meetingsToInsert[i*2].Id,
                User__c = userId
            );
            participants.add(newPart);
            newPart = new Participant__c(
                Meeting__c = meetingsToInsert[i*2].Id,
                Contact__c = patientContacts[0].Id
            );
            participants.add(newPart);
            newPart = new Participant__c(
                Meeting__c = meetingsToInsert[i*2 + 1].Id,
                Group__c = groupsToInsert[0].Id
            );
            participants.add(newPart);
            newPart = new Participant__c(
                Meeting__c = meetingsToInsert[i*2 + 2].Id,
                User__c = userId
            );
        }
        system.debug('participants ' + participants);
        insert participants;


	}
	
	static testMethod void testByPatientFocus()
	{
        Set<Id> contactIdSet = new Set<ID>();
		for (Contact c: [select Id, AccountId from Contact])
		{
            contactIdSet.add(c.AccountId);
		}
        system.assert(contactIdSet.size() > 0);
		contactIdSet.add(Userinfo.getUserId());
        
        //troubleshooting 210217JN can be removed if desirec
            List<Participant__c> pars = [SELECT Meeting__c FROM Participant__c WHERE User__c IN :contactIdSet];
            system.assert(pars.size() > 0, 'No pars in immediate query');
            String query = 'SELECT Id, Patient_Name__c, Start_Date_Time__c, End_Date_Time__c, Meeting_Focus__c, Patient_Account__c, Patient_Account__r.Name, ';
            query += 'Subject__c, Description__c, Recurrence__c, Meeting_Type__c, Patient_Attendance__c, Group_Attendance_Tracking__c, All_Day_Meeting__c, All_Day_Date__c, ';
            query += 'Room_Resource__c, Room_Resource__r.Building__c, Room_Resource__r.Long_Name__c, Room_Resource__r.Short_Name__c, Room_Resource__r.Room__c, Videoconference_Link__c, ';
            query += 'Monthly_Note__c, Monthly_Note_Finalized__c ';
            query += 'FROM Meeting__c ';
            query += 'WHERE Patient_Account__c IN :contactIdSet ';
            query += 'AND ID IN (SELECT Meeting__c FROM Participant__c WHERE User__c IN :contactIdSet) ';
            query += 'ORDER BY Start_Date_Time__c ASC';
            System.debug('query ' + query);
            List<Meeting__c> checkMeetings = (List<Meeting__c>)Database.query(query);
            system.assert(checkMeetings.size() > 0, 'No Meetings in immediate query');

		system.debug(contactIdSet);
		Scheduling.Options options = new Scheduling.Options();
		options.type = 'PatientFocus';
		options.personOrGroupIds = contactIdSet;
        options.rangeStart = system.now().addDays(-7);
        options.rangeEnd = system.now().addDays(7);
        
        Test.startTest();
            Scheduling.Calendar testCal = Scheduling.getSchedule(JSON.serialize(options));
        Test.stopTest();
        system.assert(testCal.events.size() > 0);
	}

    static testmethod void testByMeetingTypes()
    {
        Set<String> meetingTypes = new Set<String>
        {
            'Case Conference',
            'Doctor on Call'
        };
        Scheduling.Options options = new Scheduling.Options();
        options.type = 'MeetingType';
        options.meetingTypes = meetingTypes;
        options.rangeStart = system.now().addDays(-7);
        options.rangeEnd = system.now().addDays(7);
        
        Test.startTest();
            Scheduling.Calendar testCal = Scheduling.getSchedule(JSON.serialize(options));
        Test.stopTest();
        system.assert(testCal.events.size() > 0);
    }

    static testmethod void testByUser()
    {
        List<Meeting__c> allMeetings = [
                SELECT Id, Subject__c,
                    (SELECT Id, User__c, Contact__c, Group__c 
                        FROM Participants__r)
                FROM Meeting__c
        ];
        system.assertEquals(12, allMeetings.size());
        for (Meeting__c m : allMeetings)
        {
            // system.assert(m.Participants__r.size() > 0);
        }

        Set<Id> userIdSet = new Set<Id>
        {
            Userinfo.getUserId()
        };

        Scheduling.Options options = new Scheduling.Options();
        options.type = 'User';
        options.personOrGroupIds = userIdset;
        options.rangeStart = system.now().addDays(-7);
        options.rangeEnd = system.now().addDays(7);
        
        Test.startTest();
            Scheduling.Calendar testCal = Scheduling.getUserSchedule(JSON.serialize(options));
        Test.stopTest();
        system.assert(testCal.events.size() > 0);
    }

    static testmethod void testByGroup()
    {
        List<Group__c> groups = [select Id, Name from Group__c];
        Set<Id> groupIdSet = new Map<Id, Group__c>(groups).keySet();
        
        Scheduling.Options options = new Scheduling.Options();
        options.type = 'Group';
        options.personOrGroupIds = groupIdSet;
        options.rangeStart = system.now().addDays(-7);
        options.rangeEnd = system.now().addDays(7);
        
        Test.startTest();
            Scheduling.Calendar testCal = Scheduling.getSchedule(JSON.serialize(options));
        Test.stopTest();
        system.assert(testCal.events.size() > 0);
    }

    static testmethod void testByContact()
    {
        Set<Id> contactIdSet = new Map<Id, Contact>([select Id from Contact]).keySet();
        system.assert(contactIdSet.size() > 0);
        Scheduling.Options options = new Scheduling.Options();
        options.type = 'Contact';
        options.personOrGroupIds = contactIdSet;
        options.rangeStart = system.now().addDays(-7);
        options.rangeEnd = system.now().addDays(7);

        Test.startTest();
            Scheduling.Calendar testCal = Scheduling.getSchedule(JSON.serialize(options));
        Test.stopTest();
        system.assert(testCal.events.size() > 0);
    }

    static testmethod void testGetUser()
    {
        Test.startTest();
            Scheduling.UserResponse userResponse = Scheduling.getUser(Userinfo.getUserId());
        Test.stopTest();
        system.assertEquals(Userinfo.getUserId(), userResponse.user.Id);
    }

    static testmethod void testGetSchedulerDaysById()
    {
        Datetime rangeEndDateTime = system.now().addDays(7);
        Datetime rangeStartDateTime = system.now().addDays(-7);

        Test.startTest();
            List<Scheduling.Day> days = Scheduling.getSchedulerDaysById(Userinfo.getUserId(), rangeStartDateTime, rangeEndDateTime);
        Test.stopTest();

        system.assertEquals(15, days.size());
        for (Scheduling.Day day : days)
        {
            system.assertNotEquals(0, day.blocks.size());
            
            if (day.blocks.size() == 1)
            {
                system.assertNotEquals(system.today().addDays(-1),day.dateOfDay);
                system.assertNotEquals(system.today().addDays(1),day.dateOfDay);
            } else 
            {
                system.assert(day.dateOfDay == system.today().addDays(-1) || day.dateOfDay == system.today().addDays(1), 'more blocks on ' + day.dateOfDay);
            }
        }
    }


    static testmethod void testGetSchedulerHeaders()
    {
        Datetime rangeStartDateTime = system.now().addDays(-7);
        Datetime rangeEndDateTime = system.now().addDays(7);

        Test.startTest();
            List<Scheduling.Day> days = Scheduling.getSchedulerHeaders(rangeStartDateTime, rangeEndDateTime);
        Test.stopTest();
    }    
    
    static testmethod void testAvailableRooms()
    {
        List<Scheduling_Resource__c> rooms = [select Id, Name from Scheduling_Resource__c order by Name ASC];

        Datetime newMeetingStartDateTime = System.now();
        Datetime newMeetingEndDateTime = newMeetingStartDateTime.addHours(2);
        Meeting__c newMeeting = new Meeting__c(
            Start_Date_Time__c = newMeetingStartDateTime,
            End_Date_Time__c = newMeetingEndDateTime,
            Subject__c = 'existing meeting',
            Room_Resource__c = rooms[0].Id
        );
        insert newMeeting;
        Test.startTest();
            List<Scheduling_Resource__c> availableRooms = Scheduling.getAvailableSchedulingResourcesForMeetingTimes(rooms[1].Id, newMeetingStartDateTime, newMeetingEndDateTime);
            system.assertEquals(rooms.size() - 1, availableRooms.size(), availableRooms);
            
            availableRooms = Scheduling.getAvailableSchedulingResourcesForMeetingTimes(rooms[0].Id, newMeetingStartDateTime, newMeetingEndDateTime);
            system.assertEquals(rooms.size(), availableRooms.size(), availableRooms);
        Test.stopTest();
    }    

    static testmethod void testDeleteMeeting()
    {
        Id meetingId = [select Id from Meeting__c limit 1].Id;
        Test.startTest();
            String result = Scheduling.deleteMeeting(meetingId);

        Test.stopTest();
        System.assertEquals('success', result);
    }

}
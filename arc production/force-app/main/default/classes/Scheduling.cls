public class Scheduling
{
    //public List<Participant__c> participants = new List<Participant__c>();
    Options options;
    ViewOptionsCtl.OptionSet currentOptionSet;

    public List<Meeting> meetings = new List<Meeting>();
    private Set<Id> groupIds = new Set<Id>();
    private Set<Id> userIds = new Set<Id>();
    private Set<Id> patientIds = new Set<Id>();
    private Set<String> meetingTypes = new Set<String>();
    private Set<String> roomNames = new Set<String>();
    private Set<String> filterAggregatedValues = new Set<String>();
	private Set<String> filterExcludedValues = new Set<String>();
	private Boolean showAllStaff = false;

    public static Time startTime = Time.newInstance(8, 0, 0, 0);
    public static Time endTime = Time.newInstance(17, 0, 0, 0);
    public class SchedulingException extends Exception {}


    public Scheduling(Options options)
    {
        System.debug('options ' + options);
        this.options = options;
        if (options.aggregatedField != null && options.aggregatedField != '')
        {
            //collect values for query later
            filterAggregatedValues.addAll(options.aggregatedValues);
            filterExcludedValues.addAll(options.excludedValues);
        }

        queryCurrentViewOptionSet();

        if(options.type == 'User' || options.type == 'Contact')
        {

            if(options.type == 'User')
            {
                if (options.personOrGroupIds != null) this.userIds.addAll(options.personOrGroupIds);
                System.debug('User Ids ' + this.userIds);
            }
            if(options.type == 'Contact')
            {
                if (options.personOrGroupIds != null) this.patientIds.addAll(options.personOrGroupIds);
            }
            getAllGroupIds(options.personOrGroupIds);
            queryParticipants(options);
        }
        else if(options.type == 'Group')
        {
            if (options.personOrGroupIds != null) groupIds.addAll(options.personOrGroupIds);
            queryParticipants(options);
        }
        else if(options.type == 'MeetingType')
        {
            if (options.meetingTypes != null) meetingTypes.addAll(options.meetingTypes);
            queryMeetingTypes(options);
        }
        else if(options.type == 'RoomName')
        {
            if (options.roomNames != null) roomNames.addAll(options.roomNames);
            queryRoomNames(options);
		}
		else if (options.type == 'PatientFocus')
		{
			if (options.personOrGroupIds != null)
			{
				this.userIds.addAll(options.personOrGroupIds);
				this.patientIds.addAll(options.personOrGroupIds);
			}
			if (options.showAllStaff != null) {this.showAllStaff = options.showAllStaff;}
			queryPatientFocus(options);
		}
    }

    void queryCurrentViewOptionSet()
    {
		system.debug('options type: ' + options.type);
        if (options.currentViewOptionSetId != null && options.type != 'PatientFocus')
        {
            List<ViewOptionsCtl.OptionSet> allOptionSets = ViewOptionsCtl.getViewOptionSets(options.context);
            for (ViewOptionsCtl.OptionSet thisOpt : allOptionSets)
            {
                if (thisOpt.optionSetObj.Id == this.options.currentViewOptionSetId)
                {
                    currentOptionSet = thisOpt;
                    Map<String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(thisOpt.optionSetObj.Parameters__c);
                    options.aggregatedField = (String)parameters.get('aggregatedField');
                    options.aggregatedValues = new Set<String>();


                    break;
                }
            }
        }

    }

    private void getAllGroupIds(Set<Id> personIds)
    {
        if(personIds != null && !personIds.isEmpty())
        {
            List<Id> personIdList = new List<Id> (personIds);
            Id sObjectId = personIdList[0];
            if(sObjectId.getSObjectType().getDescribe().getName() == 'User')
            {
                //221214 JN added filter to only pull group members where start date and end date match current date
                for(Staff_Group_Member__c groupMember : [SELECT Group_Name__c 
                    FROM Staff_Group_Member__c
                	WHERE Staff_Member__c IN :personIds
                        AND Start_Date__c <= TODAY
                        AND (Planned_End_Date__c >= TODAY OR Planned_End_Date__c = null)])
                {
                    groupIds.add(groupMember.Group_Name__c);
                }
            }
            else if(sObjectId.getSObjectType().getDescribe().getName() == 'Contact')
            {
                for(Patient_Group_Member__c groupMember : [SELECT Group_Name__c 
                    FROM Patient_Group_Member__c
                	WHERE Patient__c IN :personIds
                        AND Start_Date__c <= TODAY
                        AND (Planned_End_Date__c >= TODAY OR Planned_End_Date__c = null)])
                {
                    groupIds.add(groupMember.Group_Name__c);
                }
            }
        }
    }

    private void queryMeetingTypes(Options options)
    {
        this.meetings = new List<Meeting>();
        if (!options.meetingTypes.isEmpty())
        {
            Datetime rangeStart = options.rangeStart;
			Datetime rangeEnd = options.rangeEnd;
            Date rangeStartDate = convertDatetimeToDateWithoutTimeInformation(rangeStart);
            rangeEnd = rangeEnd.addDays(1);
            Date rangeEndDate = Date.valueOf(rangeEnd);
            String query = 'SELECT Id, Patient_Name__c, Start_Date_Time__c, End_Date_Time__c, Meeting_Focus__c, Patient_Account__c, Patient_Account__r.Name, ';
			query += 'Subject__c, Description__c, Recurrence__c, Meeting_Type__c, Patient_Attendance__c, Group_Attendance_Tracking__c, ';
			query += 'All_Day_Meeting__c, All_Day_Date__c, Monthly_Note__c, Monthly_Note_Finalized__c, ';
            query += 'Room_Resource__c, Room_Resource__r.Building__c, Room_Resource__r.Long_Name__c, Room_Resource__r.Short_Name__c, Room_Resource__r.Room__c, Videoconference_Link__c ';
			if (options.aggregatedField != null && !query.contains(options.aggregatedField)) query += ', ' + options.aggregatedField + ' ';
            query += 'FROM Meeting__c ';
            query += 'WHERE Meeting_Type__c IN ';
                query += expandSet(options.meetingTypes);

			query += 'AND ((All_Day_Date__c >= :rangeStartDate AND All_Day_Date__c < :rangeEndDate) ';
			query += 'OR (DAY_ONLY(convertTimezone(Start_Date_Time__c)) >= :rangeStartDate AND DAY_ONLY(convertTimezone(End_Date_Time__c)) < :rangeEndDate)) ';
            // query += 'AND Start_Date_Time__c >= :rangeStart ';
            // query += 'AND End_Date_Time__c < :rangeEnd ';
            query += 'ORDER BY Start_Date_Time__c ASC';
            System.debug('rangeStart ' + rangeStart + ' rangeEnd ' + rangeEnd);
            System.debug('query ' + query);

            List<Meeting__c> mtgs = (List<Meeting__c>)Database.query(query);
            for (Meeting__c mtg : mtgs)
            {
                System.debug('current meeting: ' + mtg);
                String fieldValue;
                if (options.aggregatedField != null)
                {
                    fieldValue = getFieldValue(mtg, options.aggregatedField);
                    if (String.isNotBlank(fieldValue))
                    {
                        // fieldValue = String.valueOf(mtg.get(options.aggregatedField));
                        options.aggregatedValues.add(fieldValue);
                    }
                }
                //save if this is a selected value or there are no values, and also this is not an excluded value
                // if ((filterAggregatedValues.isEmpty()
                //             || filterAggregatedValues.contains(fieldValue))
                //         && !filterExcludedValues.contains(fieldValue))
                //000105 JN getting everything except unchecked boxes
                if (!filterExcludedValues.contains(fieldValue))
                {
                    this.meetings.add(new Meeting(mtg));
                }

                // if (options.aggregatedField != null
                //     && mtg.get(options.aggregatedField) != null)
                // {
                //     options.aggregatedValues.add(String.valueOf(mtg.get(options.aggregatedField)));
                // }

                // this.meetings.add(new Meeting(mtg));
            }
        }
    }

    private String expandSet(Set<String> theSet)
    {
        String returnString = '(';
        Boolean isFirst = true;
        for (String typ : theSet)
        {
            if (isFirst)
            {
                isFirst = false;
            } else
            {
                returnString += ', ';
            }
            returnString += '\'' + typ + '\'';
        }
        returnString += ') ';
        System.debug('expandSet returnString ' + returnString);
        return returnString;
    }
    private void queryRoomNames(Options options)
    {
        this.meetings = new List<Meeting>();
        system.debug('roomNames ' + options.roomNames);
        if (!options.roomNames.isEmpty())
        {

            Datetime rangeStart = options.rangeStart;
            Datetime rangeEnd = options.rangeEnd;
			//Date rangeStartDate = Date.valueOf(rangeStart);
			//Date rangeEndDate = Date.valueOf(rangeEnd);
            Date rangeStartDate = convertDatetimeToDateWithoutTimeInformation(rangeStart);
            rangeEnd = rangeEnd.addDays(1);
            Date rangeEndDate = Date.valueOf(rangeEnd);
            String query = 'SELECT Id, Patient_Name__c, Start_Date_Time__c, End_Date_Time__c, Meeting_Focus__c, Patient_Account__c, Patient_Account__r.Name, ';
                        query += 'Subject__c, Description__c, Recurrence__c, Meeting_Type__c, Patient_Attendance__c, All_Day_Meeting__c, All_Day_Date__c, ';
						query += 'Room_Resource__c, Room_Resource__r.Building__c, Room_Resource__r.Long_Name__c, Room_Resource__r.Short_Name__c, Room_Resource__r.Room__c, Videoconference_Link__c, ';
						query += 'Monthly_Note__c, Monthly_Note_Finalized__c ';
            if (options.aggregatedField != null && !query.contains(options.aggregatedField)) query += ', ' + options.aggregatedField + ' ';

                    query += 'FROM Meeting__c ';
                    query += 'WHERE ';
                    if (!options.roomNames.isEmpty())
                    {
                        query += 'Room_Resource__r.Short_Name__c IN ';
                            query += expandSet(options.roomNames);
                        query += ' AND ';
					}
						query += '((All_Day_Date__c >= :rangeStartDate AND All_Day_Date__c < :rangeEndDate) ';
						query += 'OR (DAY_ONLY(convertTimezone(Start_Date_Time__c)) >= :rangeStartDate AND DAY_ONLY(convertTimezone(End_Date_Time__c)) < :rangeEndDate)) ';
                        // query += 'Start_Date_Time__c >= :rangeStart ';
                        // query += 'AND End_Date_Time__c < :rangeEnd ';
                    query += 'ORDER BY Start_Date_Time__c ASC';
            System.debug('rangeStart ' + rangeStart + ' rangeEnd ' + rangeEnd);
            System.debug('query ' + query);

            List<Meeting__c> mtgs = (List<Meeting__c>)Database.query(query);
            for (Meeting__c mtg : mtgs)
            {
                System.debug('current meeting: ' + mtg);
                String fieldValue;
                if (options.aggregatedField != null)
                {
                    fieldValue = getFieldValue(mtg, options.aggregatedField);
                    if (String.isNotBlank(fieldValue))
                    {
                        // fieldValue = String.valueOf(mtg.get(options.aggregatedField));
                        options.aggregatedValues.add(fieldValue);
                    }
                }
                //save if this is a selected value or there are no values, and also this is not an excluded value
                if ((filterAggregatedValues.isEmpty()
                            || filterAggregatedValues.contains(fieldValue))
                        && !filterExcludedValues.contains(fieldValue))
                {
                    this.meetings.add(new Meeting(mtg));
                }

                //this.meetings.add(new Meeting(mtg));
            }
        }
    }

    
    private void queryParticipants(Options options)
    {
        Datetime rangeStart = options.rangeStart;
        Datetime rangeEnd = options.rangeEnd;
		Date rangeStartDate = convertDatetimeToDateWithoutTimeInformation(rangeStart);
		Date rangeEndDate = Date.valueOf(rangeEnd);
        String query = 'SELECT Id, Meeting__c, Meeting__r.Start_Date_Time__c, Meeting__r.End_Date_Time__c, ';
                    query += 'Meeting__r.Subject__c, Meeting__r.Description__c, Meeting__r.Recurrence__c, Meeting__r.Meeting_Type__c, ';
                    query += 'Meeting__r.Patient_Attendance__c, Meeting__r.Patient_Account__c, Meeting__r.Patient_Account__r.Name, ';
                    query += 'Meeting__r.Patient_Name__c, Meeting__r.Meeting_Focus__c, Meeting__r.All_Day_Meeting__c, Meeting__r.All_Day_Date__c, ';
                    query += 'Meeting__r.Room_Resource__c, Meeting__r.Room_Resource__r.Building__c, Meeting__r.Room_Resource__r.Long_Name__c, ';
					query += 'Meeting__r.Room_Resource__r.Short_Name__c, Meeting__r.Room_Resource__r.Room__c, Meeting__r.Videoconference_Link__c, ';
					query += 'Meeting__r.Monthly_Note__c, Meeting__r.Monthly_Note_Finalized__c ';
        if (options.aggregatedField != null && !query.contains('Meeting__r.' + options.aggregatedField)) query += ', Meeting__r.' + options.aggregatedField + ' ';

        query += 'FROM Participant__c ';
        query += 'WHERE (User__c IN :userIds ';
        query += 'OR Contact__c IN :patientIds ';
        query += 'OR Group__c IN :groupIds) ';

        query += 'AND ((Meeting__r.All_Day_Date__c >= :rangeStartDate AND Meeting__r.All_Day_Date__c < :rangeEndDate) ';
        query += 'OR (DAY_ONLY(convertTimezone(Meeting__r.Start_Date_Time__c)) >= :rangeStartDate AND DAY_ONLY(convertTimezone(Meeting__r.End_Date_Time__c)) < :rangeEndDate)) ';
        // query += 'AND Meeting__r.Start_Date_Time__c >= :rangeStart ';
        // query += 'AND Meeting__r.End_Date_Time__c < :rangeEnd ';

        if (currentOptionSet != null
                && currentOptionSet.optionSetObj != null
                && currentOptionSet.optionSetObj.Parameters__c != null)
        {
            Map<String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(currentOptionSet.optionSetObj.Parameters__c);
            if (parameters.containsKey('whereClause'))
            {
                query += 'AND ( ' + parameters.get('whereClause') + ') ';
            }
        }

        query += 'ORDER BY Meeting__r.Start_Date_Time__c ASC';
        System.debug('rangeStart ' + rangeStart);
        System.debug('rangeStartDate ' + rangeStartDate);
        System.debug('rangeEnd ' + rangeEnd);
        System.debug('rangeEndDate ' + rangeEndDate);
        system.debug('userIds ' + userIds);
        System.debug('query ' + query);
        List<Participant__c> participants = Database.query(query);

        this.meetings = new List<Meeting>();
        Set<Id> meetingIds = new Set<Id>();
        for(Participant__c participant : participants)
        {
            if (!meetingIds.contains(participant.Meeting__c))
            {
                Meeting__c mtg = participant.Meeting__r;
                String fieldValue;
                if (options.aggregatedField != null)
                {
                    fieldValue = getFieldValue(mtg, options.aggregatedField);
                    System.debug('current meeting: ' + mtg);
                    system.debug('fieldValue ' + fieldValue);
                    if (String.isNotBlank(fieldValue))
                    {
                        // fieldValue = String.valueOf(mtg.get(options.aggregatedField));
                        options.aggregatedValues.add(fieldValue);
                    }
                }
                //save if this is a selected value or there are no values, and also this is not an excluded value
                // if ((filterAggregatedValues.isEmpty()
                //             || filterAggregatedValues.contains(fieldValue))
                //         && !filterExcludedValues.contains(fieldValue))
                 if (!filterExcludedValues.contains(fieldValue))
                {
                    this.meetings.add(new Meeting(mtg));
                }

                meetingIds.add(participant.Meeting__c);
            }
		}
	}

	private void queryPatientFocus(Options options)
	{
		this.meetings = new List<Meeting>();
        if (!options.personOrGroupIds.isEmpty())
        {

            Datetime rangeStart = options.rangeStart;
			Datetime rangeEnd = options.rangeEnd;
			Date rangeStartDate = convertDatetimeToDateWithoutTimeInformation(rangeStart);
            rangeEnd = rangeEnd.addDays(1);
            Date rangeEndDate = Date.valueOf(rangeEnd);
			Set<ID> keys = this.patientIds;
            System.debug('@@ keys ' + keys + '\nrangeStart' + rangeStart + '\nrangeEnd ' + rangeEnd);

            String query = 'SELECT Id, Patient_Name__c, Start_Date_Time__c, End_Date_Time__c, Meeting_Focus__c, Patient_Account__c, Patient_Account__r.Name, ';
            query += 'Subject__c, Description__c, Recurrence__c, Meeting_Type__c, Patient_Attendance__c, Group_Attendance_Tracking__c, All_Day_Meeting__c, All_Day_Date__c, ';
			query += 'Room_Resource__c, Room_Resource__r.Building__c, Room_Resource__r.Long_Name__c, Room_Resource__r.Short_Name__c, Room_Resource__r.Room__c, Videoconference_Link__c, ';
			query += 'Monthly_Note__c, Monthly_Note_Finalized__c ';
			// query += '(SELECT User__c FROM Participants__r) ';
            query += 'FROM Meeting__c ';
			query += 'WHERE Patient_Account__c IN :keys ';
			query += 'AND ID IN (SELECT Meeting__c FROM Participant__c WHERE User__c IN :keys) ';
			query += 'AND ((All_Day_Date__c >= :rangeStartDate AND All_Day_Date__c < :rangeEndDate) ';
			query += 'OR (DAY_ONLY(convertTimezone(Start_Date_Time__c)) >= :rangeStartDate AND DAY_ONLY(convertTimezone(End_Date_Time__c)) < :rangeEndDate)) ';
			// query += 'AND Start_Date_Time__c >= :rangeStart ';
            // query += 'AND End_Date_Time__c < :rangeEnd ';
            query += 'ORDER BY Start_Date_Time__c ASC';
            System.debug('query ' + query);

            List<Meeting__c> mtgs = (List<Meeting__c>)Database.query(query);
            for (Meeting__c mtg : mtgs)
            {
               this.meetings.add(new Meeting(mtg));
            }
        }
	}


    public static Map<String, Map<String, String>> meetingType2ParametersMap = new Map<String, Map<String, String>>
    {
        'All Center'                        => new Map<String, String> {'background-color' => 'rgb(92,30,103)', 'color' => 'white' },
        'All Staff'                         => new Map<String, String> {'background-color' => 'rgb(94,138,180)', 'color' => 'white' },
        'Case Conference'                   => new Map<String, String> {'background-color' => 'rgb(217,138,94)', 'color' => 'black' },
        'Clinical Review'                   => new Map<String, String> {'background-color' => 'rgb(217,138,94)', 'color' => 'black' },
        'Clinical Staff Meeting'            => new Map<String, String> {'background-color' => 'rgb(94,138,180)', 'color' => 'white' },
        'Community Meeting'                 => new Map<String, String> {'background-color' => 'rgb(131,155,105)', 'color' => 'black' },
        'Dietetics and Nutrition'           => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Doctor on Call'                    => new Map<String, String> {'background-color' => 'white', 'color' => 'black' },
        'EPC'                               => new Map<String, String> {'background-color' => 'rgb(217,138,94)', 'color' => 'black' },
        'Family Consultation'               => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Family Therapy'                    => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Patient-Centered Family Meeting'   => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Holiday'                           => new Map<String, String> {'background-color' => 'yellow', 'color' => 'black', 'isAllDay' => 'true' },
        'Individual Psychotherapy'          => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Med Office'                        => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'non-Riggs Event/Conference'        => new Map<String, String> {'background-color' => 'rgb(40,40,40)', 'color' => 'white' },
        'Patient Government'                => new Map<String, String> {'background-color' => 'rgb(131,155,105)', 'color' => 'black' },
        'Psychological Testing Seminar'     => new Map<String, String> {'background-color' => 'rgb(94,138,180)', 'color' => 'white' },
        'Psychiatry'                        => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Psychological Test'                => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Riggs Event/Conference'            => new Map<String, String> {'background-color' => 'rgb(168,0,0)', 'color' => 'white' },
        'Individual Social Work'            => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Substance Use Services'            => new Map<String, String> {'background-color' => 'rgb(241,202,52)', 'color' => 'black' },
        'Community Center Group'            => new Map<String, String> {'background-color' => 'rgb(131,155,105)', 'color' => 'black' },
        'Team'                              => new Map<String, String> {'background-color' => 'rgb(94,138,80)', 'color' => 'black' },
        'unknown'                           => new Map<String, String> {'background-color' => 'white', 'color' => 'black' },
        'Other'                             => new Map<String, String> {'background-color' => 'white', 'color' => 'black' }
    };

    public static String getFieldValue(sObject obj, String fieldName)
	{
		if (obj == null || fieldName == null) return null;
        if (fieldName.contains('.'))
		{
			List<String> parts = fieldName.split('\\.', 2);
			system.debug('parts ' + parts);
            system.debug('obj ' + obj);
            system.debug('get: ' + obj.getSobject('Patient_Account__r'));
			sObject newObj = obj.getSobject(parts[0]);
            return getFieldValue(newObj, parts[1]);
		}
		Object rawValue = obj.get(fieldName);
		String value = '';
		if (rawValue != null)
		{
			value = String.valueOf(rawValue);
			String fieldType = String.valueOf(obj.getSobjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getType());
			if (fieldType == 'Date')
			{
				value = ((Date)rawValue).format();
			}

	        if (value == null) value = '';
	    }
		//system.debug('fieldName ' + fieldName + ' value ' + value);
		return value;
	}

    @AuraEnabled
    public static String deleteMeeting(Id meetingId)
    {
        return deleteMeeting( meetingId, 'single');
    }
    @AuraEnabled
    public static String deleteMeeting(Id meetingId, String recurrenceType)
    {
        return deleteMeetings(new Set<Id>{meetingId}, recurrenceType);
    }

    public static String deleteMeetings(Set<Id> meetingIdSet, String recurrenceType)
    {
        System.debug('deleteMeetings enter');
        String returnString = 'success';
        List<Participant__c> participants = new List<Participant__c>();
        List<Patient_Note__c> patientNotes = new List<Patient_Note__c>();
        List<Group_Note__c> groupNotes = new List<Group_Note__c>();
        List<Recurrence__c> recurrences = new List<Recurrence__c>();
        Savepoint sp = Database.setSavepoint();
        try
        {
            Set<Id> recurrenceIds = new Set<Id>();
            if (recurrenceType == 'series')
            {
                List<Meeting__c> mtgsRecurring = [
                        SELECT Recurrence__c
                        FROM Meeting__c
                        WHERE Id in :meetingIdSet
                            AND Recurrence__c != null];
                for (Meeting__c mtg : mtgsRecurring)
                {
                    recurrenceIds.add(mtg.Recurrence__c);
                }
            }

            //query for meeting and participants and Notes
            // List<Meeting__c> meetings = [
            //     SELECT Id,
            //         (SELECT Id FROM Group_Notes__r)
            //         // (SELECT Id FROM Patient_Notes__r),
            //     FROM Meeting__c
            //     WHERE (Start_Date_Time__c >= TODAY OR All_Day_Date__c >= TODAY)
            //         AND (Id in :meetingIdSet
            //                 OR Recurrence__c in :recurrenceIds)];

            List<Meeting__c> meetings = [
                SELECT Id,
                    (SELECT Id, Finalized_By__c FROM Group_Notes__r)
                    // (SELECT Id FROM Patient_Notes__r),
                FROM Meeting__c
                WHERE (Id in :meetingIdSet
                            OR Recurrence__c in :recurrenceIds) AND Monthly_Note_Finalized__c = FALSE];

            for (Meeting__c meeting : meetings)
            {
                // patientNotes.addAll(meeting.Patient_Notes__r);
                groupNotes.addAll(meeting.Group_Notes__r);
            }
            // checkNotes(patientNotes);
            checkNotes(groupNotes);

            participants = [SELECT Id from Participant__c
                            WHERE Meeting__c in :meetingIdSet
                                OR Meeting__r.Recurrence__c in :recurrenceIds];

            for (Id recurrenceId : recurrenceIds)
            {
                recurrences.add(new Recurrence__c(Id = recurrenceId));
            }

            System.debug('Meetings: ' + meetings);

            delete participants;
            // delete patientNotes;
            delete groupNotes;
            delete meetings;
            delete recurrences;

        } catch (Exception e)
        {
            Database.rollback(sp);
            returnString = 'Problem deleting: ' + e.getMessage() + '\n' + e.getStackTraceString();
        }
        return returnString;
    }

    static void checkNotes(List<sObject> notes)
    {
        for (sObject note : notes)
        {
            // if (note.get('Finalized_By__c') != null || note.get('Completed_By__c') != null)
            if (note.get('Finalized_By__c') != null)
            {
                throw new SchedulingException('You may not delete a Meeting with a completed Note.');
            }
        }
    }

    @AuraEnabled
    public static Calendar getSchedule(String options)
    {
        Scheduling.Options schedulingOptions = (Scheduling.Options)JSON.deserialize(options,
        	Scheduling.Options.class);
        return getSchedule(schedulingOptions);
    }
    public static Calendar getSchedule(Options schedulingOptions)
    {

        system.debug('384 schedulingOptions ' + schedulingOptions);
        Calendar calendar = new Calendar();
        calendar.startDate = System.today();
        if (schedulingOptions.rangeStart != null)
        {
            calendar.startDate = schedulingOptions.rangeStart.addHours(6).Date();
        }

        Scheduling schedule = new Scheduling(schedulingOptions);

		Set<ID> meetingIDs = new Set<ID>();
		for (Meeting m : schedule.meetings)
        {
            meetingIDs.add(m.id);
		}
		List<Group_Note__c> allGroupNotes = [SELECT Meeting__c FROM Group_Note__c WHERE Meeting__c IN :meetingIDs];
		Map<ID, List<Group_Note__c>> groupNotesByMeetingID = new Map<ID, List<Group_Note__c>>();
		for (Group_Note__c currentNote: allGroupNotes)
		{
			List<Group_Note__c> currentMeetingNotes = groupNotesByMeetingID.get(currentNote.Meeting__c);
			if (currentMeetingNotes == null) {currentMeetingNotes = new List<Group_Note__c>();}
			currentMeetingNotes.add(currentNote);
			groupNotesByMeetingID.put(currentNote.Meeting__c, currentMeetingNotes);
		}

        for (Meeting m : schedule.meetings)
        {
            Map<String, String> parametersMap = meetingType2ParametersMap.get(m.meeting.Meeting_Type__c);
            if (parametersMap != null)
            {
                if (parametersMap.containsKey('background-color')) m.color = parametersMap.get('background-color');
                if (parametersMap.containsKey('color')) m.textColor = parametersMap.get('color');
                if (parametersMap.containsKey('isAllDay')) m.isAllDay = Boolean.valueOf(parametersMap.get('isAllDay'));
			}

			List<Group_Note__c> currentMeetingNotes = groupNotesByMeetingID.get(m.id);
			// if (currentMeetingNotes == null) {currentMeetingNotes = new List<Group_Note__c>();}
			m.groupNotes = currentMeetingNotes;
        }

		calendar.events = schedule.meetings;
		calendar.options = schedulingOptions;

        return calendar;

    }

    @AuraEnabled
    public static Calendar getUserSchedule(String options)
    {
        return getSchedule(options);
    }


    @AuraEnabled
    public static UserResponse getUser(String userId)
    {
        UserResponse userResponse = new UserResponse();
        userResponse.user = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        if(userResponse.user.Profile.Name == 'System Administrator' || PermissionSets.hasPermissionSet(userId, 'Schedule Manager'))
        {
            userResponse.isScheduleManager = true;
        }
        return userResponse;
    }

    //used for ScheduleRow
    @AuraEnabled
    public static List<Day> getSchedulerDaysById(Id recordId, Datetime rangeStartDateTime, Datetime rangeEndDateTime)
    {
        List<Day> days = new List<Day>();

        Datetime dayStartDateTime = Datetime.newInstance(rangeStartDateTime.date(), Scheduling.startTime);
        Day currentDay = new Day(dayStartDateTime);
        Block currentBlock = new Block(dayStartDateTime);
        Block previousBlock;

		Datetime rangeStart = rangeStartDateTime;
        Datetime rangeEnd = rangeEndDateTime;
		//Date rangeStartDate = Date.valueOf(rangeStartDateTime);
		//Date rangeEndDate = Date.valueOf(rangeEndDateTime);
        Date rangeStartDate = convertDatetimeToDateWithoutTimeInformation(rangeStart);
		Date rangeEndDate = Date.valueOf(rangeEnd);
        String query = 'SELECT Id, Meeting__r.Start_Date_Time__c, Meeting__r.End_Date_Time__c,  Meeting__r.Meeting_Focus__c, ';
		query += 'Meeting__r.Subject__c, Meeting__r.Description__c, Meeting__r.Recurrence__c, Meeting__r.Patient_Attendance__c, ';
		query += 'Meeting__r.All_Day_Meeting__c, Meeting__r.All_Day_Date__c, Meeting__r.Monthly_Note__c, Meeting__r.Monthly_Note_Finalized__c ';
        query += 'FROM Participant__c ';
        query += 'WHERE (User__c = :recordId ';
        query += 'OR Contact__c = :recordId ';
        query += 'OR Group__c = :recordId) ';
		query += 'AND ((Meeting__r.All_Day_Date__c >= :rangeStartDate AND Meeting__r.All_Day_Date__c < :rangeEndDate) ';
		query += 'OR (DAY_ONLY(convertTimezone(Meeting__r.Start_Date_Time__c)) >= :rangeStartDate AND DAY_ONLY(convertTimezone(Meeting__r.End_Date_Time__c)) < :rangeEndDate)) ';
		// query += 'AND Meeting__r.Start_Date_Time__c >= :rangeStartDateTime ';
        // query += 'AND Meeting__r.End_Date_Time__c < :rangeEndDateTime ';
        query += 'ORDER BY Meeting__r.Start_Date_Time__c ASC';
        System.debug('query ' + query);
        Integer minimumWidth = 1;
        for(Participant__c participant : Database.query(query))
        {
            Meeting__c meeting = participant.Meeting__r;
            System.debug('meeting participant.Meeting__r.Description__c ' + participant.Meeting__r.Description__c);
            Datetime meetingStart = participant.Meeting__r.Start_Date_Time__c;
            Datetime meetingEnd = participant.Meeting__r.End_Date_Time__c;

            if(meetingStart >= currentDay.endDateTime)
            {
                if(meetingStart.date() > currentDay.endDateTime.date())
                {
                    if(!currentBlock.isFree
                        && currentDay.endDateTime > currentBlock.endDateTime)
                    {
                        currentDay.blocks.add(currentBlock);
                        previousBlock = currentBlock;

                        Block freeBlock = new Block();
                        freeBlock.startDateTime = currentBlock.endDateTime;

                        currentBlock = freeBlock;
                    }
                    currentBlock.endDateTime = currentDay.endDateTime;
                    if(currentBlock.width >= minimumWidth)
                    {
                        currentDay.blocks.add(currentBlock);
                        previousBlock = currentBlock;
                    }
                    else
                    {
                        previousBlock.endDateTime = currentBlock.endDateTime;
                    }
                    days.add(currentDay);
                    dayStartDateTime = dayStartDateTime.addDays(1);
                    currentDay = new Day(dayStartDateTime);
                    currentBlock = new Block(dayStartDateTime);

                    // end current block
                    // add current block to day
                    // add day to day list
                    // increment dayStartDateTime
                    // set current day to new Day
                    // set current block to new Block
                    while (meetingStart.date() > dayStartDateTime.date()) {
                        currentBlock.endDateTime = currentDay.endDateTime;
                        currentDay.blocks.add(currentBlock);
                        days.add(currentDay);
                        dayStartDateTime = dayStartDateTime.addDays(1);
                        currentDay = new Day(dayStartDateTime);
                        currentBlock = new Block(dayStartDateTime);
                    }
                }
                else
                {
                    // A Meeting that is today, after the end of day
                    continue;
                }
            }

            if(currentBlock.isFree)
            {
                if(meetingStart == currentBlock.startDateTime)
                {
                    currentBlock.isFree = false;
                    currentBlock.endDateTime = meetingEnd;
                    System.debug('meeting ' + meeting);
                    currentBlock.meeting = meeting;
                }
                else if(meetingStart > currentBlock.startDateTime)
                {
                    currentBlock.endDateTime = meetingStart;
                    if(currentBlock.width >= minimumWidth)
                    {
                        currentDay.blocks.add(currentBlock);
                        previousBlock = currentBlock;
                    }
                    else
                    {
                        previousBlock.endDateTime = currentBlock.endDateTime;
                    }
                    System.debug('meeting ' + meeting);
                    currentBlock = new Block(meeting);
                }
            }
            else
            {
                if(meetingStart == currentBlock.startDateTime)
                {
                    continue;
                }
                else if(meetingStart > currentBlock.endDateTime)
                {
                    if(currentBlock.width >= minimumWidth)
                    {
                        currentDay.blocks.add(currentBlock);
                        previousBlock = currentBlock;
                    }
                    else
                    {
                        previousBlock.endDateTime = currentBlock.endDateTime;
                    }

                    Block freeBlock = new Block();
                    freeBlock.startDateTime = currentBlock.endDateTime;
                    freeBlock.endDateTime = meetingStart;

                    if(freeBlock.width >= minimumWidth)
                    {
                        currentDay.blocks.add(freeBlock);
                        previousBlock = freeBlock;
                    }
                    else
                    {
                        previousBlock.endDateTime = freeBlock.endDateTime;
                    }

                    System.debug('meeting ' + meeting);
                    currentBlock = new Block(meeting);
                }
                else if(meetingStart > currentBlock.startDateTime)
                {
                    currentBlock.endDateTime = meetingStart;

                    if(currentBlock.width >= minimumWidth)
                    {
                        currentDay.blocks.add(currentBlock);
                        previousBlock = currentBlock;
                    }
                    else
                    {
                        previousBlock.endDateTime = currentBlock.endDateTime;
                    }

                    System.debug('meeting ' + meeting);
                    currentBlock = new Block(meeting);
                }
            }
        }

        if(!currentBlock.isFree
            && currentDay.endDateTime > currentBlock.endDateTime)
        {
            currentDay.blocks.add(currentBlock);
            previousBlock = currentBlock;
            Block freeBlock = new Block(currentBlock.endDateTime);
            currentBlock = freeBlock;
        }

        while (rangeEndDateTime.date() > currentBlock.startDateTime.date())
        {
            System.debug('line 263: in outer while loop ' + rangeEndDateTime + ' current block: ' + currentBlock);
            currentBlock.endDateTime = currentDay.endDateTime;
            currentDay.blocks.add(currentBlock);
            days.add(currentDay);
            dayStartDateTime = dayStartDateTime.addDays(1);
            currentDay = new Day(dayStartDateTime);
            currentBlock = new Block(dayStartDateTime);
        }

        if(currentBlock.isFree || currentBlock.endDateTime > currentDay.endDateTime)
        {
            currentBlock.endDateTime = currentDay.endDateTime;
        }

        if(currentBlock.width >= minimumWidth)
        {
            currentDay.blocks.add(currentBlock);
            previousBlock = currentBlock;
        }
        else
        {
            previousBlock.endDateTime = currentBlock.endDateTime;
        }

        if(currentBlock.endDateTime < currentDay.endDateTime && !currentBlock.isFree)
        {
            Block freeBlock = new Block();
            freeBlock.startDateTime = currentBlock.endDateTime;
            freeBlock.endDateTime = currentDay.endDateTime;

            if(freeBlock.width >= minimumWidth)
            {
                currentDay.blocks.add(freeBlock);
                previousBlock = freeBlock;
            }
            else
            {
                previousBlock.endDateTime = freeBlock.endDateTime;
            }
        }

        days.add(currentDay);

        return days;
    }

    @AuraEnabled
    public static List<Day> getSchedulerHeaders(Datetime rangeStartDateTime, Datetime rangeEndDateTime)
    {
        List<Day> days = new List<Day>();

        Datetime dayStartDateTime = Datetime.newInstance(rangeStartDateTime.date(), Scheduling.startTime);
        Datetime dayEndDateTime = Datetime.newInstance(rangeEndDateTime.date(), Scheduling.endTime);
        Day currentDay = new Day(dayStartDateTime);
        Block currentBlock = new Block(dayStartDateTime);

        System.debug('dayEndDateTime ' + dayEndDateTime);
        while(currentBlock.startDateTime < dayEndDateTime)
        {
            System.debug('currentBlock.endDateTime ' + currentBlock.endDateTime);
            if(currentBlock.startDateTime < currentDay.endDateTime)
            {
                currentBlock.endDateTime = currentBlock.startDateTime.addHours(1);
                currentDay.blocks.add(currentBlock);
                if(currentBlock.endDateTime == dayEndDateTime)
                {
                    days.add(currentDay);
                    break;
                }
                currentBlock = new Block(currentBlock.endDateTime);
            }
            else
            {
                days.add(currentDay);
                dayStartDateTime = dayStartDateTime.addDays(1);
                currentDay = new Day(dayStartDateTime);
                currentBlock = new Block(dayStartDateTime);
            }
        }

        return days;
    }

    private static List<Scheduling_Resource__c> getSchedulingResourcesForMeetingTimes(
        Id currentResourceId,
        Datetime newMeetingStartDateTime,
        Datetime newMeetingEndDateTime)
    {
        System.debug('currentResourceId ' + currentResourceId);
        return [SELECT Id, Name, Building__c, Room__c,
            (SELECT Id, Start_Date_Time__c, End_Date_Time__c FROM Meetings__r
                WHERE (Start_Date_Time__c <= :newMeetingStartDateTime
                    AND End_Date_Time__c <= :newMeetingEndDateTime
                    AND End_Date_Time__c > :newMeetingStartDateTime)
                OR (Start_Date_Time__c >= :newMeetingStartDateTime
                    AND Start_Date_Time__c < :newMeetingEndDateTime
                    AND End_Date_Time__c >= :newMeetingEndDateTime)
                OR (Start_Date_Time__c < :newMeetingStartDateTime
                    AND End_Date_Time__c > :newMeetingEndDateTime)
                OR (Start_Date_Time__c >= :newMeetingStartDateTime
                    AND End_Date_Time__c <= :newMeetingEndDateTime))
            FROM Scheduling_Resource__c ORDER BY Order__c ASC, Name ASC];
    }

    @AuraEnabled
    public static List<Scheduling_Resource__c> getAvailableSchedulingResourcesForMeetingTimes(
            Id currentResourceId,
            Datetime newMeetingStartDateTime,
            Datetime newMeetingEndDateTime)
    {
        List<Scheduling_Resource__c> availableResources = new List<Scheduling_Resource__c>();
        for(Scheduling_Resource__c schedulingResource : getSchedulingResourcesForMeetingTimes(
            currentResourceId, newMeetingStartDateTime, newMeetingEndDateTime)
        )
        {
            if(schedulingResource.Meetings__r == null || schedulingResource.Meetings__r.isEmpty() ||
                schedulingResource.Id == currentResourceId)
            {
                availableResources.add(schedulingResource);
            }
        }
        return availableResources;
    }

    public class Options
    {
        public String context {get; set;} //Custom Calendar, User Schedule
        public String type {get; set;} //User, Contact, MeetingType, RoomName
        public Set<Id> personOrGroupIds {get; set;}
        public Set<String> meetingTypes {get; set;}
        public Set<String> roomNames {get; set;}
        public Datetime rangeStart {get; set;}
		public Datetime rangeEnd {get; set;}
		public Boolean showAllStaff {get;set;}

        public String aggregatedField {get; set;}
        public Set<String> aggregatedValues {get; set;}
        public Set<String> excludedValues {get; set;}

        public String currentViewOptionSetId {get; set; }

        public Options()
        {
            this.aggregatedValues = new Set<String>();
        }
    }

    public class Calendar
    {
        @AuraEnabled
        public Date startDate;
        @AuraEnabled
        public List<Meeting> events = new List<Meeting>();
        @AuraEnabled
		public Options options;


    }

    public class Meeting
    {
        @AuraEnabled
        public Meeting__c meeting;
        @AuraEnabled
        public Participant__c participant;
        @AuraEnabled
		public String id;
		@AuraEnabled
        public Boolean isAllDay = false;
        @AuraEnabled
		public Date allDayDate;
        @AuraEnabled
        public Datetime startDateTime;
        @AuraEnabled
        public Datetime endDateTime;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String color;
        @AuraEnabled
        public String textColor;
        @AuraEnabled
        public Boolean isRecurring = false;
		@AuraEnabled
		public List<Group_Note__c> groupNotes = new List<Group_Note__c>();

        // public Meeting(Participant__c participant)
        // {
        //     this.participant = participant;
        //     this.id = participant.Meeting__c;
        //     this.startDateTime = participant.Meeting__r.Start_Date_Time__c;
        //     this.endDateTime = participant.Meeting__r.End_Date_Time__c;
        //     this.title = participant.Meeting__r.Subject__c;
        //     this.description = participant.Meeting__r.Description__c;
        //     if(participant.Meeting__r.Recurrence__c != null)
        //     {
        //         this.isRecurring = true;
        //     }
        //     this.meeting = participant.Meeting__r;
        // }

        public Meeting(Meeting__c meeting)
        {
            this.meeting = meeting;
			this.id = meeting.Id;
			this.isAllDay = meeting.All_Day_Meeting__c;
			this.allDayDate = meeting.All_Day_Date__c;
            if (meeting.All_Day_Meeting__c == true)
            {
                this.startDateTime = DateTime.newInstanceGMT(meeting.All_Day_Date__c.year(), meeting.All_Day_Date__c.month(), meeting.All_Day_Date__c.day());
            } else
            {
                this.startDateTime = meeting.Start_Date_Time__c;
            }
            this.endDateTime = meeting.End_Date_Time__c;
			this.title = meeting.Subject__c + 
				(meeting.Room_Resource__r != null && meeting.Room_Resource__r.Short_Name__c != null ?
					' (' + meeting.Room_Resource__r.Short_Name__c + ')' : '');
            // if (meeting.Patient_Account__c != null)
            // {
            //     this.title = meeting.Patient_Account__r.Name + ' - ' + meeting.Meeting_Type__c;
            // }
            this.description = meeting.Description__c;
            if(meeting.Recurrence__c != null)
            {
                this.isRecurring = true;
            }
            System.debug('Meeting info for ' + this.title + ' startDateTime: ' + this.startDateTime);
        }
    }

    public class UserResponse
    {
        @AuraEnabled
        public User user;
        @AuraEnabled
        public Boolean isScheduleManager = false;
    }

    public class Day
    {
        @AuraEnabled
        public Date dateOfDay;
        @AuraEnabled
        public Datetime startDateTime;
        @AuraEnabled
        public Datetime endDateTime;
        @AuraEnabled
        public List<Block> blocks = new List<Block>();

        public Day(Datetime dayStartDateTime)
        {
            this.startDateTime = dayStartDateTime;
            this.endDateTime = Datetime.newInstance(dayStartDateTime.date(), Scheduling.endTime);
            this.dateOfDay = dayStartDateTime.date();
        }
    }

    public class Block
    {
        private Long dayTimeDifferenceInMinutes = DateUtils.timeDifferenceInMinutes(Scheduling.startTime, Scheduling.endTime);
        @AuraEnabled
        public Boolean isFree = true;
        @AuraEnabled
        public Meeting__c meeting;
        @AuraEnabled
        public Datetime startDateTime;
        @AuraEnabled
        public Datetime endDateTime
        {
            get;
            set
            {
                endDateTime = setEndDateTime(value);
            }
        }
        @AuraEnabled
        public Decimal width;

        public Block()
        {

        }

        public Block(Datetime startDateTime)
        {
            this.startDateTime = startDateTime;
        }

        public Block(Meeting__c meeting)
        {
            this.isFree = false;
            this.meeting = meeting;
            this.startDateTime = meeting.Start_Date_Time__c;
            this.endDateTime = meeting.End_Date_Time__c;
        }

        private Datetime setEndDateTime(Datetime endDateTime)
        {
            Long timeDifferenceInMinutes = DateUtils.timeDifferenceInMinutes(this.startDateTime, endDateTime);
            Decimal widthPercentage = (Decimal)timeDifferenceInMinutes / dayTimeDifferenceInMinutes;
            Decimal roundedValue = widthPercentage.setScale(4, RoundingMode.HALF_EVEN);
            this.width = roundedValue * 100;
            return endDateTime;
        }
    }
    private static Date convertDatetimeToDateWithoutTimeInformation(Datetime dt) {
        return Date.newInstance(dt.year(), dt.month(), dt.day());
    }
}
/**
 * NoteAttendance Controller class for the component.
 */
public class NoteAttendanceCtl 
{
    public static Map<Integer,String> monthMap=new Map<Integer,String>
    {
        1=>'January',
        2=>'February',
        3=>'March',
        4=>'April',
        5=>'May',
        6=>'June',
        7=>'July',
        8=>'August',
        9=>'September',
        10=>'October',
        11=>'November',
        12=>'December'
    };
        
    @AuraEnabled
    public static NoteAttendanceBundle getMeetings(Date contactDate, String patientId, String noteId)
    {
        Map<String, NoteAttendanceMeeting> meetingTypeMap = new Map<String, NoteAttendanceMeeting>();
		List<Participant__c> participantList = NoteAttendanceCtl.getAllMeetings(UserInfo.getUserId(), patientId, noteId, contactDate.month(), contactDate.year());
        String attendedDates = '';
        String unattendedDates = '';
        String unknownDates = '';
        // System.debug('NoteAttendanceCtl getMeetings participantList: ' + participantList);
        for(Participant__c participant : participantList)
        {
            // We only process the records that have proper start date time
            if(participant.Meeting__r.Start_Date_Time__c != null)// || participant.Meeting__r.All_Day_Date__c != null)
            {
                NoteAttendanceMeeting meetingType = meetingTypeMap.get(participant.Meeting__r.Meeting_Type__c);
                if(meetingType == null)
                {
                    meetingType = new NoteAttendanceMeeting(participant.Meeting__r.Meeting_Type__c);
                    // meetingType.attended = '';
                    // meetingType.didNotAttend = '';
                    // meetingType.unknown = '';
                    // meetingType.meetingType = participant.Meeting__r.Meeting_Type__c;
                }
                Meeting__c theMeeting = participant.Meeting__r;

                //ARC-2512 schedule within patient note doesn't show early morning meetings on 1st of the month
                //theMeeting.Start_Date_Time__c is stored in GMT timezone such as 2022-09-01 02:30:00
                //the following three lines of code convert the timezone of theMeeting.Start_Date_Time__c from GMT to current user's timezone
                //TimeZone targetTZ = UserInfo.getTimeZone();
                TimeZone targetTZ = Timezone.getTimeZone('America/New_York');
                integer offsetTotargetTZ = targetTZ.getOffset(theMeeting.Start_Date_Time__c);
                DateTime targetDT = theMeeting.Start_Date_Time__c.addMinutes(offsetTotargetTZ / (1000 * 60));

                Date meetingDate = Date.valueOf(targetDT);
                
                if ('attended'.equalsIgnoreCase(participant.Meeting__r.Patient_Attendance__c))
                {
                    Map<Id, Meeting__c> mtgMap = meetingType.attendedDateMap.get(meetingDate);
                    if (mtgMap == null) mtgMap = new Map<Id, Meeting__c>();
                    mtgMap.put(theMeeting.Id, theMeeting);
                    meetingType.attendedDateMap.put(meetingDate, mtgMap);
                    // if(String.isNotBlank(meetingType.attended))
                    // {
                    //     meetingType.attended += ', ';
                    // }
                    // else
                    // {
                    //     meetingType.attended = monthMap.get(contactDate.month()) + ' ';
                    // }
                    // meetingType.attended += participant.Meeting__r.Start_Date_Time__c.day();
                    attendedDates += participant.Meeting__r.Start_Date_Time__c.format('MM/dd/yy', 'America/New_York') + ', ';
                }
                else if ('did not attend'.equalsIgnoreCase(participant.Meeting__r.Patient_Attendance__c))
                {
                    Map<Id, Meeting__c> mtgMap = meetingType.didNotAttendDateMap.get(meetingDate);
                    if (mtgMap == null) mtgMap = new Map<Id, Meeting__c>();
                    mtgMap.put(theMeeting.Id, theMeeting);
                    meetingType.didNotAttendDateMap.put(meetingDate, mtgMap);
                    // if(String.isNotBlank(meetingType.didNotAttend))
                    // {
                    //     meetingType.didNotAttend += ', ';
                    // }
                    // else
                    // {
                    //     meetingType.didNotAttend = monthMap.get(contactDate.month()) + ' ';
                    // }
                    // meetingType.didNotAttend += participant.Meeting__r.Start_Date_Time__c.day();
                    unattendedDates += participant.Meeting__r.Start_Date_Time__c.format('MM/dd/yy', 'America/New_York') + ', ';
                }
                else if ('unknown'.equalsIgnoreCase(participant.Meeting__r.Patient_Attendance__c))
                {
                    Map<Id, Meeting__c> mtgMap = meetingType.unknownDateMap.get(meetingDate);
                    if (mtgMap == null) mtgMap = new Map<Id, Meeting__c>();
                    mtgMap.put(theMeeting.Id, theMeeting);
                    meetingType.unknownDateMap.put(meetingDate, mtgMap);
                    // if(String.isNotBlank(meetingType.unknown))
                    // {
                    //     meetingType.unknown+=', ';
                    // }
                    // else
                    // {
                    //     meetingType.unknown=monthMap.get(contactDate.month())+' ';
                    // }
                    // meetingType.unknown += participant.Meeting__r.Start_Date_Time__c.day();
                    unknownDates += participant.Meeting__r.Start_Date_Time__c.format('MM/dd/yy', 'America/New_York') + ', ';
                }
                    // Map<Date, Map<Id, Meeting__c>> mtgDateMap;
                    // Map<Id, Meeting__c> mtgMap;
                    // String meetingTypeListString;
                    // String datesListString;
                    // if ('attended'.equalsIgnoreCase(participant.Meeting__r.Patient_Attendance__c))
                    // {
                    //     mtgDateMap = meetingType.attendedDateMap;
                    //     mtgMap = meetingType.attendedDateMap.get(meetingDate);
                    //     meetingTypeListString = meetingType.attended;
                    //     datesListString = attendedDates;
                    // } else if ('did not attend'.equalsIgnoreCase(participant.Meeting__r.Patient_Attendance__c))
                    // {
                    //     mtgDateMap = meetingType.attendedDateMap;
                    //     mtgMap = meetingType.didNotAttendDateMap.get(meetingDate);
                    //     meetingTypeListString = meetingType.didNotAttend;
                    //     datesListString = unattendedDates;
                    // } else if ('unknown'.equalsIgnoreCase(participant.Meeting__r.Patient_Attendance__c))
                    // {
                    //     mtgDateMap = meetingType.attendedDateMap;
                    //     mtgMap = meetingType.unknownDateMap.get(meetingDate);
                    //     meetingTypeListString = meetingType.unknown;
                    //     datesListString = unknownDates;
                    // } 
                    // if (mtgMap == null) mtgMap = new Map<Id, Meeting__c>();
                    // mtgMap.put(theMeeting.Id, theMeeting);
                    // if(String.isNotBlank(meetingTypeListString))
                    // {
                    //     meetingTypeListString += ', ';
                    // }
                    // else
                    // {
                    //     meetingTypeListString = monthMap.get(contactDate.month())+' ';
                    // }
                    // meetingTypeListString += participant.Meeting__r.Start_Date_Time__c.day();
                    // datesListString += participant.Meeting__r.Start_Date_Time__c.format('MM/dd/yy', 'America/New_York') + ', ';
                    // // meetingType.unknownDateMap.put(meetingDate, mtgMap);
                meetingTypeMap.put(participant.Meeting__r.Meeting_Type__c, meetingType);
            }
        }

        List<NoteAttendanceMeeting> meetingTypes = meetingTypeMap.values();
        
        NoteAttendanceBundle returnBundle = new NoteAttendanceBundle(meetingTypes);
        
        // System.debug('NoteAttendanceCtl getMeetings attendedDates: ' + attendedDates.removeEnd(', '));
        // System.debug('calculated attendedDates: ' + returnBundle.attendedDates);
        // System.debug('NoteAttendanceCtl getMeetings unattendedDates: ' + unattendedDates);
        // System.debug('NoteAttendanceCtl getMeetings unknownDates: ' + unknownDates);
        //removed 210504 JN. This was causing the "Patient Note was updated in another session" exception on the client
        // Patient_Note__c thisNote = new Patient_Note__c(
        //     Id = noteId,
        //     Attended_Meetings__c = attendedDates,
        //     Unattended_Meetings__c = unattendedDates,
        //     Unknown_Meeting_Attendance__c = unknownDates
        // );
        // update thisNote;
        return returnBundle;
    }
    
    @testVisible
    public static String concatenateDates(Map<Date, Map<Id, Meeting__c>> allDateMap)
    {
        String dateListString = '';
        
        List<Date> mtgDates = new List<Date>(allDateMap.keySet());
        mtgDates.sort();
        Integer month;
        Boolean firstMonth = TRUE;
        Boolean firstDate = TRUE;
        for (Date d : mtgDates)
        {
            if (month != d.month())
            {
                if (firstMonth)
                {
                    firstMonth = false;
                } else
                {
                    dateListString += ', ';
                }
                month = d.month();
                dateListString += monthMap.get(month) + ' ';
                firstDate = TRUE;
            }
            Integer mtgsForThisDate = allDateMap.get(d).size();
            
            for (Integer i = 0;  i < mtgsForThisDate; i++)
            {
                if (firstDate)
                {
                    firstDate = FALSE;
                } else
                {
                    dateListString += ', ';    
                }
                dateListString += d.day();
            }
            
        }
        return dateListString;
    }

    private static List<Participant__c> getAllMeetings(Id userId, Id patientId, Id noteId, Integer month, Integer year)
    {
        // system.debug('userId:'+userId+', patientId:'+patientId+', month:'+month+', year:'+year);
        List<Participant__c> participants = [
            SELECT Meeting__c, Meeting__r.Subject__c, Meeting__r.Start_Date_Time__c, Meeting__r.All_Day_Date__c, Meeting__r.All_Day_Meeting__c, 
                Meeting__r.Meeting_Type__c, Meeting__r.Patient_Attendance__c, Meeting__r.Monthly_Note__c, Meeting__r.Monthly_Note__r.Status__c
            FROM Participant__c 
            WHERE User__c = :userId 
                // AND (Meeting__r.Monthly_Note__c = null OR Meeting__r.Monthly_Note__c = :noteId)
                AND Meeting__r.Patient_Account__c = :patientId
                AND CALENDAR_MONTH(convertTimezone(Meeting__r.Start_Date_Time__c)) = :month
                AND CALENDAR_YEAR(convertTimezone(Meeting__r.Start_Date_Time__c)) = :year
            ORDER BY Meeting__r.Meeting_Type__c, Meeting__r.Patient_Attendance__c, Meeting__r.Start_Date_Time__c
        ];
        
        List<Meeting__c> decoupleMeetings = [
                SELECT Id, Monthly_Note__c , Patient_Account__c , Start_Date_Time__c 
                FROM Meeting__c  
                WHERE Patient_Account__c = :patientId
                AND CALENDAR_MONTH(Start_Date_Time__c) != :month
                AND Monthly_Note__c = :noteId];
        
        for(Meeting__c m : decoupleMeetings) {
            m.Monthly_Note__c = null;
        }

        if(decoupleMeetings.size() > 0) {
           update decoupleMeetings;
        }
        Map<Id, Meeting__c> meetingsToUpdateMap = new Map<Id, Meeting__C>();
        for (Participant__c parti: participants)
        {
            if (parti.Meeting__r.Monthly_Note__c == null)
            {
                Meeting__c meeting = new Meeting__c(
                    Id = parti.Meeting__c,
                    Monthly_Note__c = noteId
                );
                meetingsToUpdateMap.put(parti.Meeting__c, meeting);
            }
        }
        update meetingsToUpdateMap.values();
        return participants;
    }

    
    public class NoteAttendanceBundle
    {

        @AuraEnabled 
        public List<NoteAttendanceMeeting> meetingTypes;
        @AuraEnabled
        public String attendedDates { get; set;}
        @AuraEnabled
        public String unattendedDates { get; set;}
        @AuraEnabled
        public String unknownDates { get; set;}
        @AuraEnabled
        public String noteAttendanceHtml { get; set; } 
        
        public NoteAttendanceBundle(List<NoteAttendanceMeeting> meetingTypes)
        {
            this.meetingTypes = meetingTypes;
            this.attendedDates = '';
            this.unattendedDates = '';
            this.unknownDates = '';
            this.noteAttendanceHtml = '<table>'
                                        + '<theader>'
                                            + '<tr>'
                                                + '<th></th>'
                                                + '<th>Attended</th>'
                                                + '<th>Did Not Attend</th>'
                                                + '<th>Unknown</th>'
                                            + '</tr>'
                                        + '</theader>'
                                        + '<tbody>';
            
            this.addMeetingTypes(meetingTypes);
        }

        public void addMeetingTypes(List<NoteAttendanceMeeting> meetingTypes)
        {
            Boolean firstMeetingType = TRUE;
            for (NoteAttendanceMeeting meetingType : meetingTypes)
            {
                meetingType.buildConcatenatedDateLists();

                this.addMeetingType(meetingType, firstMeetingType);
                firstMeetingType = FALSE;     
            }
            this.noteAttendanceHtml += '</tbody></table>';
        }
        void addMeetingType(NoteAttendanceMeeting newMeetingType, Boolean firstMeetingType)
        {
            if (!firstMeetingType)
            {
                this.attendedDates += '\n\n';
                this.unattendedDates += '\n\n';
                this.unknownDates += '\n\n';
            }
            this.noteAttendanceHtml += '<tr>'
                                        + '<td>' + newMeetingType.meetingType + '</td>'
                                        + '<td>' + newMeetingType.attended + '</td>'
                                        + '<td>' + newMeetingType.didNotAttend + '</td>'
                                        + '<td>' + newMeetingType.unknown + '</td>'
                                    + '</tr>';            
            this.attendedDates += newMeetingType.meetingType + ': ' + newMeetingType.attended;
            this.unattendedDates += newMeetingType.meetingType + ': ' + newMeetingType.didNotAttend;
            this.unknownDates += newMeetingType.meetingType + ': ' + newMeetingType.unknown;
        }
    }

}
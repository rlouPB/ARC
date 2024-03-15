public class NoteAttendanceMeeting 
{
	@AuraEnabled
    public String meetingType{get;set;}
    
    @AuraEnabled
    public String attended{get;set;}
    @AuraEnabled
    public Map<Date, Map<Id, Meeting__c>> attendedDateMap = new Map<Date, Map<Id, Meeting__c>>();

    @AuraEnabled
    public String didNotAttend{get;set;}
    @AuraEnabled
    public Map<Date, Map<Id, Meeting__c>> didNotAttendDateMap = new Map<Date, Map<Id, Meeting__c>>();
    
    @AuraEnabled
    public String unknown{get;set;}
    @AuraEnabled
    public Map<Date, Map<Id, Meeting__c>> unknownDateMap = new Map<Date, Map<Id, Meeting__c>>();
   
    // public NoteAttendanceMeeting() {}
    public NoteAttendanceMeeting(String meetingType)
    {
        this.meetingType = meetingType;
        // this.attended = '';
        // this.didNotAttend = '';
        // this.unknown = '';
    }

    public void buildConcatenatedDateLists()
    {
        attended = NoteAttendanceCtl.concatenateDates(attendedDateMap);
        didNotAttend = NoteAttendanceCtl.concatenateDates(didNotAttendDateMap);
        unknown = NoteAttendanceCtl.concatenateDates(unknownDateMap);
    }

    // String concatenateDates(Map<Date, Map<Id, Meeting__c>> allDateMap)
    // {
    //     return NoteAttendanceCtl.concatenateDates(allDateMap);
        // String dateListString = '';
        
        // List<Date> mtgDates = new List<Date>(allDateMap.keySet());
        // mtgDates.sort();
        // Integer month;
        // Boolean firstMonth = TRUE;
        // Boolean firstDate = TRUE;
        // for (Date d : mtgDates)
        // {
        //     if (month != d.month())
        //     {
        //         if (firstMonth)
        //         {
        //             firstMonth = false;
        //         } else
        //         {
        //             dateListString += ', ';
        //         }
        //         month = d.month();
        //         dateListString += NoteAttendanceCtl.monthMap.get(month) + ' ';
        //         firstDate = TRUE;
        //     }
        //     Integer mtgsForThisDate = allDateMap.get(d).size();
            
        //     for (Integer i = 0;  i < mtgsForThisDate; i++)
        //     {
        //         if (firstDate)
        //         {
        //             firstDate = FALSE;
        //         } else
        //         {
        //             dateListString += ', ';    
        //         }
        //         dateListString += d.day();
        //     }
            
        // }
        // return dateListString;
    // }

}
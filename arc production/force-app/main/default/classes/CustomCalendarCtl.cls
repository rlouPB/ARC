public with sharing class CustomCalendarCtl 
{
    @AuraEnabled
    public static Map<String,object> initializeComponentData(){
        return new Map<String,object>{
            'hasCalendarShowGroupNote' => PermissionUtils.checkPerms('CalendarShowGroupNote'),
            'hasScheduleManager' => PermissionUtils.checkPerms('ScheduleManager')
        };
    }

    @AuraEnabled
    public static String getCalendar(String options)
    {
        Scheduling.Options schedulingOptions = (Scheduling.Options)JSON.deserialize(options, Scheduling.Options.class);
        System.debug('before calling Scheduling.getSchedule' + schedulingOptions);
        Scheduling.Calendar calendar = Scheduling.getSchedule(schedulingOptions);
        System.debug('getCalendar schedulingOptions from page ' + options);
        System.debug('getCalendar schedulingOptions from Scheduling ' + calendar.options);
        System.debug('CustomCalendarCtl getCalendar calendar: ' + calendar);
        return JSON.serialize(calendar);
    }

    @AuraEnabled
    public static String quickSaveMeeting_ctl(String serializedMeeting)
    {
        String returnString = '';
        try
        {
            Meeting__c meetingToUpdate = (Meeting__c)JSON.deserialize(serializedMeeting, Meeting__c.class);
            update meetingToUpdate;
            returnString = JSON.serialize(meetingToUpdate);
        } catch (Exception e)
        {
            returnString = JSON.serialize(e);
        }
        
        return returnString;
    }

    @AuraEnabled
    public static String deleteMeeting(Id meetingId)
    {
        return Scheduling.deleteMeeting(meetingId);
    }
    
    @AuraEnabled
    public static Scheduling.UserResponse getUser(String userId)
    {
        return Scheduling.getUser(userId);
    }

    

}
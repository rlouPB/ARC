@isTest
private class CustomCalendarCtlTest 
{
    static testmethod void testGetCalendar()
    {
        Scheduling.Options options = new Scheduling.Options();

        Test.startTest();

            Scheduling.Calendar testCalendar = (Scheduling.Calendar)JSON.deserialize( CustomCalendarCtl.getCalendar(JSON.serialize(options)), Scheduling.Calendar.class);
        System.debug(testCalendar);

        Test.stopTest();


    }
    
    @isTest
    private static void meetingUpdate()
    {
         Meeting__c meeting = new Meeting__c(
            Subject__c = 'Testing SUB',
            Start_Date_Time__c = DateTime.now(),
            All_Day_Date__c = Date.today()

        );
        insert meeting;
        Test.startTest();

         String meet = CustomCalendarCtl.quickSaveMeeting_ctl(JSON.serialize(meeting));
        Test.stopTest();
    }
    
    @isTest
    private static void userUpdate()
    {
        Test.startTest();
         CustomCalendarCtl.getUser(UserInfo.getUserId());
        CustomCalendarCtl.initializeComponentData();
        Test.stopTest();
    }

}
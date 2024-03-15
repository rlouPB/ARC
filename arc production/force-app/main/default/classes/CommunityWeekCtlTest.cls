@isTest
private class CommunityWeekCtlTest {
    private static final String SUBJECT = 'Test Subject';
    private static final String CASE_CONFERENCE = 'Case Conference';
    private static final String PATIENT_NAME = 'Patient';

    @TestSetup
    private static void makeData(){
        Id userId = Userinfo.getUserId();
        
        List<Scheduling_Resource__c> rooms = new List<Scheduling_Resource__c>();
        rooms.add(new Scheduling_Resource__c(Building__c = 'Building0', Name = 'Room0'));
        rooms.add(new Scheduling_Resource__c(Building__c = 'Building0', Name = 'Room1'));
        rooms.add(new Scheduling_Resource__c(Building__c = 'Building0', Name = 'Room2'));
        insert rooms;

        Group__c groupsToInsert = new Group__c(
            Name = 'this group'
        );
        insert groupsToInsert;

        Account ptAccount = new Account(
            Name = PATIENT_NAME,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId()
        );
        insert ptAccount;

        Contact patientContacts = new Contact(
            LastName = 'patientZero',
            RecordtypeId = [select Id from Recordtype where sObjectType = 'Contact' and Name = 'Patient' LIMIT 1].Id,
            AccountId = ptAccount.Id
        );
        insert patientContacts;

        Meeting__c meeting = new Meeting__c(
            Subject__c = SUBJECT,
            Start_Date_Time__c = DateTime.now(),
            Staff_Group_Meeting_Type__c = CASE_CONFERENCE,
            All_Day_Date__c = Date.today(),
            Patient_Account__c = ptAccount.Id

        );
        insert meeting;

        List<Patient_Group_Member__c> patientGMsToInsert = new List<Patient_Group_Member__c>();
        patientGMsToInsert.add(new Patient_Group_Member__c(
            Group_Name__c = groupsToInsert.Id,
            Patient__c = patientContacts.Id,
            Role__c = 'Member',
            Start_Date__c = system.today().addDays(-100)
        ));
        insert patientGMsToInsert;

        Date today = system.today();
        Datetime baseTime = Datetime.newInstance(today.year(), today.month(), today.day(), 12, 0, 0); //noon today

        List<Datetime> meetingTimes = new List<Datetime> {
            baseTime.addDays(-100),
            baseTime.addDays(-1),
            baseTime.addDays(1),
            baseTime.addDays(100)
        };


        Participant__c newPart = new Participant__c(
            Meeting__c = meeting.Id,
            User__c = userId
            
        );
        insert newPart;
    }

    @isTest
    private static void getWeekTest() {
        Scheduling.Options options = new Scheduling.Options();
        options.type = 'PatientFocus';
        options.personOrGroupIds = new Set<Id> { [select Id, AccountId from Contact LIMIT 1].Id, [SELECT Id FROM Account LIMIT 1].Id, UserInfo.getUserId() };
        options.rangeStart = system.now().addDays(-7);
        options.rangeEnd = system.now().addDays(7);


        Scheduling.Calendar calendars = new Scheduling.Calendar();
        calendars.startDate = Date.today();

        CommunityWeekCtl.getWeek(options);
    }
    
     @isTest
    private static void getWeekStringTest() {
        Scheduling.Options options = new Scheduling.Options();
        options.type = 'PatientFocus';
        options.personOrGroupIds = new Set<Id> { [select Id, AccountId from Contact LIMIT 1].Id, [SELECT Id FROM Account LIMIT 1].Id, UserInfo.getUserId() };
        options.rangeStart = system.now().addDays(-7);
        options.rangeEnd = system.now().addDays(7);


        Scheduling.Calendar calendars = new Scheduling.Calendar();
        calendars.startDate = Date.today();

        CommunityWeekCtl.getWeek(JSON.serialize(options));
    }
}
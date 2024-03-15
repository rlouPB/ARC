@isTest
public class NursingSignInOutServiceTest {
    private static final String SHIFT_NUMBER = '1st';
    private static final String STATUS = 'Open';
    private static final String TYPE_OF_DATE = 'Weekday';

    @TestSetup
    static void initiateData() {
        Nursing_Shift__c nursingShift = new Nursing_Shift__c(
            Shift_Number__c = SHIFT_NUMBER, 
            Date__c = Date.Today(), 
            Status__c = STATUS, 
            Shift_Open_Date_Time__c = System.now(),
            Type_of_Day__c = TYPE_OF_DATE
        );
        insert nursingShift;

        Nursing_Shift_Assignment__c nightShiftAssignment = new Nursing_Shift_Assignment__c(
            Owner__c = UserInfo.getUserId(),
            OwnerId = UserInfo.getUserId(),
            Nursing_Shift__c = nursingShift.Id,
            Sign_In_Date_Time__c = System.now(),
            Status__c = STATUS
        );
        insert nightShiftAssignment;
    }

    @isTest
    private static void getNursingShiftSingleTest() {
        List<Nursing_Shift__c> nursingShift = [SELECT Id, Name FROM Nursing_Shift__c];

        Test.startTest();
        Nursing_Shift__c nursingResponse = NursingSignInOutService.getNursingShiftSingle(nursingShift[0].Id);
        Test.stopTest();

        System.assertEquals(nursingShift[0].Id, nursingResponse.Id);
    }

    @isTest
    private static void getMyNursingShiftAssigmentsTest() {
        Test.startTest();
        List<Nursing_Shift_Assignment__c> nursingShiftAssignmentResponse = NursingSignInOutService.getMyNursingShiftAssigments();
        Test.stopTest();

        System.assert(!nursingShiftAssignmentResponse.isEmpty());
    }

    @isTest
    private static void signIntoShiftTest() {
        List<Nursing_Shift__c> nursingShift = [SELECT Id, Name FROM Nursing_Shift__c];

        Test.startTest();
        String signInShift = NursingSignInOutService.signIntoShift(nursingShift[0].Id);
        Test.stopTest();

        System.assert(String.isBlank(signInShift));
    }

    @isTest
    private static void signOutFromShiftTest() {
        List<Nursing_Shift_Assignment__c> nursingShiftAssignment = [SELECT Id FROM Nursing_Shift_Assignment__c];

        Test.startTest();
        String signOutShift = NursingSignInOutService.signOutFromShift(nursingShiftAssignment[0].Id);
        Test.stopTest();

        System.assert(String.isBlank(signOutShift));
    }

    @isTest
    private static void getSignInOutDataTest() {
        List<Nursing_Shift__c> nursingShift = [SELECT Id, Name FROM Nursing_Shift__c];

        Test.startTest();
        List<Object> signInOutData = NursingSignInOutService.getSignInOutData();
        Test.stopTest();

        System.assert(!signInOutData.isEmpty());
    }

    @isTest
    private static void nursingShiftWrapperTest() {
        List<Nursing_Shift__c> nursingShift = [SELECT Id, Name, Shift_Open_Date_Time__c FROM Nursing_Shift__c];

        Test.startTest();
        NursingSignInOutService.nursingShiftWrapper wrapper = new NursingSignInOutService.nursingShiftWrapper(nursingShift[0]);
        Test.stopTest();

        System.assert(wrapper != null);
    }
}
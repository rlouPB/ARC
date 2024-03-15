@isTest
private class CaseTriggerHandlerTest {

    @TestSetup
    static void makeData()
    {
        Profile riggsClinicalProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'RiggsClinical'
            LIMIT 1
        ];

        List<User> usersToInsert = new List<User>();
        User testUser1 = new User(
            FirstName = 'Access Pass Test 1',
            LastName = 'Test',
            ProfileId = riggsClinicalProfile.Id,
            Username = 'testuser1@austenriggs.net.Phase2Dev',
            Email = 'accessPassTest@example.com',
            Alias = 'test1',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
        usersToInsert.add(testUser1);
        insert usersToInsert;

        List<Account> accountsToInsert = new List<Account>();
        Account testPatient1 = new Account(
            Name = 'Access Pass Test Patient 1'
        );
        accountsToInsert.add(testPatient1);
        insert accountsToInsert;

        List<Admission__c> admissionsToInsert = new List<Admission__c>();
        Admission__c testAdm1 = new Admission__c(
            Patient_Account__c = testPatient1.Id
        );
        admissionsToInsert.add(testAdm1);
        insert admissionsToInsert;
        
        Account testPatient = [
            SELECT Id
            FROM Account
            WHERE Name = 'Access Pass Test Patient 1'
            LIMIT 1
        ];
        Admission__c testAdm = [
            SELECT Id
            FROM Admission__c
            WHERE Patient_Account__r.Name = 'Access Pass Test Patient 1'
            LIMIT 1
        ];
        User testUser = [
            SELECT Id
            FROM User
            WHERE Email = 'accessPassTest@example.com'
        ];

        Test.startTest();
        Case testCase = new Case(
            AccountId = testPatient.Id,
            Admission__c = testAdm.Id
        );
        insert testCase;
        
    }

    @isTest
    private static void testCreation()
    {
        Account testPatient = [
            SELECT Id
            FROM Account
            WHERE Name = 'Access Pass Test Patient 1'
            LIMIT 1
        ];
        Admission__c testAdm1 = [
            SELECT Id
            FROM Admission__c
            WHERE Patient_Account__r.Name = 'Access Pass Test Patient 1'
            LIMIT 1
        ];
        User testUser = [
            SELECT Id
            FROM User
            WHERE Email = 'accessPassTest@example.com'
        ];

        Test.startTest();
        Case testCase = new Case(
            AccountId = testPatient.Id,
            Admission__c = testAdm1.Id
        );
        insert testCase;
        Test.stopTest();
    }
    @istest
    public static void updatetest(){
        case c=[select id from case where Account.name='Access Pass Test Patient 1' limit 1];
        update c;
    }
       @istest
    public static void deletetest(){
        case c2=[select id from case where Account.name='Access Pass Test Patient 1' limit 1];
        delete c2;
        
  
    }

}
@isTest
private class InterventionTriggerHandlerTest {

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
            FirstName = 'Intervention Test 1',
            LastName = 'Test',
            ProfileId = riggsClinicalProfile.Id,
            Username = 'testuser1@austenriggs.net.Phase2Dev',
            Email = 'interventionPassTest@example.com',
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
            Name = 'Intervention Test Patient 1'
        );
        accountsToInsert.add(testPatient1);
        insert accountsToInsert;

        List<Admission__c> admissionsToInsert = new List<Admission__c>();
        Admission__c testAdm1 = new Admission__c(
            Patient_Account__c = testPatient1.Id
        );
        admissionsToInsert.add(testAdm1);
        insert admissionsToInsert;

        List<Case> casesToInsert = new List<Case>();
        Case testCase1 = new Case(
            AccountId = testPatient1.Id,
            Admission__c = testAdm1.Id
        );
        casesToInsert.add(testCase1);
        insert casesToInsert;
    }

    @isTest
    private static void testCreation()
    {
        Case testCase = [
            SELECT Id
            FROM Case
            WHERE Account.Name = 'Intervention Test Patient 1'
        ];

        Test.startTest();
        Intervention__c testIntervention = new Intervention__c(
            Case__c = testCase.Id
        );
        insert testIntervention;
        Test.stopTest();
    }

}
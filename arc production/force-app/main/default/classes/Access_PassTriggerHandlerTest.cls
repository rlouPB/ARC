@isTest
private class Access_PassTriggerHandlerTest {

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
        
       
        EGO__c testEGO = new EGO__c(
            Admission__c = admissionsToInsert[0].Id
        );
        insert testEGO;
        
        EGO_Rating__c er= new EGO_Rating__c(
              EGO__c=testEGO.Id
        );
        insert er;
        
        
        Goal__c gl=new Goal__c();
        gl.Name='testgoal';
        gl.Domain_Metadata_ID__c='12345';
        insert gl;
        
        case cc= new case();
        cc.AccountId=accountsToInsert[0].id;
        cc.Goal__c=gl.Id;
        
        insert cc;
        Intervention__c itt= new Intervention__c();
        itt.Name='Test Intervention';
        itt.Case__c=cc.Id;
        insert itt;
        Objective__c ob=new Objective__c();
        ob.Goal__c=gl.Id;
        insert ob;
        
        
         Access_Pass__c testAccessPass = new Access_Pass__c(
            Patient__c = accountsToInsert[0].Id,
            Requesting_User__c = usersToInsert[0].Id
        );
        insert testAccessPass;
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
        User testUser = [
            SELECT Id
            FROM User
            WHERE Email = 'accessPassTest@example.com'
        ];

        Test.startTest();
        Access_Pass__c testAccessPass = new Access_Pass__c(
            Patient__c = testPatient.Id,
            Requesting_User__c = testUser.Id
        );
        insert testAccessPass;
        Test.stopTest();
    }
     @istest
    public static void testupdate()
    {
        Access_Pass__c acpass=[Select id from Access_Pass__c limit 1];
      update acpass;
    }
     @istest
    public static void testdelete()
    {
        Access_Pass__c acpass=[Select id from Access_Pass__c limit 1];
      delete acpass;
    }
}
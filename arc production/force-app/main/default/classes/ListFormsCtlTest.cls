@isTest
public class ListFormsCtlTest {
    public ListFormsCtlTest() {

    }

    @testSetup
    static void makeData(){
        
        UserRole testRole = new UserRole(name = 'TEST ROLE');
        insert testRole;
        
        User thisUser = [Select Id, EmailEncodingKey, LanguageLocaleKey, LocaleSidKey, TimeZoneSidKey, UserRoleId, ProfileId
            FROM User
            WHERE Id = :UserInfo.getUserId()];

        Profile profile = [Select Id, Name, UserType
            FROM Profile
            WHERE Name LIKE 'ARC Patient%' LIMIT 1];

        System.debug('thisUser UserRoleId: ' + thisUser.UserRoleId);

        User adminUser = new User();
        adminUser.ProfileId = thisUser.ProfileId;
        adminUser.UserRoleId = testRole.Id;
        adminUser.FirstName = 'Test';
        adminUser.LastName = 'AdminUser';
        adminUser.Username = 'testadminuser@123example.austenriggs.com';
        adminUser.Email = 'testadminuser@example.com';
        adminUser.Alias = 'tauser';
        adminUser.EmailEncodingKey = thisUser.EmailEncodingKey;
        adminUser.LanguageLocaleKey = thisUser.LanguageLocaleKey;
        adminUser.LocaleSidKey = thisUser.LocaleSidKey;
        adminUser.TimezoneSidKey = thisUser.TimezoneSidKey;

        insert adminUser;

        System.runAs(adminUser)
        {
            // UserRole r = new UserRole(name = 'TEST ROLE');
            // insert r;
            Id accPatientRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordtypeId();
            Id conPatientRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordtypeId();
            Id rcPatientRtId = Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName().get('Patient').getRecordtypeId();

            Account acc = new Account(name = 'Test Person', RecordtypeId = accPatientRtId);
            insert acc;
            Contact con = new Contact(FirstName = 'Test', LastName = 'Person', AccountId = acc.Id, RecordtypeId = conPatientRtId);
            insert con;
            acc.Patient_Contact__c = con.Id;
            acc.Owner = adminUser;
            update acc;
            Related_Contact__c relCon = new Related_Contact__c(Contact__c = con.Id, Account__c = acc.Id, RecordtypeId = rcPatientRtId, Role__c = 'Patient');
            insert relCon;

            System.debug('Contact Id: ' + con.Id + 'Account Id: ' + acc.Id + 'Account patient contact: ' + acc.Patient_Contact__c);
            System.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());

            User portalUser = new User();
            portalUser.ContactId = con.Id;
            portalUser.ProfileId = profile.Id;
            // u.UserRoleId = r.Id;
            portalUser.FirstName = 'Test';
            portalUser.LastName = 'PortalUser';
            portalUser.Username = 'testportaluser@123example.austenriggs.com';
            portalUser.Email = 'testportaluser@example.com';
            portalUser.Alias = 'tpuser';
            portalUser.EmailEncodingKey = thisUser.EmailEncodingKey;
            portalUser.LanguageLocaleKey = thisUser.LanguageLocaleKey;
            portalUser.LocaleSidKey = thisUser.LocaleSidKey;
            portalUser.TimezoneSidKey = thisUser.TimezoneSidKey;

            insert portalUser;

            System.debug(portalUser);

            disco__Form_Template__c testFormTemplate = new disco__Form_Template__c(Name = 'Test Form Template', disco__Status__c = 'In Use');
            testFormTemplate.Forms_Allowed_in_Community__c = true;
            insert testFormTemplate;
            disco__Form__c testForm = new disco__Form__c(disco__Form_Template__c = testFormTemplate.Id, disco__Form_Account__c = acc.Id, disco__Form_Contact__c = con.Id);
            testForm.Available_in_Community__c = true;
            insert testForm;
        }
    }
    
    @isTest
    static void testRefreshFormsListNoUserId()
    {
        User userForTesting = [SELECT Id FROM User WHERE Username LIKE 'testportaluser%' LIMIT 1];
        System.runAs(userForTesting)
        {
            Test.startTest();
            String context = 'community';
            List<String> fields = new List<String>();
            fields.add('Name');

            List<disco__Form__c> forms = ListFormsCtl.refreshFormList(context, fields, null);
            List<disco__Form__c> forms2 = ListFormsCtl.refreshFormList('not community', fields, null);
            Test.stopTest();

            System.assertEquals(1, forms.size());
            System.assert(forms2.isEmpty());
        }
    }

    @isTest
    static void testRefreshFormsList()
    {
        User userForTesting = [SELECT Id FROM User WHERE Username LIKE 'testportaluser%' LIMIT 1];
        System.runAs(userForTesting)
        {
            Test.startTest();
            String context = 'community';
            List<String> fields = new List<String>();
            fields.add('Name');

            List<disco__Form__c> forms = ListFormsCtl.refreshFormList(context, fields, null);
            Test.stopTest();
            System.assertEquals(1, forms.size());
        }
    }

    @isTest
    static void testGetLabelsByAPI()
    {
        Test.startTest();
        List<String> fields = new List<String>();
        fields.add('Admission__c');

        String result = ListFormsCtl.getLabelsByAPI(fields);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetLastModifiedFormDateTimeNoUser()
    {
        Test.startTest();
        String context = 'community';
        DateTime lastDateTime = ListFormsCtl.getLastModifiedFormDateTime(context);
        Test.stopTest();
        System.assertEquals(DateTime.newInstance(1900, 1, 1), lastDateTime);
    }

    @isTest
    static void testGetLastModifiedFormDateTime()
    {
        User userForTesting = [SELECT Id FROM User WHERE Username LIKE 'testportaluser%' LIMIT 1];
        disco__Form__c testForm = [SELECT Id, LastModifiedDate FROM disco__Form__c LIMIT 1];
        System.runAs(userForTesting)
        {
            Test.startTest();
            String context = 'community';

            DateTime lastDateTime = ListFormsCtl.getLastModifiedFormDateTime(context);
            Test.stopTest();
            System.assertEquals(lastDateTime, testForm.LastModifiedDate);
        } 
    }
}
@isTest
public class Ctl_LogCallTest {

    @testSetup static void setup(){
        Contact c = (Contact)TestFactory_Patient.createSObject(new Contact(LastName = 'Test_Patient'), true);

        Contact accountWithContact = [SELECT Id,AccountId  FROM Contact WHERE Id =: c.Id];

        Related_Contact__c relatedContact = (Related_Contact__c)TestFactory_Patient.createSObject(
            new Related_Contact__c(Contact__c  = c.Id, Account__c = accountWithContact.AccountId), true
        );
    }

    public static testMethod void createLogCallCreateNewTest(){
        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];

        Basic_Note__c pNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Caller_Affect_and_Presentation__c = 'Test_Caller_Affect_and_Presentation',
                Patient_Name__c = c.AccountId
            ),
            false
        );

        Basic_Note__c t = Ctl_LogCall.createLogCall(JSON.serialize(pNote),c.AccountId);

        // System.assertEquals(pNote.Patient_Name__c,[SELECT Id,Patient_Name__c FROM Basic_Note__c WHERE Id =: t.Id].Patient_Name__c);
    }

    public static testMethod void createLogCallTest(){
        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];

        Basic_Note__c pNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Call_Status__c = 'Logged',
                Caller_Affect_and_Presentation__c = 'Test_Caller_Affect_and_Presentation',
                Account__c = c.AccountId,
                Contact__c = c.Id
            ),
            true
        );
        Test.startTest();
            Basic_Note__c t = Ctl_LogCall.createLogCall(JSON.serialize(pNote),c.AccountId);

            // System.assertEquals(pNote.Account__c,[SELECT Id,Account__c FROM Basic_Note__c WHERE Id =: t.Id].Account__c);
            // System.assertEquals(true, Ctl_LogCall.hasRelationship(c.AccountId, c.Id));

        Test.stopTest();
    }

    public static testMethod void createLogCallWithCallerNameAsTextTest(){

        Contact c = [SELECT Id,AccountId, Account.Current_Admission__c
                    FROM Contact
                    WHERE LastName = 'Test_Patient'];
        // System.assertEquals(null, c.Account.Current_Admission__c);

        Basic_Note__c pNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Caller_Affect_and_Presentation__c = 'Test_Caller_Affect_and_Presentation',
                Call_Status__c = 'Logged',
                Account__c = c.AccountId,
                Caller_Name__c = 'test'
            ),
            true
        );
        Test.startTest();
            Basic_Note__c t = Ctl_LogCall.createLogCall(JSON.serialize(pNote),c.AccountId);
        Test.stopTest();

        c = [SELECT Id,AccountId, Account.Current_Admission__c
                    FROM Contact
                    WHERE LastName = 'Test_Patient'];
        // System.assertNotEquals(null, c.Account.Current_Admission__c);

        // System.assertEquals(c.Account.Current_Admission__c, t.Admission__c);
        // System.assertEquals(null, t.Contact__c);
    }

    public static  testMethod void getPatientDetailsTest(){

        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];

        Contact con = Ctl_LogCall.getPatientDetails(c.AccountId);

    }

    public static testMethod void getContactDetailsTest(){

        List<Contact> con = [SELECT Id FROM Contact WHERE LastName = 'Test_Patient'];

        Contact c = Ctl_LogCall.getContactDetails(con[0].Id);

    }

    public static testMethod void getPatientNoteDetailsTest(){

        Basic_Note__c patientNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Call_Status__c = 'Logged',
                Patient_Name__c ='Test_Patient',
                Caller_Name__c = 'test'
            ),
            true
        );

        Ctl_LogCall.getPatientNoteDetails(patientNote.Id);


    }

    public static testMethod void FieldDescribeUtilTest()
    {
        FieldDescribeUtil.getDependentOptionsImpl('Task','Non_starter_Reason__c','Call_Type__c');
        NewRelatedContactCtl.RecordTypeInfoWrapper rtWrapper = Ctl_LogCall.getContactRecordTypeDetails();
    }



}
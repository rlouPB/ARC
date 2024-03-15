@isTest
public class Test_Ctl_LogNote {
    
    @testSetup 
    static void setup(){
        Contact c = (Contact)TestFactory_Patient.createSObject(new Contact(LastName = 'Test_Patient'), true);
        Contact accountWithContact = [SELECT Id,AccountId FROM Contact WHERE Id =: c.Id];
        
        Related_Contact__c relatedContact = (Related_Contact__c)TestFactory_Patient.createSObject(
            new Related_Contact__c(Contact__c  = c.Id, Account__c = accountWithContact.AccountId), true
        );
    }
    
    @isTest
    public static void createLogCallCreateNewTest(){

        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];

        Basic_Note__c pNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Caller_Affect_and_Presentation__c = 'Test_Caller_Affect_and_Presentation',
                Call_Status__c = 'Logged', 
                Patient_Name__c ='Test_Patient',
                Caller_Name__c = 'test'
            ), false);
                
            Basic_Note__c t = Ctl_LogNote.createLogNote(JSON.serialize(pNote), c.AccountId);
        //system.assertEquals(taskObj.Patient_Name__c,[SELECT Id,Patient_Name__c FROM Task WHERE Id =: t.Id].Patient_Name__c);
    }
    
    @isTest
    public static void createLogCallTest(){

        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];

        Task taskObj = (Task)TestFactory_Patient.createSObject(new Task(Call_Status__c = 'Logged',  Patient_Name__c = c.AccountId,Caller_Name__c = c.Id), true);
        
        Basic_Note__c pNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Caller_Affect_and_Presentation__c = 'Test_Caller_Affect_and_Presentation',
                Call_Status__c = 'Logged',  
                Patient_Name__c = c.AccountId,
                Caller_Name__c = c.Id
            ), true
        );

        Basic_Note__c t = Ctl_LogNote.createLogNote(JSON.serialize(pNote),c.AccountId);
       
       system.assertEquals(pNote.Patient_Name__c,[SELECT Id,Account__c FROM Basic_Note__c WHERE Id =: t.Id].Account__c);

    }

    @isTest
    public static void createLogCallWithCallerNameAsTextTest(){

        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];
        
        Basic_Note__c pNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Caller_Affect_and_Presentation__c = 'Test_Caller_Affect_and_Presentation',
                Call_Status__c = 'Logged', 
                Patient_Name__c ='Test_Patient',
                Caller_Name__c = 'test'
            ), true
        );

        Basic_Note__c t = Ctl_LogNote.createLogNote(JSON.serialize(pNote),c.AccountId);
        
        system.assertEquals(pNote.Caller_Name__c,[SELECT Id,Caller_Name__c FROM Basic_Note__c WHERE Id =: t.Id].Caller_Name__c);

    }
    
    @isTest
    public static void getPatientNoteDetailsTest(){

        Basic_Note__c patientNote = (Basic_Note__c)TestFactory_Patient.createSObject(
            new Basic_Note__c(
                Call_Status__c = 'Logged', 
                Patient_Name__c ='Test_Patient',
                Caller_Name__c = 'test'
            ), true
        );

        Ctl_LogNote.getPatientNoteDetails(patientNote.Id);

    }

}
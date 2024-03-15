@IsTest(SeeAllData=false)
public with sharing class FlaggedNotesServiceTest {

    @TestSetup
    public static void setup() {
        disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
            Name = 'Psychiatrist Transfer from Test',
            disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
        );
        insert discoFormTemplate;

        ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();
		AdmissionScreeningControllerTest.setup();
        Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        Admission__c admission=[SELECT Id,Team__c FROM Admission__c WHERE Patient_Account__c=:patient.Id limit 1];
        Case currentCase=new Case(AccountId=patient.Id,Admission__c=admission.Id);
        insert currentCase;
        patient.Current_Case__c=currentCase.Id;
        update patient;
        admission.Team__c='A';
        update admission;

        test.startTest();

        Clinical_Code__c clinicalcode = new Clinical_Code__c(Name='001',Description__C='test code');
        insert clinicalcode;

        Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
        Patient_Note__c consultantNote = new Patient_Note__c(
            Account__c = patient.Id,
            Admission__c = admission.Id,
            Consultation_Assigned_Date__c = System.today(),
            Consultation_Requested_By__c = 'Patient',
            Type__c = 'Admissions Consultation Note',
            RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId()
        );

        insert consultantNote;
    }


    public static testmethod void testMethods() {
        Patient_Note__c pn = [SELECT Id,Account__c FROM Patient_Note__c limit 1];
        pn.Status__c = 'Finalized';
        pn.Finalized_Date_Time__c = system.today();
        pn.Flagged__c=true;
        update pn;

        Date t = system.today();

        string today = ''+t.year()+'-'+t.month()+'-'+t.day();

        System.assertNotEquals(0, FlaggedNotesService.getFlaggedNotes(pn.Account__c, '24 Hours', today, today ).size() );
        System.assertNotEquals(0, FlaggedNotesService.getFlaggedNotes(pn.Account__c, '1 Month', today, today ).size() );
        System.assertNotEquals(0, FlaggedNotesService.getFlaggedNotes(pn.Account__c, '7 Days', today, today ).size() );
        FlaggedNotesService.getFlaggedNotes(pn.Account__c, 'Custom', today, today );


        FlaggedNotesService.getAlerts(pn.Account__c, '24 Hours', today, today ).size();
        FlaggedNotesService.getAlerts(pn.Account__c, '1 Month', today, today ).size();
        FlaggedNotesService.getAlerts(pn.Account__c, '7 Days', today, today ).size();
        FlaggedNotesService.getAlerts(pn.Account__c, 'Custom', today, today );
    }
}
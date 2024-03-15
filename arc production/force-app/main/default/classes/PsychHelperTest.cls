@IsTest(SeeAllData=false)
public with sharing class PsychHelperTest {
    @testSetup
    private static void doSetup(){
		AdmissionScreeningControllerTest.setup();
        Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        Admission__c admission=[SELECT Id,Team__c FROM Admission__c WHERE Patient_Account__c=:patient.Id limit 1];
        Case currentCase=new Case(AccountId=patient.Id,Admission__c=admission.Id);
        insert currentCase;
        patient.Current_Case__c=currentCase.Id;
        update patient;
        admission.Team__c='A';
        update admission;

        List<Assigned_Clinician__c> cliniciansToInsert = new List<Assigned_Clinician__c>();
		cliniciansToInsert.add( new Assigned_Clinician__c(
            Patient_Account__c =patient.Id,
			Admission__c = admission.ID,
			Role__c = 'Psychotherapist',
			User__c = UserInfo.getUserId(),
			Start_Date__c = Date.today().addDays(-7)
        ));
        insert cliniciansToInsert;
    }

    @isTest
    private static void testPsychTestingRequestCreationOnAdmitted(){
        Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        Admission__c admission=[SELECT Id,Team__c FROM Admission__c WHERE Patient_Account__c=:patient.Id limit 1];
        List<Psych_Testing_Request__c> ptrs = [Select Id from Psych_Testing_Request__c WHERE Admission__c = :admission.Id];

        Test.startTest();
        system.assertEquals(0, ptrs.size());
        admission.Stage__c = 'Admitted';
        update admission;
        ptrs = [Select Id from Psych_Testing_Request__c WHERE Admission__c = :admission.Id];
        system.assertEquals(1, ptrs.size());
        Test.stopTest();
    }

    @isTest
    private static void testPsychTestingRequestCreationWithDocType(){
        Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        Admission__c admission=[SELECT Id,Team__c FROM Admission__c WHERE Patient_Account__c=:patient.Id limit 1];

        PsychHelper.PsychTestingWrapper wrapper1 = new PsychHelper.PsychTestingWrapper();
        wrapper1.patientId = patient.Id;
        wrapper1.docTypeName = 'Referral_for_Neuropsychological_Scr';

        Test.startTest();
        System.assert(PsychHelper.createPsychTestingRequestAndReport(new List<PsychHelper.PsychTestingWrapper>{wrapper1}).size() != 0);

        Psych_Testing_Request__c ptr = [Select Id from Psych_Testing_Request__c WHERE Patient_Account__c = :patient.Id limit 1];
        ptr.Report_Due_Date__c = Date.today();
        TriggerFactory.Recursions.clear();
        update ptr;
        TriggerFactory.Recursions.clear();
        delete ptr;
        Test.stopTest();
    }

   
}
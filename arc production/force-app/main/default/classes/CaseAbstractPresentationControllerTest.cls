@isTest
public class CaseAbstractPresentationControllerTest {
    @TestSetup
    static void makeData()
    {
        PatientFileTestDataUtil.createPatient();
        PatientFileTestDataUtil.createPatientWithAdmission();
        Account testPatient = [SELECT Id, Current_Admission__c
                                FROM Account
                                WHERE Recordtype.Name = 'Patient'
                                LIMIT 1];
        Admission__c admission=[SELECT Id,Team__c FROM Admission__c WHERE Patient_Account__c=:testPatient.Id limit 1];
        system.debug('queryAssignedClinicians admissionId =' + admission.Id);
        Case currentCase=new Case(AccountId=testPatient.Id,Admission__c=admission.Id);
        insert currentCase;
        testPatient.Current_Case__c=currentCase.Id;
        testPatient.Current_Admission__c = admission.Id;
        update testPatient;
        admission.Team__c='A';

        List<Assigned_Clinician__c> assignedClinicians = new List<Assigned_Clinician__c>();
        Assigned_Clinician__c socialWorker = new Assigned_Clinician__c
		(
            Patient_Account__c = testPatient.Id,
            Admission__c = admission.Id,
			Treatment_Plan__c = currentCase.Id,
			User__c = UserInfo.getUserId(),
			Role__c = 'Clinical Social Worker',
            Start_Date__c = Date.Today().addDays(-5)
		);
        assignedClinicians.add(socialWorker);

        Assigned_Clinician__c psychotherapist = new Assigned_Clinician__c
		(
            Patient_Account__c = testPatient.Id,
            Admission__c = admission.Id,
			Treatment_Plan__c = currentCase.Id,
			User__c = UserInfo.getUserId(),
			Role__c = 'Psychotherapist',
            Start_Date__c = Date.Today().addDays(-5)
		);
        assignedClinicians.add(psychotherapist);

        Assigned_Clinician__c expiredSocialWorker = new Assigned_Clinician__c
		(
            Patient_Account__c = testPatient.Id,
            Admission__c = admission.Id,
			Treatment_Plan__c = currentCase.Id,
			User__c = UserInfo.getUserId(),
			Role__c = 'Clinical Social Worker',
            Start_Date__c = Date.Today().addDays(-50),
            End_Date__c = Date.Today().addDays(-5)
		);
        assignedClinicians.add(expiredSocialWorker);

        Assigned_Clinician__c medOfficeDoc = new Assigned_Clinician__c
		(
            Patient_Account__c = testPatient.Id,
            Admission__c = admission.Id,
			Treatment_Plan__c = currentCase.Id,
			User__c = UserInfo.getUserId(),
			Role__c = 'Med Office Physician',
            Start_Date__c = Date.Today().addDays(-50)
		);
        assignedClinicians.add(medOfficeDoc);

		insert assignedClinicians;

    }
    
    @isTest
    static void testCaseAbstractPresentationController()
    {
        Account testPatient = [SELECT Id, Current_Admission__c
                               FROM Account
                               WHERE Recordtype.Name = 'Patient'
                               LIMIT 1];
        Test.startTest();
        CaseAbstract ca =  (CaseAbstract) JSON.deserialize(CaseAbstract.createNewCaseAbstract(testPatient.Id, 'Initial_Case_Abstract', false), CaseAbstract.class);
        
        PageReference pageRef = Page.CaseAbstractPresentation;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController csStdCtl = new ApexPages.StandardController(ca.record);
        CaseAbstractPresentationController csController = new CaseAbstractPresentationController(csStdCtl);
        csController.init();
        csController.backToCaseAbstract();
        csController.savePdf();
        
        Test.stopTest();
        
    }
}
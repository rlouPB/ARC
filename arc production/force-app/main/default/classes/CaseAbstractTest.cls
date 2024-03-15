@IsTest
class CaseAbstractTest
{
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
    static testmethod void testCreateCaseAbstract()
    {
        Account testPatient = [SELECT Id, Current_Admission__c
                                FROM Account
                                WHERE Recordtype.Name = 'Patient'
                                LIMIT 1];
        Id testPatientId;

        Test.startTest();
        CaseAbstract.CaseAbstractRequest caRequest = new CaseAbstract.CaseAbstractRequest();
        caRequest.caType = 'Initial_Case_Abstract';
        caRequest.patientId = testPatient.Id;
        List<CaseAbstract.CaseAbstractRequest> reqList = new List<CaseAbstract.CaseAbstractRequest>{caRequest};
        List<String> caIds = CaseAbstract.createNewCaseAbstractInvocable(reqList);
        System.debug('caIds=' + caIds);
        CaseAbstract ca =  (CaseAbstract) JSON.deserialize(CaseAbstract.createNewCaseAbstract(caRequest.patientId, caRequest.caType, false), CaseAbstract.class);
        CaseAbstract ca2 = new CaseAbstract(caIds[0]);

        String strCA = CaseAbstract.getCaseAbstract(caIds[0]);
        System.debug('strCA = ' + strCA);
        strCA = CaseAbstract.finalizeCaseAbstract(caIds[0]);
        strCA = CaseAbstract.reopenCaseAbstract(caIds[0]);
        System.debug('strCA = ' + strCA);
        system.debug('CA Sections=' + ca.sections);
        system.debug('CA Sections=' + ca.sections[0].record);

        system.debug('setOwner='+CaseAbstract.setOwner(ca.sections[0].record.Id, userInfo.getUserId()));
        ca.sections[0].record.status__c='Completed';
        system.debug('set status result = ' + JSON.serialize(ca.sections[0]));
        system.debug('set status result = ' + CaseAbstract.setStatus(JSON.serialize(ca.sections[0])));
        TriggerFactory.Recursions.clear();
        CaseAbstract.saveSection(JSON.serialize(ca.sections[0].record));


        Case_Abstract_Section__c sectionObj = ca.sections[0].record;
        sectionObj.Status__c = 'Completed';
        TriggerFactory.Recursions.clear();
        update sectionObj;
        TriggerFactory.Recursions.clear();
        delete sectionObj;
        Test.stopTest();

        // System.assertEquals(testPatient.Current_Admission__c, ca.admission.Id);
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

    @isTest
    static void testCaseAbstractPresentationPDF()
    {
        Account testPatient = [SELECT Id, Current_Admission__c
                                FROM Account
                                WHERE Recordtype.Name = 'Patient'
                                LIMIT 1];
        Test.startTest();
        CaseAbstract ca =  (CaseAbstract) JSON.deserialize(CaseAbstract.createNewCaseAbstract(testPatient.Id, 'Initial_Case_Abstract', false), CaseAbstract.class);
        List<Case_Abstract_Section__c> cass = new List<Case_Abstract_Section__c>();
        for(CaseAbstract.Section section : ca.sections) {
            section.record.Status__c = 'Completed';
            cass.add(section.record);
        }
        update cass;
        PageReference pageRef = Page.CaseAbstractPresentationPDF;
        Test.setCurrentPage(pageRef);

        CaseAbstractPresentationPDFController csDefaultController = new CaseAbstractPresentationPDFController();

        ApexPages.StandardController csStdCtl = new ApexPages.StandardController(ca.record);
		CaseAbstractPresentationPDFController csController = new CaseAbstractPresentationPDFController(csStdCtl);
        csController.init();

        Test.stopTest();

    }

    @isTest static void testCaseAbstractLookupService() {
        User adminNotMe = [SELECT Id
					 		FROM User
							WHERE Profile.Name = 'System Administrator'
									AND IsActive = true
									AND Id != :Userinfo.getUserId()
							LIMIT 1];
		System.runAs(adminNotMe) {
            List<User> usersToCreate = new List<User>();
            Profile riggsClinicalProfile = [select Id from Profile where Name = 'RiggsClinical' LIMit 1];
		    Profile riggsStaffProfile = [select Id from Profile where Name = 'RiggsStaff' LIMit 1];

			//good: all staff
			User testUser =  new User(
				FirstName = 'AGMTestnonclinicalAllstaff',
				LastName = 'Test',
				ProfileId = riggsStaffProfile.Id,
				Username = 'nonclinicalAllstaff@austenriggs.net.Phase2Dev',
				Email = 'nonclinicalAllstaff@example.com',
				Alias = 'noncl',
				EmailEncodingKey = 'ISO-8859-1',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US',
				TimeZoneSidKey = 'America/New_York',
				IsActive = true
			);
            insert testUser;
            PermissionSet clinPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Clinical' LIMIT 1];
			PermissionSetAssignment psa = new PermissionSetAssignment(
				AssigneeId = testUser.Id,
				PermissionSetId = clinPermSet.Id
			);
			insert psa;

        }
        Test.startTest();
        System.debug('test result=' + CaseAbstractLookupService.SearchByText('AGMT'));
        Test.stopTest();

    }

    @IsTest
    static void testCaseAbstractPresentation() {
        Account testPatient = [SELECT Id, Current_Admission__c
                                FROM Account
                                WHERE Recordtype.Name = 'Patient'
                                LIMIT 1];
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = testPatient.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;

        Test.startTest();

        CaseAbstractPresentation cap = new CaseAbstractPresentation(documents[0].Id);
        cap.generatedDatetime = Datetime.now();
        System.debug('generatedDateTimeString =' + cap.generatedDateTimeString);
        Test.stopTest();
    }

  
}
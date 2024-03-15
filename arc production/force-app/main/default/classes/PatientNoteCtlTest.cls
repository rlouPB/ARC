@isTest(SeeAllData=false)
private class PatientNoteCtlTest {
	@TestSetup
    private static void testSetup(){
        System.debug('PatientNoteCtlTest testSetup...');
        disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
            Name = 'Psychiatrist Transfer from Test',
            disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
        );
        insert discoFormTemplate;

        AdmissionScreeningControllerTest.setup();
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        
        Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
        Patient_Note__c consultantNote = new Patient_Note__c(Account__c = patient.Id,
                                                            Admission__c = patient.Current_Admission__c,
                                                            Consultation_Assigned_Date__c = System.today(),
                                                            Consultation_Requested_By__c = 'Patient',
                                                             Type__c = 'Psychotherapy Consultation Note',
                                                            RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId());
        insert consultantNote;

        System.debug('PatientNoteCtlTest testSetup consultantNote: ' + consultantNote);

        List <Group__c> groups = new List<Group__c>();

        Group__c g1 = new Group__c(
            Name = 'Current Clinical Staff',
            Type__c = 'Center-wide'
        );
        groups.add(g1);

        Group__c g2 = new Group__c(
            Name = 'Clinical',
            Type__c = 'Center-wide'
        );
        groups.add(g2);
        Group__c testGroup = new Group__c(
            Name='Current Clinical Staff',
            Attendance_Tracking__c='Do not Track Attendance',
            Duration__c = 'Standing',
            Type__c='Program',
            Primary_Function__c='Staff'
        );
        groups.add(testGroup);

        insert groups;

        System.debug('PatientNoteCtlTest testSetup groups: ' + groups);

        AuthorizedSignersTest.createAuthorizedSignerGroups();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='RiggsAdmissions']; 
        User u = new User(Alias = 'samtestu', Email='samtestu@testorg.com', 
            EmailEncodingKey='UTF-8', FirstName='tEsT', LastName='samtestuTesting', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='samtestu@testorg.com',
                         Requires_Co_Signature__c = true);
        
        insert u;
        System.debug('PatientNoteCtlTest testSetup TestUser: ' + u);
        
        String psychTestingRecordTypeId = Schema.SObjectType.Psych_Testing_Request__c.getRecordTypeInfosByDeveloperName().get('Psychological_Testing_Request').getRecordTypeId();
        Psych_Testing_Request__c psychTestingRequestTestRecord = new Psych_Testing_Request__c();
        psychTestingRequestTestRecord.Independent_Testing__c = false;
        psychTestingRequestTestRecord.Report_Writer__c = u.Id;
        
        psychTestingRequestTestRecord.RecordTypeId =psychTestingRecordTypeId;
        psychTestingRequestTestRecord.Testing_Supervisor__c = u.Id;
        
        insert psychTestingRequestTestRecord;
        System.debug('PatientNoteCtlTest testSetup psychTestingRequestTestRecord: ' + psychTestingRequestTestRecord);
        
        Patient_Note__c patientNoteTestRecord = new Patient_Note__c(Account__c = patient.Id,	
                                                                    Admission__c = patient.Current_Admission__c,
                                                                    Consultation_Assigned_Date__c = System.today(),
                                                                    Consultation_Requested_By__c = 'Patient',
                                                                    Type__c = 'Psychotherapy Consultation Note',
                                                                    Status__c = 'Draft',
                                                                    Psych_Testing_Request__c = psychTestingRequestTestRecord.Id
                                                                   // RecordTypeId = patientNoteRecordTypeMap.get('Psychological_Testing_Request').getRecordTypeId()
                                                                   );
        insert patientNoteTestRecord;
        
        System.debug('PatientNoteCtlTest testSetup patientNoteTestRecord: ' + patientNoteTestRecord);
        
        Assigned_Clinician__c ac1 = new Assigned_Clinician__c(Role__c = 'Psychotherapist',
                                                              Admission__c =patient.Current_Admission__c,
                                                              Start_Date__c = date.newInstance(2022, 1, 1),
                                                              User__c = u.Id
                                                             );
        insert ac1;
        
        Assigned_Clinician__c ac2 = new Assigned_Clinician__c(Role__c = 'Psychotherapist',
                                                             Admission__c =patient.Current_Admission__c,
                                                             Start_Date__c = date.newInstance(2022, 1, 1),
                                                              User__c = u.Id
                                                            );
        insert ac2;
        
        Prescription__c pres = new Prescription__c(
            Location__c = 'Keep',
            location_temp__c = 'Keep',
            Quantity_to_Package__c = 1,
            Quantity_to_Package_Temp__c = 1,
            account__c = patient.Id,
            Status__c = 'Active'
    	);
        insert pres;
        
    }
    @isTest
    private static void getAndSaveDraftCompleteFinalizePatientNote(){
        System.debug('PatientNoteCtlTest getAndSaveDraftCompleteFinalizePatientNote...');
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        Patient_Note__c consultantNote = [SELECT
                                         Id
                                         FROM Patient_Note__c
                                         LIMIT 1];
        
        Patient_Note__c patientNoteTestRecord = [SELECT
                                          Id, Type__c
                                          FROM Patient_Note__c
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT 1];
        
        
        Test.startTest();
        PatientNoteCtl.getUser(UserInfo.getUserId());
        NoteDefinition.Note theNote = PatientNoteCtl.getNote(consultantNote.Id);
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Draft');
        theNote = PatientNoteCtl.getNote(consultantNote.Id);
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Complete');
        theNote = PatientNoteCtl.getNote(consultantNote.Id);
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Finalize');
        
        patientNoteTestRecord.Type__c = 'Medication Self Administration (MSA) Order';
        update patientNoteTestRecord;
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Cancelled');
        Test.stopTest();
    }
    
     @isTest
    private static void testSaveNotewithCancelled(){
        System.debug('PatientNoteCtlTest getAndSaveDraftCompleteFinalizePatientNote...');
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        Patient_Note__c patientNoteTestRecord = [SELECT
                                          Id, Type__c
                                          FROM Patient_Note__c
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT 1];
        
        
        Test.startTest();
        
        patientNoteTestRecord.Type__c = 'Medication Self Administration (MSA) Order';
        update patientNoteTestRecord;
        NoteDefinition.Note theNote = PatientNoteCtl.getNote(patientNoteTestRecord.Id);
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Finalize');
        Test.stopTest();
    }
    
    @isTest
    private static void savePatientNoteWithRaceCondition(){
        System.debug('PatientNoteCtlTest savePatientNoteWithRaceCondition...');
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        Patient_Note__c consultantNote = [SELECT
                                         Id
                                         FROM Patient_Note__c
                                         LIMIT 1];
        Test.startTest();
        PatientNoteCtl.getUser(UserInfo.getUserId());
        NoteDefinition.Note theNote = PatientNoteCtl.getNote(consultantNote.Id);
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Draft');
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Complete');
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Finalize');
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Cancelled');
        Test.stopTest();
    }
    @isTest
    private static void createSdocJunction(){
        System.debug('PatientNoteCtlTest createSdocJunction...');
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        Patient_Note__c consultantNote = [SELECT
                                         Id
                                         FROM Patient_Note__c
                                         LIMIT 1];
        SDoc_Junction__c sDocJunction = new SDoc_Junction__c();
        Patient_Note__c h = Patient_NoteTriggerHandler.createSdDocJunction(consultantNote);


    }

    @IsTest
	static void testGetGroup() {
		Test.startTest();
		String str = PatientNoteCtl.getGroup();
		System.assert(String.isNotBlank(str));
		Test.stopTest();
	}

    @IsTest
	static void testCanFinalizeNote() {
        Patient_Note__c consultantNote = [SELECT
                                         Id
                                         FROM Patient_Note__c
                                         LIMIT 1];
        
        Patient_Note__c patientNoteTestRecord = [SELECT
                                          Id
                                          FROM Patient_Note__c
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT 1];
        Psych_Testing_Request__c psychtest = [select id, RecordTypeId FROM Psych_Testing_Request__c ORDER BY LastModifiedDate DESC LIMIT 1];
        
		Test.startTest();
        Boolean isNoteEmpty = PatientNoteCtl.getCanFinalize('');
		Boolean flag = PatientNoteCtl.getCanFinalize(consultantNote.Id);
        
        boolean type1 = PatientNoteCtl.getCanFinalize(patientNoteTestRecord.Id);
        
        
        
        psychtest.RecordTypeId =Schema.SObjectType.Psych_Testing_Request__c.getRecordTypeInfosByDeveloperName().get('Neuropsychological_Screening_Request').getRecordTypeId();
        update psychtest;
        
        patientNoteTestRecord.Type__c = 'Summation of Hospitalization';
        update patientNoteTestRecord;
        
        boolean type2 = PatientNoteCtl.getCanFinalize(patientNoteTestRecord.Id);
        
        User userWithoutCosign = [SELECT Id, Requires_Co_Signature__c FROM User ORDER BY LastModifiedDate DESC LIMIT 1];
        userWithoutCosign.Requires_Co_Signature__c = false;
        update userWithoutCosign;
        
        
        psychtest.Independent_Testing__c =true;
        psychtest.Testing_Supervisor__c = null;
        update psychtest;
        
        boolean type3 = PatientNoteCtl.getCanFinalize(patientNoteTestRecord.Id);

		Test.stopTest();
	}

    @IsTest
	static void testGetPatientNoteRecord() {
        Patient_Note__c consultantNote = [SELECT
                                         Id
                                         FROM Patient_Note__c
                                         LIMIT 1];
		Test.startTest();
		Patient_Note__c note = PatientNoteCtl.getPatientNoteRecord(consultantNote.Id);

		Test.stopTest();
	}

    @IsTest
	static void testReopenNote() {
        Patient_Note__c consultantNote = [SELECT
                                         Id
                                         FROM Patient_Note__c
                                         LIMIT 1];
		Test.startTest();
		PatientNoteCtl.reopenNote(consultantNote.Id, 'Draft');

		Test.stopTest();
	}

    @isTest
    private static void getAndSaveDraftCompleteFinalizePatientNote2(){
        System.debug('PatientNoteCtlTest getAndSaveDraftCompleteFinalizePatientNote...');
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        Patient_Note__c consultantNote = [SELECT
                                         Id
                                         FROM Patient_Note__c
                                         LIMIT 1];
        consultantNote.type__c = 'Summation of Hospitalization';
        consultantNote.Status__c='Draft';
        update consultantNote;
        Test.startTest();

        NoteDefinition.Note theNote = PatientNoteCtl.getNote(consultantNote.Id);
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Draft');
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Cancelled');

        Test.stopTest();
    }
    
    @isTest
    private static void testCanSeeCompleteButton(){
        System.debug('PatientNoteCtlTest canSeeCompleteButton...');
        Patient_Note__c patientNoteTestRecord = [SELECT
                                          Id
                                          FROM Patient_Note__c
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT 1];
        Test.startTest();
		PatientNoteCtl.canSeeCompleteButton(patientNoteTestRecord.Id);
        
        patientNoteTestRecord.type__c = 'Summation of Hospitalization';
        update patientNoteTestRecord;
        
        PatientNoteCtl.canSeeCompleteButton(patientNoteTestRecord.Id);
        Test.stopTest();
    }


    @isTest
    private static void testAwayMethods(){
        System.debug('PatientNoteCtlTest testAwayMethods...');
        Patient_Note__c patientNoteTestRecord = [SELECT
                                          Id
                                          FROM Patient_Note__c
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT 1];
        Test.startTest();
		PatientNoteCtl.getPatientNoteAwayOrderInfo(patientNoteTestRecord.Id);

        Date today = Date.today();
        Date firstDay = Date.newInstance(today.year(), 10, 11);
        string hour = '12';
        string minute = '20';
        string second = '20';
        String firstDayStr = String.valueOf(firstDay.year()) + '-' + String.valueOf(firstDay.month()) + '-' + String.valueOf(firstDay.day() +
            ' ' + hour + ':' + 
            minute + ':' + second);
        
        Date lastDay = Date.newInstance(today.year(), 10, 15);
        String lastDayStr =  String.valueOf(lastDay.year()) + '-' + String.valueOf(lastDay.month()) + '-' + String.valueOf(lastDay.day() +
            ' ' + hour + ':' + 
            minute + ':' + second);
        PatientNoteCtl.saveAwayMedOrderNoteDetails(patientNoteTestRecord.Id, firstDayStr, lastDayStr, false, 4);
        
        Test.stopTest();
    }

    @isTest
    private static void testSaveNoteWithTypeThatHasDiagnosis(){
        System.debug('PatientNoteCtlTest testSaveNoteWithTypeThatHasDiagnosis...');
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        Patient_Note__c patientNoteTestRecord = [SELECT
                                          Id, Type__c
                                          FROM Patient_Note__c
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT 1];
        
        
        Test.startTest();
        
        patientNoteTestRecord.Type__c = 'Admissions Consultation Note';
        update patientNoteTestRecord;
        NoteDefinition.Note theNote = PatientNoteCtl.getNote(patientNoteTestRecord.Id);
        PatientNoteCtl.saveNote(JSON.serialize(theNote.patientNote), 'Finalize');

        List<Patient_Note__c> pns = new List<Patient_Note__c>();
        pns.add(patientNoteTestRecord);
        PatientNoteCtl.cloneDiagnosesWithPatientNote(pns);
        Test.stopTest();
    }

 
}
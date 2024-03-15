@IsTest
public  class NoteDiagnosesTests {
    @TestSetup
    public static void makedata() {
        //PatientFileTestDataUtil.createPatient();

        disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
            Name = 'Psychiatrist Transfer from Test',
            disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
        );
        insert discoFormTemplate;

        AdmissionScreeningControllerTest.setup();
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account];
        insert new Clinical_Code__c(Name='001',Description__C='test code');
        Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
        Patient_Note__c consultantNote = new Patient_Note__c(
            Account__c = patient.Id,
            Admission__c = patient.Current_Admission__c,
            Consultation_Assigned_Date__c = System.today(),
            Consultation_Requested_By__c = 'Patient',
            Type__c = 'Psychotherapy Consultation Note',
            RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId()
        );
        insert consultantNote;

        Patient_Note__c note = [Select Id,Account__c,Account__r.Current_Admission__c from Patient_Note__c];
        Clinical_Code__c code = [Select id from Clinical_Code__c];
        system.assertNotEquals(null,NoteDiagnosisCtl.saveDiagnosis( JSON.serialize( new Diagnosis__c(
            Admission__c = note.Account__r.Current_Admission__c,
            Patient_Note__c = note.Id,
            Source__c='Admissions',
            Clinical_Code__c=code.Id,
            Type__c='Principal'
        ))));
        system.assertNotEquals(null,NoteDiagnosisCtl.saveDiagnosis( JSON.serialize( new Diagnosis__c(
            Admission__c = note.Account__r.Current_Admission__c,
            Patient_Note__c = note.Id,
            Source__c='Admissions',
            Clinical_Code__c=code.Id,
            Type__c='Comorbid'
        ))));
        system.assertNotEquals(null,NoteDiagnosisCtl.saveDiagnosis( JSON.serialize( new Diagnosis__c(
            Admission__c = note.Account__r.Current_Admission__c,
            Marked_for_Delete__c=true,
            Patient_Note__c = note.Id,
            Source__c='Admissions',
            Clinical_Code__c=code.Id,
            Type__c='Comorbid'
        ))));
    }
    public static testmethod void testGetters(){
        Patient_Note__c note = [Select Id,Account__c,Account__r.Current_Admission__c from Patient_Note__c];
        system.assertNotEquals(null,NoteDiagnosisCtl.getDiagnoses(note.Account__r.Current_Admission__C, 'Admissions', note.Id));
        system.assertNotEquals(null, NoteDiagnosisCtl.getRecordInfo(userinfo.getUserId(), 'User', 'Name'));
        system.assertNotEquals(0,NoteDiagnosisCtl.getComorbids(note.Account__r.Current_Admission__c,'Admissions', note.Id).size());
    }
    public static testmethod void testSetters(){
        Patient_Note__c note = [Select Id,Account__c,Account__r.Current_Admission__c from Patient_Note__c];
        DIagnosis__c d = [Select Id from Diagnosis__c where Type__C='Comorbid' and Marked_for_Delete__c=true limit 1];
        system.assertEquals(null,NoteDiagnosisCtl.MarkForDelete(d.Id, true).errorMessage);
        update new Patient_Note__c(Id=note.Id, Status__c='Finalized');
        test.startTest();
        NoteDiagnosisCtl.finalize(note.Account__r.Current_Admission__c, note, 'Admissions');
        test.stopTest();
    }
    public static testmethod void testPatientDiagnoses(){
        Patient_Note__c note = [Select Id,Account__c,Account__r.Current_Admission__c from Patient_Note__c];
        DIagnosis__c d = [Select Id from Diagnosis__c where Type__C='Comorbid' and Marked_for_Delete__c=true limit 1];
        update new Patient_Note__c(Id=note.Id,Status__c='Finalized');
        NoteDiagnosisCtl.finalize(note.Account__r.Current_Admission__c, note,'Admissions');
        PatientDiagnosesCls.LoadDataResult resp = PatientDiagnosesCls.LoadData(note.Account__c, null);
    }
    public static testmethod void testErrors(){
        system.assertNotEquals(null, NoteDiagnosisCtl.getDiagnoses(null, null, null) );
        system.assertNotEquals(null, NoteDiagnosisCtl.MarkForDelete(null,null) );
        system.assertNotEquals(null, PatientDiagnosesCls.LoadData(null,null) );
    }
}
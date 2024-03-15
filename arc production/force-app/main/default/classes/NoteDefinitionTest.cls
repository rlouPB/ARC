@isTest
private class NoteDefinitionTest
{
    private static Note_Definition__mdt getCustomNoteDefinition()
    {
        Note_Definition__mdt noteDefinition = new Note_Definition__mdt();
        noteDefinition.DeveloperName = 'Clinical_Review';
        noteDefinition.MasterLabel = 'Clinical Review';
        noteDefinition.Note_Label__c = 'Clinical Review';
        noteDefinition.Active__c = true;
        noteDefinition.Parameters__c = '{"sidebar": {"fieldNames": [{ "fieldName": "Account__r.Name", "label": "Patient" }, {"fieldName": "Program__c", "label": "Program"}, { "fieldName": "Admission__r.Admit_Date__c", "label": "Admit Date" }]},'
                                        + '"header": {"fieldNames": [{ "fieldName": "Account__r.Name", "label": "Patient" }, {"fieldName": "Program__c", "label": "Program"}, { "fieldName": "Admission__r.Admit_Date__c", "label": "Admit Date" }]},'
                                        + '"footer": {"fieldNames": [{ "fieldName": "Account__r.Name", "label": "Patient" }, {"fieldName": "Program__c", "label": "Program"}, { "fieldName": "Admission__r.Admit_Date__c", "label": "Admit Date" }]}}'
                                        + '"saveToQueue": "Med Office"';
        return noteDefinition;
    }

    private static List<Note_Item__mdt> getCustomNoteItemList(String Id)
    {
        List<Note_Item__mdt> noteItemList = new List<Note_Item__mdt>();

        // Test Date field
        Note_Item__mdt noteItem1 = new Note_Item__mdt();
        noteItem1.Note_Definition__c = Id;
        noteItem1.DeveloperName = 'Clinical_Review_Date';
        noteItem1.MasterLabel = 'Clinical Review Date';
        noteItem1.Title__c = 'Clinical Review Date';
        noteItem1.Active__c = true;
        noteItem1.Order__c = 1.0;
        noteItem1.Type__c = 'Field';
        noteItem1.Field_Name__c = 'Clinical_Review_Date__c';

        // Test Text field
        Note_Item__mdt noteItem2 = new Note_Item__mdt();
        noteItem2.Note_Definition__c = Id;
        noteItem2.DeveloperName = 'Requesting_Clinician';
        noteItem2.MasterLabel = 'Requesting Clinician';
        noteItem2.Title__c = 'Requesting Clinician';
        noteItem2.Active__c = true;
        noteItem2.Order__c = 2.0;
        noteItem2.Type__c = 'Field';
        noteItem2.Field_Name__c = 'Requesting_Clinician__c';

        // Test Rich Text field
        Note_Item__mdt noteItem3 = new Note_Item__mdt();
        noteItem3.Note_Definition__c = Id;
        noteItem3.DeveloperName = 'Reason_for_Request';
        noteItem3.MasterLabel = 'Reason for Request';
        noteItem3.Title__c = 'Reason for Request';
        noteItem3.Active__c = true;
        noteItem3.Order__c = 3.0;
        noteItem3.Type__c = 'Field';
        noteItem3.Field_Name__c = 'Reason_for_Request__c';

        // Test User Lookup field
        Note_Item__mdt noteItem4 = new Note_Item__mdt();
        noteItem4.Note_Definition__c = Id;
        noteItem4.DeveloperName = 'Consultation_Assigned_To';
        noteItem4.MasterLabel = 'Consultation Assigned To';
        noteItem4.Title__c = 'Consultation Assigned To';
        noteItem4.Active__c = true;
        noteItem4.Order__c = 4.0;
        noteItem4.Type__c = 'Field';
        noteItem4.Field_Name__c = 'Consultation_Assigned_To__c';

        // Test Contact Lookup field
        Note_Item__mdt noteItem5 = new Note_Item__mdt();
        noteItem5.Note_Definition__c = Id;
        noteItem5.DeveloperName = 'Contact_Lookup_Test';
        noteItem5.MasterLabel = 'Contact Lookup Test';
        noteItem5.Title__c = 'Contact Lookup Test';
        noteItem5.Active__c = true;
        noteItem5.Order__c = 5.0;
        noteItem5.Type__c = 'Field';
        noteItem5.Field_Name__c = 'Contact__c';

        return noteItemList;
    }

    @TestSetup
    static void setup()
    {
        disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
            Name = 'Psychiatrist Transfer from Test',
            disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
        );
        insert discoFormTemplate;

        Note_Definition__mdt noteDefinition = getCustomNoteDefinition();

        List<Note_Item__mdt> noteItemList = getCustomNoteItemList(noteDefinition.Id);

        Id patientRecordTypeId = [SELECT Id FROM RecordType
            WHERE SobjectType = 'Patient_Note__c' AND Name = 'Custom Note'].Id;

        List<Patient_Note__c> patientNoteList = new List<Patient_Note__c>();
        Patient_Note__c patientNote1 = new Patient_Note__c();
        patientNote1.RecordTypeId = patientRecordTypeId;
        patientNote1.Type__c = 'Clinical Review';

        patientNoteList.add(patientNote1);

        insert patientNoteList;
    }

    @isTest
    static void testGetNoteDefinition()
    {
        NoteDefinition.Note clinicialReviewNote = NoteDefinition.getNoteDefinition(
            'Clinical Review'
        );
        NoteDefinition.Note psychotherapyConsultationNote = NoteDefinition.getNoteDefinition(
            'Psychotherapy Consultation Note'
        );
        NoteDefinition.Note therapistsInitialContactNote = NoteDefinition.getNoteDefinition(
            'Therapist\'s Initial Contact Note'
        );
        NoteDefinition.Note therapyMonthlyProgressNote = NoteDefinition.getNoteDefinition(
            'Therapy Monthly Progress Note'
        );
        NoteDefinition.Note therapyProgressNote = NoteDefinition.getNoteDefinition(
            'Therapy Progress Note'
        );
    }

    @isTest
    static void testNullGetNoteDefinition()
    {
        NoteDefinition.Note nullNote = NoteDefinition.getNoteDefinition('Null Note');
        System.assertEquals(null, nullNote);
    }

    @isTest
    static void testGetPatientNoteLocked()
    {
        Id patientNote1Id = [SELECT Id FROM Patient_Note__c
            WHERE Type__c = 'Clinical Review'].Id;
        //NoteDefinition noteDefinition = new NoteDefinition(patientNote1Id);
        NoteDefinition.Note lockedNote = NoteDefinition.getNote(patientNote1Id, true);
        System.assertNotEquals(null, lockedNote);
    }

    @isTest
    static void testGetNote()
    {
        Id patientNote1Id = [SELECT Id FROM Patient_Note__c
            WHERE Type__c = 'Clinical Review'].Id;
        NoteDefinition.Note note = NoteDefinition.getNote(patientNote1Id);
        System.assertNotEquals(null, note);
    }

    @isTest
    static void testCalcHide()
    {
        String yesConditions = '{"fieldName": "Attended_Meetings__c","operator": "==","fieldValue": "12345"}';
        String noConditions = '{"fieldName": "Attended_Meetings__c","operator": "!=","fieldValue": "12345"}';
        String boolConditions = '{"fieldName": "Abdomen_Quick_Text__c","operator": "==","fieldValue": "1"}';

        sObject controllingsObject = (sObject)(new Patient_Note__c(Attended_Meetings__c = '12345', Abdomen_Quick_Text__c = true));
        Test.startTest();
            System.assertEquals(true, NoteDefinition.calculateHideNoteItem(yesConditions, controllingsObject), yesConditions);
            System.assertEquals(false, NoteDefinition.calculateHideNoteItem(noConditions, controllingsObject), noConditions);
            System.assertEquals(true, NoteDefinition.calculateHideNoteItem(boolConditions, controllingsObject), boolConditions);
        Test.stopTest();
    }
}
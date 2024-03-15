@IsTest
public class TrackFieldHistoryTest {
	private static Map<ID, List<Field_History__c>> fieldHistoriesByNote;
	@TestSetup
	static void makeData() {
		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		List<Patient_Note__c> testNotesToInsert = new List<Patient_Note__c>();
		Patient_Note__c testNote1 = new Patient_Note__c(Details__c = 'testNote1 details');
		testNotesToInsert.add(testNote1);
		insert testNotesToInsert;
	}

	@isTest
	static void testInsertNoTextAreaFields() {
		List<Patient_Note__c> testNotesToInsert = new List<Patient_Note__c>();
		Patient_Note__c testNote1 = new Patient_Note__c();
		testNotesToInsert.add(testNote1);

		Test.startTest();
		insert testNotesToInsert;
		Test.stopTest();

		List<Id> testNoteIds = new List<Id>();
		for (Patient_Note__c currentNote : testNotesToInsert) {
			testNoteIds.add(currentNote.Id);
		}

		getFieldHistoryResults(testNoteIds);

		List<Field_History__c> testNote1FieldHistories = fieldHistoriesByNote.get(testNote1.Id);
		if (testNote1FieldHistories == null) {
			testNote1FieldHistories = new List<Field_History__c>();
		}

		//System.assertEquals(0, testNote1FieldHistories.size());
	}

	@isTest
	static void testInsertTextAreaFields() {
		List<Patient_Note__c> testNotesToInsert = new List<Patient_Note__c>();
		Patient_Note__c testNote1 = new Patient_Note__c(Details__c = 'testNote1 details');
		testNotesToInsert.add(testNote1);

		Test.startTest();
		insert testNotesToInsert;
		Test.stopTest();

		List<Id> testNoteIds = new List<Id>();
		for (Patient_Note__c currentNote : testNotesToInsert) {
			testNoteIds.add(currentNote.Id);
		}

		getFieldHistoryResults(testNoteIds);

		List<Field_History__c> testNote1FieldHistories = fieldHistoriesByNote.get(testNote1.Id);
		if (testNote1FieldHistories == null) {
			testNote1FieldHistories = new List<Field_History__c>();
		}

		//System.assertEquals(1, testNote1FieldHistories.size());
		// System.assertEquals('Details__c', testNote1FieldHistories[0].Field_Name__c);
		// System.assertEquals('testNote1 details', testNote1FieldHistories[0].Long_Text_Value__c);
	}

	@isTest
	static void testInsertAndUpdateTextAreaFields() {
		// List<Patient_Note__c> testNotesToInsert = new List<Patient_Note__c>();
		// Patient_Note__c testNote1 = new Patient_Note__c
		// (
		// 	Details__c = 'testNote1 details'
		// );
		// testNotesToInsert.add(testNote1);
		// insert testNotesToInsert;

		Patient_Note__c testNote1 = [SELECT Id FROM Patient_Note__c LIMIT 1];

		Test.startTest();
		testNote1.Details__c = 'testNote1 changed details';
		update testNote1;
		Test.stopTest();

		List<Id> testNoteIds = new List<Id>();
		// for (Patient_Note__c currentNote: testNotesToInsert)
		// {
		testNoteIds.add(testNote1.Id);
		// }

		getFieldHistoryResults(testNoteIds);

		List<Field_History__c> testNote1FieldHistories = fieldHistoriesByNote.get(testNote1.Id);
		if (testNote1FieldHistories == null) {
			testNote1FieldHistories = new List<Field_History__c>();
		}

		//System.assertEquals(2, testNote1FieldHistories.size());
		for (Field_History__c currentFieldHistory : testNote1FieldHistories) {
			// System.assertEquals('Details__c', currentFieldHistory.Field_Name__c);
			// System.assert(currentFieldHistory.Long_Text_Value__c == 'testNote1 details' || currentFieldHistory.Long_Text_Value__c == 'testNote1 changed details');
		}
	}

	private static void getFieldHistoryResults(List<Id> testNoteIds) {
		List<Field_History__c> allFieldHistories = [SELECT Patient_Note__c, Field_Name__c, Long_Text_Value__c FROM Field_History__c WHERE Patient_Note__c IN :testNoteIds];

		fieldHistoriesByNote = new Map<ID, List<Field_History__c>>();

		for (Field_History__c currentFieldHistory : allFieldHistories) {
			List<Field_History__c> fieldHistories = fieldHistoriesByNote.get(currentFieldHistory.Patient_Note__c);
			if (fieldHistories == null) {
				fieldHistories = new List<Field_History__c>();
			}
			fieldHistories.add(currentFieldHistory);
			fieldHistoriesByNote.put(currentFieldHistory.Patient_Note__c, fieldHistories);
		}
	}
	/*
    public static testmethod void testPatientNotes() {
        test.startTest();
        Account patient= new Account(Name='Test');
        insert patient;

        Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
        Patient_Note__c consultantNote = new Patient_Note__c(
            Account__c = patient.Id,
            Consultation_Assigned_Date__c = System.today(),
            Consultation_Requested_By__c = 'Patient',
            Type__c = 'Psychotherapy Consultation Note',
            Additional_Concerns_Comments__c = 'test',
            Text_Narrative_Notes__c = 'Test'
        );
        insert consultantNote;
        update new Patient_Note__c(Id=consultantNote.Id,Additional_Concerns_Comments__c='another test 2');
        test.stopTest();

        Field_History__c[] tracks = [Select Field_Name__c, Long_Text_Value__c from Field_History__c where Patient_Note__c=:consultantNote.Id ];
        system.assertEquals(2, tracks.size());
    }
    public static testmethod void testBasicNotes() {
        test.startTest();
        Basic_Note__c bn =  new Basic_Note__c(Rich_Text_Notes__c='test');
        insert bn;
        bn.Rich_Text_Notes__c = 'test2';
        update bn;
        bn.Rich_Text_Notes__c = 'test3';
        update bn;
        bn.Rich_Text_Notes__c = 'test';
        update bn;
        test.stopTest();

        Field_History__c[] tracks = [Select Field_Name__c, Long_Text_Value__c,Old_Long_Text_Value__c from Field_History__c where Basic_Note__c=:bn.Id ];
        system.assertNotEquals(0, tracks.size());
    }*/
}
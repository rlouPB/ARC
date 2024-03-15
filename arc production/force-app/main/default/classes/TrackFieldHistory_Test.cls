@isTest
public class TrackFieldHistory_Test {
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
}
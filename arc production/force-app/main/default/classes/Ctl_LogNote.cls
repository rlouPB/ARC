public class Ctl_LogNote {
	@AuraEnabled
	public static Basic_Note__c createLogNote(String patientNoteStr, String accountId) {
		return createLogNote(patientNoteStr, accountId, false);
	}

	@AuraEnabled
	public static Basic_Note__c createLogNote(String patientNoteStr, String accountId, Boolean isDraftSave) {
		Id patientAccountId = accountId;

		Basic_Note__c patientNote = (Basic_Note__c) JSON.deserialize(patientNoteStr, Basic_Note__c.class);

		Id ptNoteRecordTypeId = Schema.getGlobalDescribe().get('Basic_Note__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Admissions_Officer_Highlight').getRecordTypeId();

		patientNote.Auto_Saved__c = isDraftSave;

		if (String.isNotBlank(patientNote.Id)) {
			patientNote.Id = Id.valueof(patientNote.Id);
		}

		if (patientNote.Patient_Name__c instanceof Id) {
			patientNote.Account__c = patientNote.Patient_Name__c;
			patientAccountId = patientNote.Patient_Name__c;
		}

		if (patientAccountId != null) {
			patientNote.Account__c = patientAccountId;

			List<Account> accs = [SELECT Id, Current_Admission__c FROM Account WHERE Id = :patientAccountId];
			if (!accs.isEmpty()) {
				if (patientNote.Admission__c == null)
					patientNote.Admission__c = accs[0].Current_Admission__c;
			}
		}

		patientNote.RecordtypeId = ptNoteRecordTypeId;

		upsert patientNote;

		return getPatientNoteDetails(patientNote.Id);
	}

	@AuraEnabled
	public static Basic_Note__c getPatientNoteDetails(String basicNoteId) {
		Basic_Note__c basicNote = new Basic_Note__c();

		if (basicNoteId != '' && basicNoteId != null) {
			basicNote = [SELECT Id, Call_Date_Time__c, Calling_Number__c, RecordTypeId, Recordtype.Name, Admission__c, Call_Status__c, Call_Type__c, Caller_Gender__c, Caller_Name__c, Patient_Name__c, Non_starter_Reason__c, Patient_City__c, Length_of_Call__c, Call_Method__c, Patient_State__c, Patient_Gender__c, Subject__c, Patient_Country__c, Caller_Country__c, Auto_Saved__c, Service_Type__c, LastModifiedDate, LastModifiedBy.Name, Caller_Affect_and_Presentation__c, Rich_Text_Notes__c FROM Basic_Note__c WHERE Id = :basicNoteId];
		}

		return basicNote;
	}
}
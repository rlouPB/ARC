public with sharing class Ctl_LogCall {
    @AuraEnabled
    public static Basic_Note__c createLogCall(String patientNoteStr, String accountId) {
        return createLogCall(patientNoteStr, accountId, false);
    }

    @AuraEnabled
    public static Basic_Note__c createLogCall(String patientNoteStr, String accountId, Boolean isDraftSave) {
        Basic_Note__c patientNote = (Basic_Note__c) JSON.deserialize(patientNoteStr, Basic_Note__c.class);

        Id ptNoteRecordTypeId = Schema.getGlobalDescribe()
					.get('Basic_Note__c')
					.getDescribe()
					.getRecordTypeInfosByDeveloperName()
					.get('Admissions_Notes')
					.getRecordTypeId();

        // if (patientNote.Caller_Name__c instanceOf Id) {
        //     patientNote.Contact__c = patientNote.Caller_Name__c;
        // } else {
        //     patientNote.Caller_Name__c = patientNote.Caller_Name__c;
        // }

        // if (patientNote.Patient_Name__c instanceOf Id) {
        //     patientNote.Account__c = patientNote.Patient_Name__c;
        //     patientAccountId = patientNote.Patient_Name__c;
        // }

        patientNote.RecordtypeId = ptNoteRecordTypeId;
        patientNote.Auto_Saved__c = isDraftSave;

        //find current admission
        if (accountId != null) {
            List<Account> accs = [
							SELECT Id, Current_Admission__c, Current_Admission__r.Stage__c, Current_Admission__r.Service_Type__c, Patient_Contact__c
							FROM Account
							WHERE Id = :accountId
						];

            if (!accs.isEmpty()) {
                Id correctCurrentAdmissionId = getCurrentAdmissionId(accs[0]);
                if (patientNote.Admission__c == null)
                    patientNote.Admission__c = correctCurrentAdmissionId;
            }
        }

        upsert patientNote;

        //return newPatientNoteRecord;
        return getPatientNoteDetails(patientNote.Id);
    }

    //return current or do DML as necessary to have a valid Current Admission Id to use
    static Id getCurrentAdmissionId(Account patientAccount) {
        Id returnAdmissionId = patientAccount.Current_Admission__c;
        Set<String> endStages = new Set<String>{ 'Discharged', 'Declined', 'Withdrawn' };
        Set<String> inactiveStages = new Set<String>{ 'Inactive' };

        if (returnAdmissionId == null || endStages.contains(patientAccount.Current_Admission__r.Stage__c)) {
            Admission__c newAdmission = new Admission__c(
							Patient_Account__c = patientAccount.Id,
							Service_Type__c = patientAccount.Current_Admission__r.Service_Type__c,
							Patient_Contact__c = patientAccount.Patient_Contact__c
						);
            insert newAdmission;
            returnAdmissionId = newAdmission.Id;
        } else if (inactiveStages.contains(patientAccount.Current_Admission__r.Stage__c)) {
            Admission__c updateAdmission = new Admission__c(
							Id = patientAccount.Current_Admission__c,
							Stage__c = 'Open Inquiry',
							Outcome_Reason__c = null
						);
            update updateAdmission;
        }

        return returnAdmissionId;
    }

    @AuraEnabled
    public static Contact getPatientDetails(String patientId) {
        return [
					SELECT Id, Distinguished_Name__c, Name, AccountId, Account.Current_Admission__r.Service_Type__c
					FROM Contact
					WHERE AccountId = :patientId
				];
    }

    @AuraEnabled
    public static Account getAccountServiceTyoe(String patientId) {
        return [SELECT Id, Current_Admission__r.Service_Type__c FROM Account WHERE Id = :patientId];
    }

    @AuraEnabled
    public static Contact getContactDetails(String contactId) {
        return [SELECT Id, Name FROM Contact WHERE Id = :contactId];
    }

    @AuraEnabled
    public static Basic_Note__c getPatientNoteDetails(String patientNoteId) {
        Basic_Note__c patientNote = new Basic_Note__c();

        if (patientNoteId != '' && patientNoteId != null) {
            patientNote = [
							SELECT
								Id,
								Call_Date_Time__c,
								Calling_Number__c,
								RecordTypeId,
								Recordtype.Name,
								Admission__c,
								Call_Status__c,
								Call_Type__c,
								Caller_Gender__c,
								Caller_Name__c,
								Patient_Name__c,
								Non_starter_Reason__c,
								Patient_City__c,
								Length_of_Call__c,
								Call_Method__c,
								Patient_State__c,
								Patient_Gender__c,
								Subject__c,
								Patient_Country__c,
								Caller_Country__c,
								Auto_Saved__c,
								Service_Type__c,
								LastModifiedDate,
								LastModifiedBy.Name,
								Caller_Affect_and_Presentation__c,
								Rich_Text_Notes__c,
								Account__c,
								Account__r.Name,
								Contact__c,
								Contact__r.Name,
								Contact__r.Distinguished_Name__c
							FROM Basic_Note__c
							WHERE Id = :patientNoteId
						];
        }

        return patientNote;
    }

    @AuraEnabled
    public static Boolean hasRelationship(Id patientId, Id contactId) {
        List<Related_Contact__c> relatedContactList = [
					SELECT Id
					FROM Related_Contact__c
					WHERE Account__c = :patientId AND Contact__c = :contactId
				];
        if (!relatedContactList.isEmpty()) {
            return true;
        }
        return false;
    }

    @AuraEnabled
    public static NewRelatedContactCtl.RecordTypeInfoWrapper getContactRecordTypeDetails() {
        return NewRelatedContactCtl.getContactRecordTypeDetails();
    }
}
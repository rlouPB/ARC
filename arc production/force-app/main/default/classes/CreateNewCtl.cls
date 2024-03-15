public with sharing class CreateNewCtl {
	@AuraEnabled(cacheable=true)
	public static string getFLowNameByDocTypeName(string docTypeName) {
		try {
			return (string) RecordUtils.getRecordBySearchField('Med_Records_Document_Type__mdt', 'Name__c', docTypeName, 'Flow_Name__c').get('Flow_Name__c');
		} catch (Exception ex) {
			system.debug('Error: ' + ex.getMessage());
		}
		return null;
	}

	@AuraEnabled(cacheable=true)
	public static string getFormTemplateIdByDocTypeName(string docTypeName) {
		try {
			return [SELECT Id FROM disco__Form_Template__c WHERE DocType_Name__c = :docTypeName LIMIT 1][0].Id;
		} catch (Exception e) {
			system.debug('getFormTemplateIdByDocTypeName ERROR : ' + e.getMessage());
		}
		return null;
	}

	//Used by CreateNew.cmp
	@AuraEnabled
	public static Map<String, String> checkBlockedDuplicates(String accountId, String docTypeName, String sObjectType) {
		Map<String, String> returnMap = new Map<String, String>{ 'allowCreate' => 'true' };
		String safeDocTypeName = docTypeName.replace('-', ' ');
		Boolean allowCreate = true;
		try {
			switch on sObjectType {
				// when 'Away Medication Order' {
				//     allowCreate = (getDraftAwayOrdersForPatient(accountId).size() == 0);
				// }
				// when 'Medication Self-Administration (MSA) Order'
				// {
				//     allowCreate = (getDraftMSAOrdersForPatient(accountId).size() == 0);
				// }
				when 'Patient_Note__c' {
					allowCreate = hasExistingPatientNotes(accountId, safeDocTypeName) == false;
				}
				when 'Discharge_Disposition__c' {
					allowCreate = hasExistingDraftDDRs(accountId) == false;
				}
				when 'Case_Abstract__c' {
					allowCreate = hasExistingDraftCaseAbstracts(accountId, docTypeName + '%') == false;
				}
			}
		} catch (Exception e) {
			allowCreate = false;
			returnMap.put('errorMessage', 'Unable to create: ' + e.getMessage() + '  \n' + e.getStackTraceString());
		}
		if (!allowCreate) {
			returnMap.put('allowCreate', 'false');
			if (!returnMap.containsKey('errorMessage')) {
				returnMap.put('errorMessage', 'The patient already has a draft ' + docTypeName + '. Please update this under Drafts.');
			}
		}
		return returnMap;
	}
	private static Boolean hasExistingPatientNotes(Id accountId, String patientNoteType) {
		return ([SELECT Id FROM Patient_Note__c WHERE Account__c = :accountId AND Status__c = 'Draft' AND Type__c = :patientNoteType].size() > 0);
	}
	private static Boolean hasExistingDraftDDRs(String accountId) {
		return ([SELECT COUNT() FROM Discharge_Disposition__c WHERE Status__c = 'Draft' AND Admission__r.Patient_Account__c = :accountId] > 0);
	}
	private static Boolean hasExistingDraftCaseAbstracts(String accountId, String caseAbstractType) {
		return ([SELECT Id FROM Case_Abstract__c WHERE Status__c = 'Draft' AND Admission__r.Patient_Account__c = :accountId AND Case_Abstract_Type__c LIKE :caseAbstractType].size() > 0);
	}
}
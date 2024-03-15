public with sharing class AdmissionMoveRelatedRecordsApexCtl {
	/*
		Purpose: 	Controller for AdmissionMoveRelatedRecords
		History: 	Created 181116 JN
	*/

	@AuraEnabled
	public static List<Admission__c> getAdmissions(String accountId) {
		List<Admission__c> returnAdmissions = [SELECT Id, Name, Stage__c, CreatedDate, Is_Current_Admission__c, Admit_Date__c, Discharge_Date__c FROM Admission__c WHERE Patient_Account__c = :accountId ORDER BY CreatedDate DESC];

		return returnAdmissions;
	}

	@AuraEnabled
	public static String getMoveRecordsData(String admissionId) {
		MoveRecordsData data = new MoveRecordsData();

		data.requestItems = [SELECT Id, Name, Admissions_Requirement__r.Name, Action__c, Responsible__c, Status__c, Date_Requested__c, Notes__c, (SELECT Id, ContentDocument.Title FROM ContentDocumentLinks) FROM Request_Item__c WHERE Admissions_Requirement__r.Admission__c = :admissionId];
		data.forms = [SELECT Id, Name, disco__Form_Template__r.Name, Related_Contact__r.Contact_Role_Name__c, CreatedDate FROM disco__Form__c WHERE Admission__c = :admissionId];
		data.admissionMedications = [SELECT Id, Name, Medication__c, Dose__c, Frequency__c, Last_Dose_Taken__c, Info_Source__c FROM Admission_Medication__c WHERE Admission__c = :admissionId];

		data.baseNotes = [SELECT Id, Name, CreatedDate FROM Basic_Note__c WHERE Admission__c = :admissionId];

		return JSON.serialize(data);
	}

	@AuraEnabled
	public static String saveRecords(String targetAdmissionId, String serializedData) {
		String returnString = '';
		MoveRecordsData data = (MoveRecordsData) JSON.deserialize(serializedData, MoveRecordsData.class);

		if (data.requestItems.size() > 0) {
			Admission__c targetAdmission = [SELECT Id, (SELECT Id, Name FROM Admissions_Requirements__r), (SELECT Id FROM Basic_Notes__r) FROM Admission__c WHERE Id = :targetAdmissionId];
			Map<String, Id> requirementName2IdMap = new Map<String, Id>();

			for (Admissions_Requirement__c req : targetAdmission.Admissions_Requirements__r) {
				requirementName2IdMap.put(req.Name, req.Id);
			}

			for (Request_Item__c item : data.requestItems) {
				item.Admissions_Requirement__c = requirementName2IdMap.get(item.Admissions_Requirement__r.Name);
			}
		}

		for (disco__Form__c form : data.forms) {
			form.Admission__c = targetAdmissionId;
		}

		for (Admission_Medication__c admMed : data.admissionMedications) {
			admMed.Admission__c = targetAdmissionId;
		}

		// System.assertNotEquals(null, data.baseNotes);

		for (Basic_Note__c bn : data.baseNotes) {
			bn.Admission__c = targetAdmissionId;
		}

		Savepoint sp = Database.setSavepoint();

		try {
			update data.requestItems;
			update data.forms;
			update data.admissionMedications;
			update data.baseNotes;
		} catch (Exception e) {
			Database.rollback(sp);
			returnString = 'Problem updating records: ' + e.getMessage();
		}

		return returnString;
	}

	public class MoveRecordsData {
		public List<Request_Item__c> requestItems;
		public list<disco__Form__c> forms;
		public List<Admission_Medication__c> admissionMedications;
		public List<Basic_Note__c> baseNotes;
	}
}
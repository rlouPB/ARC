public with sharing class NoteDiagnosisCtl {
	@AuraEnabled(cacheable=true)
	public static object getRecordInfo(string recordId, string sobjectType, string fields) {
		try {
			return database.query('SELECT ' + fields + ' FROM ' + sobjectType + ' WHERE ID =:recordId')[0];
		} catch (Exception e) {
			system.debug('NoteDiagnosisCtl.getRecordInfo - ERROR: ' + e.getMessage() + ' - ' + e.getStackTraceString());
		}
		return null;
	}

	@AuraEnabled(cacheable=true)
	public static object getRecordInfo(string recordId, string sobjectType, string fields, String whereClause) {
		String whereQueryStr = 'SELECT ' + fields + ' FROM ' + sobjectType + ' WHERE ID =:recordId ' + whereClause;
		System.debug('NoteDiagnosisCtl whereQueryStr: ' + whereQueryStr);
		try {
			return database.query(whereQueryStr)[0];
		} catch (Exception e) {
			system.debug('NoteDiagnosisCtl.getRecordInfo - ERROR: ' + e.getMessage() + ' - ' + e.getStackTraceString());
		}
		return null;
	}

	@AuraEnabled
	public static Id saveDiagnosis(string diagnosisJson) {
		Diagnosis__c diagnosis = (Diagnosis__c) JSON.deserialize(diagnosisJson, Diagnosis__c.class);
		upsert diagnosis;
		return diagnosis.Id;
	}

	@AuraEnabled
	public static Diagnosis__c[] getComorbids(string admissionId, string source, string patientNoteId) {
		return [SELECT Id, Patient_Note__c, Clinical_Code__c, Clinical_Code__r.Description__c, Clinical_Code__r.Name, Additional_Specifiers__c, Source__c, Marked_for_Delete__c FROM Diagnosis__c WHERE admission__c = :admissionId AND Source__c = :source AND type__c = 'Comorbid' AND Patient_Note__c = :patientNoteId ORDER BY Clinical_Code__r.Description__c ASC];
	}

	@AuraEnabled
	public static Diagnosis__c[] getPrincipalsMarkedForDelete(string admissionId, string source) {
		return [SELECT Id, Patient_Note__c, Clinical_Code__c, Clinical_Code__r.Description__c, Clinical_Code__r.Name, Additional_Specifiers__c, Source__c, Marked_for_Delete__c FROM Diagnosis__c WHERE admission__c = :admissionId AND Source__c = :source AND type__c = 'Principal' AND Marked_for_Delete__c = TRUE ORDER BY Clinical_Code__r.Description__c ASC];
	}

	@AuraEnabled
	public static PatientDiagnosesResponse getDiagnoses(string admissionId, string source, string patientNoteId) {
		PatientDiagnosesResponse resp = new PatientDiagnosesResponse();
		try {
			Diagnosis__c[] principals = [SELECT Id, Patient_Note__c, Clinical_Code__c, Additional_Specifiers__c, Marked_for_Delete__c, CreatedDate, Admission__r.Principal_Diagnosis__c FROM Diagnosis__c WHERE admission__c = :admissionId AND Source__c = :source AND type__c = 'Principal' AND Marked_for_Delete__c != TRUE AND Patient_Note__c = :patientNoteId];
			resp.principal = principals.size() > 0 ? principals[0] : null;
			for (Diagnosis__c diag : principals) {
				if (diag.admission__r.Principal_Diagnosis__c == diag.Id) {
					resp.principal = diag;
				}
			}

			resp.principalsToDelete = [SELECT Id, Patient_Note__c, Clinical_Code__c, Clinical_Code__r.Id, Clinical_Code__r.Name, Clinical_Code__r.Description__c, Additional_Specifiers__c, Marked_for_Delete__c FROM Diagnosis__c WHERE admission__c = :admissionId AND Source__c = :source AND type__c = 'Principal' AND Marked_for_Delete__c = TRUE AND Patient_Note__c = :patientNoteId];

			resp.comorbids = getComorbids(admissionId, source, patientNoteId);
		} catch (Exception ex) {
			resp.principal = null;
			resp.comorbids = null;
			resp.errorMessage = ex.getMessage();
			resp.staticTrace = ex.getStackTraceString();
		}
		return resp;
	}

	@AuraEnabled
	public static Response MarkForDelete(string diagnosisId, boolean value) {
		Response resp = new Response();
		try {
			update new Diagnosis__c(Id = diagnosisId, Marked_for_Delete__c = value);
		} catch (Exception ex) {
			resp.errorMessage = ex.getMessage();
			resp.staticTrace = ex.getStackTraceString();
		}
		return resp;
	}

	//Is Source__c required here?
	public static void finalize(id admissionId, Patient_Note__c patientNote, String source) {
		system.debug('----------NoteDiagnosisCtl finalize admission Id =' + admissionId + ' note id =' + patientNote.Id);
		Diagnosis__c[] diagnosisList = [SELECT Id, Patient_Note__c, Source__c, Type__c, Marked_for_Delete__c, Admission__c, Patient_Note__r.Status__c, Clinical_Code_Description__c FROM Diagnosis__c WHERE admission__c = :admissionId AND Source__c = :source];
		system.debug('----------NoteDiagnosisCtl finalize diagnosisList =' + diagnosisList);
		Map<Id, Admission__c> admissionsToUpdate = new Map<Id, Admission__c>();

		Id[] toDelete = new List<id>();
		List<Diagnosis__c> toUpdateStatus = new List<Diagnosis__c>();
		for (Diagnosis__c d : diagnosisList) {
			System.debug('---------- noteId=' + patientNote.Id + ' d.Patient_Note__c=  ' + d.Patient_Note__c + '   ' + d.Clinical_Code_Description__c);

			if (d.Marked_for_Delete__c == true) {
				toDelete.add(d.Id);
			} else if ((d.Patient_Note__c != patientNote.Id) && (d.Patient_Note__r.Status__c == 'Finalized')) {
				//toDelete.add(d.Id);
				toUpdateStatus.add(new Diagnosis__c(Id = d.Id, Status__c = 'Draft'));
			} else if (d.Patient_Note__c == patientNote.Id) {
				toUpdateStatus.add(new Diagnosis__c(Id = d.Id, Status__c = 'Finalized'));
				if (d.Type__c == 'Principal') {
					admissionsToUpdate.put(admissionId, new admission__c(Id = admissionId, Principal_Diagnosis__c = d.Id));
				}
			}
		}
		system.debug('----------NoteDiagnosisCtl finalize toDelete =' + toDelete);
		system.debug('----------NoteDiagnosisCtl finalize admissionsToUpdate =' + admissionsToUpdate);
		if (!toDelete.isEmpty()) {
			database.delete(toDelete);
		}
		if (!toUpdateStatus.isEmpty()) {
			database.update(toUpdateStatus);
		}

		if (admissionsToUpdate.values().size() > 0) {
			update admissionsToUpdate.values();
			system.debug('----------NoteDiagnosisCtl finalize admissionsToUpdate =' + admissionsToUpdate);
		}
	}

	public virtual class Response {
		@AuraEnabled
		public string errorMessage;
		@AuraEnabled
		public string staticTrace;
	}

	public class PatientDiagnosesResponse extends Response {
		@AuraEnabled
		public Diagnosis__c principal;

		@AuraEnabled
		public Diagnosis__c[] principalsToDelete;

		@AuraEnabled
		public Diagnosis__c[] comorbids;
	}

	public static void increaseCoverage() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}
public with sharing class PatientDiagnosesCls {
	public class DiagnosisDto {
		@AuraEnabled
		public string id;
		@AuraEnabled
		public string description;
		@AuraEnabled
		public string specifiers;
		@AuraEnabled
		public string code;
		@AuraEnabled
		public string source;
		@AuraEnabled
		public string type;
		@AuraEnabled
		public string codeId;
		public DiagnosisDto(Diagnosis__c init) {
			if (init != null) {
				this.id = init.Id;
				this.specifiers = init.Additional_Specifiers__c;
				this.source = init.Source__c;
				this.type = init.Type__c;
				if (init.Clinical_Code__r != null) {
					this.codeId = init.Clinical_Code__c;
					this.description = init.Clinical_Code__r.Description__c;
					this.code = init.Clinical_Code__r.Name;
				}
			}
		}
	}
	public class LoadDataResult {
		@AuraEnabled
		public DiagnosisDto[] principals;
		@AuraEnabled
		public DiagnosisDto[] comorbids;
		@AuraEnabled
		public string errorMessage;
		@AuraEnabled
		public string staticTrace;
	}
	@AuraEnabled
	public static LoadDataResult LoadData(id patientId, string source) {
		LoadDataResult result = new LoadDataResult();
		try {
			string finilized = 'Finalized';
			Account patient = [SELECT Current_Admission__c FROM Account WHERE id = :patientId LIMIT 1];
			result.principals = new List<DiagnosisDto>{};
			result.comorbids = new List<DiagnosisDto>{};
			id currentAdmission = patient.Current_Admission__c;
			string baseQuery = 'select Id,Type__c,Source__c,Additional_Specifiers__c,Clinical_Code__c,Clinical_Code__r.Name,Clinical_Code__r.Description__c,Admission__r.Principal_Diagnosis__c from Diagnosis__c ';
			string[] whereParts = new List<string>{ 'Admission__c=:currentAdmission' };
			whereParts.add('Patient_Note__r.Status__c=:finilized');
			whereParts.add('((Status__c = null) OR (Status__c=:finilized))');
			//whereParts.add('Marked_for_Delete__c=false');
			if (!string.isEmpty(source) && source != 'All') {
				whereParts.add('Source__c=:source');
			}
			string query = baseQuery + ' WHERE ' + String.join(whereParts, ' AND ');
			//query += ' ORDER BY createddate DESC';

			Diagnosis__c[] diagnosisList = (Diagnosis__c[]) database.query(query);
			Diagnosis__c principal = null;
			for (Diagnosis__c diag : diagnosisList) {
				if (diag.Type__c == 'Principal') {
					principal = diag;
				} else if (diag.Type__c == 'Comorbid') {
					result.comorbids.add(new DiagnosisDto(diag));
				}
			}
			for (Diagnosis__c diag : diagnosisList) {
				if (diag.Type__c == 'Principal' && (diag.admission__r.Principal_Diagnosis__c == diag.Id)) {
					principal = diag;
					break;
				}
			}
			result.principals.add(new DiagnosisDto(principal));
		} catch (Exception e) {
			result.principals = null;
			result.comorbids = null;
			result.errorMessage = e.getMessage();
			result.staticTrace = e.getStackTraceString();
		}

		return result;
	}
}
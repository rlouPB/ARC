public class ListAssignedClinicians {
	private static final String MANAGED_CLINICIANS_PERMISSION_NAME = 'Manage_Assigned_Clinicians';

	@AuraEnabled
	public static List<Assigned_Clinician__c> getAssignedClinicians(String accountID, String showValue) {
		List<Assigned_Clinician__c> results = new List<Assigned_Clinician__c>();
		if (showValue == 'all') {
			results = [SELECT User_Name__c, Role__c, Start_Date__c, End_Date__c, User__c, User__r.Name, User__r.Professional_Name__c, User__r.Id, Admission__c, Admission__r.Substance_Use_Counselor_Active__c, Admission__r.Registered_Dietician_Nutritionist_Active__c FROM Assigned_Clinician__c WHERE Patient_Account__c = :accountID ORDER BY End_Date__c DESC NULLS FIRST, Start_Date__c DESC];
		} else if (showValue == 'active') {
			results = [SELECT User_Name__c, Role__c, Start_Date__c, End_Date__c, User__c, User__r.Name, User__r.Professional_Name__c, User__r.Id, Admission__c, Admission__r.Substance_Use_Counselor_Active__c, Admission__r.Registered_Dietician_Nutritionist_Active__c FROM Assigned_Clinician__c WHERE Patient_Account__c = :accountID AND Start_Date__c <= :Date.today() AND (End_Date__c = NULL OR End_Date__c >= :Date.today()) ORDER BY Start_Date__c DESC, End_Date__c DESC NULLS LAST];
		}

		Assigned_Clinician__c clinicianToAdd = new Assigned_Clinician__c(Start_Date__c = Date.today(), Role__c = 'Team Leader');
		results.add(clinicianToAdd);
		return results;
	}

	@AuraEnabled
	public static List<String> getRoles() {
		List<String> returnValues = new List<String>();
		Schema.DescribeFieldResult fieldResult = Assigned_Clinician__c.Role__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			returnValues.add(pickListVal.getLabel());
		}
		return returnValues;
	}

	@AuraEnabled
	public static void saveAssignedClinicians(String input, String admissionID, String patientID) {
		JSONCTMParser objParser = new JSONCTMParser();
		List<JSONCTMParser> listMeta = objParser.Parse(input);

		List<Assigned_Clinician__c> cliniciansToUpsert = new List<Assigned_Clinician__c>();
		List<Assigned_Clinician__c> cliniciansToDelete = new List<Assigned_Clinician__c>();

		for (JSONCTMParser obj : listMeta) {
			Assigned_Clinician__c clinician = new Assigned_Clinician__c();
			if (String.isNotBlank(obj.Id)) {
				clinician.Id = obj.Id;
			}

			clinician.User__c = obj.userID;
			clinician.Role__c = obj.role;
			clinician.Admission__c = admissionID;
			clinician.Patient_Account__c = patientID;

			if (obj.startDate == null || obj.startDate.trim() == '') {
				clinician.Start_Date__c = null;
			} else {
				clinician.Start_Date__c = Date.valueOf(obj.startDate);
			}

			if (obj.endDate == null || obj.endDate.trim() == '') {
				clinician.End_Date__c = null;
			} else {
				clinician.End_Date__c = Date.valueOf(obj.endDate);
			}

			if (obj.isDeleted != 'true' && clinician.User__c != null) {
				cliniciansToUpsert.add(clinician);
			}

			if (obj.isDeleted == 'true' && String.isNotBlank(clinician.Id)) {
				cliniciansToDelete.add(clinician);
			}
		}

		delete cliniciansToDelete;
		upsert cliniciansToUpsert;
	}

	// Added by Sols ARC-2100
	@AuraEnabled
	public static Boolean updateActiveAssignedClinician(String admissionID, String activeType, Boolean checked) {
		if (activeType == 'Dietician') {
			Admission__c adm = new Admission__c(Id = admissionID, Registered_Dietician_Nutritionist_Active__c = checked);
			update adm;
		} else if (activeType == 'SUS') {
			Admission__c adm = new Admission__c(Id = admissionID, Substance_Use_Counselor_Active__c = checked);
			update adm;
		}
		return true;
	}

	@AuraEnabled
	public static Boolean checkManagedCliniciansPermission() {
		return FeatureManagement.checkPermission(MANAGED_CLINICIANS_PERMISSION_NAME);
	}

	@AuraEnabled
	public static Assigned_Clinician__c getAssignedClinicianInstance() {
		Assigned_Clinician__c clinician = new Assigned_Clinician__c(Start_Date__c = Date.today(), Role__c = 'Team Leader');
		return clinician;
	}

	@AuraEnabled
	public static String getAdmissionID(String accountID) {
		Account currentAccount = [SELECT Current_Admission__c FROM Account WHERE ID = :accountID LIMIT 1];
		return currentAccount.Current_Admission__c;
	}

	public class JSONCTMParser {
		public String Id;
		public String userID;
		public String role;
		public String startDate;
		public String endDate;
		public String isDeleted;

		public List<JSONCTMParser> parse(String json) {
			return (List<JSONCTMParser>) System.JSON.deserialize(json, List<JSONCTMParser>.class);
		}
	}
}
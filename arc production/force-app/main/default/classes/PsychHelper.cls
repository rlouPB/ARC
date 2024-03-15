public with sharing class PsychHelper {
	private static Map<Id, Admission__c> admissionsMap;
	private static Map<String, String> requestDocTypeRecordTypeMap = new Map<String, String>{ 'Referral_for_Neuropsychological_Scr' => 'Neuropsychological_Screening_Request', 'Referral_for_Neuropsychological_Testing' => 'Neuropsychological_Testing_Request', 'Referral_for_Psychological_Testing' => 'Psychological_Testing_Request' };
	private static Map<String, String> requestDocTypeRecordTypeNameMap = new Map<String, String>{ 'Referral_for_Neuropsychological_Scr' => 'Neuropsychological Screening Request', 'Referral_for_Neuropsychological_Testing' => 'Neuropsychological Testing Request', 'Referral_for_Psychological_Testing' => 'Psychological Testing Request' };
	private static Map<String, String> reportDocTypeRecordTypeMap = new Map<String, String>{ 'Referral_for_Neuropsychological_Scr' => 'Neuropsychological_Screening_Report', 'Referral_for_Neuropsychological_Testing' => 'Neuropsychological_Testing_Report', 'Referral_for_Psychological_Testing' => 'Psychological_Testing_Report' };
	private static Map<String, Schema.RecordTypeInfo> psychTestingRequestRecordTypeMap = Schema.SObjectType.Psych_Testing_Request__c.getRecordTypeInfosByDeveloperName();
	private static Map<Id, Assigned_Clinician__c> psychotherapistByAdmissionIdMap;
	private static Id PSYCH_TESTING_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Psych_Testing_Request__c.getRecordTypeInfosByDeveloperName().get('Psychological_Testing_Request').getRecordTypeId();
	private static List<Psych_Testing_Request__c> psychTestingRequestsToInsert = new List<Psych_Testing_Request__c>();

	public PsychHelper() {
	}
	public static String getRecordTypeIdByDocTypeName(String docTypeName, Map<String, String> docTypeMap, Map<String, Schema.RecordTypeInfo> rtMap) {
		String recordTypeName = docTypeMap.get(docTypeName);
		String recordTypeId = rtMap.get(recordTypeName).getRecordTypeId();
		return recordTypeId;
	}

	public void fetchInfo(Set<Id> admissionIds) {
		admissionsMap = new Map<Id, Admission__c>([SELECT Id, Patient_Account__c, (SELECT Id, User__c FROM Assigned_Clinicians__r WHERE Role__c = 'Psychotherapist' AND Start_Date__c <= TODAY AND (End_Date__c >= TODAY OR End_Date__c = NULL) ORDER BY LastModifiedDate DESC LIMIT 1) FROM Admission__c WHERE Id IN :admissionIds]);

		psychotherapistByAdmissionIdMap = new Map<Id, Assigned_Clinician__c>();
		// for (Admission__c adm : [
		//         SELECT Id,
		//             (SELECT Id, User__c
		//                 FROM Assigned_Clinicans__r
		//                 WHERE Role__c = 'Psychotherapist'
		//                     AND Start_Date__c <= TODAY
		//                     AND (End_Date__c >= TODAY OR End_Date__c = null)
		//                 ORDER BY LastModifiedDate DESC
		//                 LIMIT 1)
		//         FROM Admission__c
		//         WHERE Id IN : admissionIds])
		for (Admission__c adm : admissionsMap.values()) {
			if (!adm.Assigned_Clinicians__r.isEmpty()) {
				psychotherapistByAdmissionIdMap.put(adm.Id, adm.Assigned_Clinicians__r[0]);
			}
		}
		// List<Assigned_Clinician__c> psychotherapists = [
		//         SELECT Id, Admission__c, User__c
		//         FROM Assigned_Clinician__c
		//         WHERE Admission__c IN : admissionIds
		//             AND Role__c = 'Psychotherapist'
		//             AND Start_Date__c];
		// for(Assigned_Clinician__c ac : psychotherapists) {
		//     psychotherapistByAdmissionIdMap.put(ac.Admission__c, ac);
		// }
	}

	public void createPsychTestingRequest(Id admissionId) {
		// currently PB calls this flow: Create Psych Testing Request
		// MeetingId - won't have this
		// AdmissionId
		// AccountId
		// CaseId - doen't exist on psych testing request object
		// Need to get the Therapist__c from CaseTeamRole where Name = "Therapist". This doesn't
		// look right, should we be using Assigned Clinicians here? Use the Assigned Clinicians
		// on Admission for role of "Psychotherapist".
		// Before changing to Admitted we need validation to make sure we have an Assigned Clinician
		// Psychotherapist.
		// add to draft & snapshots requests & reports
		Admission__c admission = admissionsMap.get(admissionId);
		if (null != admission) {
			Psych_Testing_Request__c ptr = new Psych_Testing_Request__c(Patient_Account__c = admission.Patient_Account__c, Admission__c = admissionId, Therapist__c = psychotherapistByAdmissionIdMap.get(admissionId).User__c, RecordTypeId = PSYCH_TESTING_REQUEST_RECORDTYPE_ID);
			psychTestingRequestsToInsert.add(ptr);
		}
	}

	public void insertPsychTestingRequests() {
		// if(psychTestingRequestsToInsert.size() > 0) {
		insert psychTestingRequestsToInsert;
		// }
	}

	@InvocableMethod(label='Create Psych Testing Request and Report' description='Create Psych Testing Request and Report')
	public static List<PsychTestingResult> createPsychTestingRequestAndReport(List<PsychTestingWrapper> request) {
		//parse input parameters
		String patientId = request.get(0).patientId;
		String docTypeName = request.get(0).docTypeName;
		String requestRTId = getRecordTypeIdByDocTypeName(docTypeName, requestDocTypeRecordTypeMap, psychTestingRequestRecordTypeMap);

		//set Independent Testing on Neuropsych Screening and Neuropsych Testing
		Boolean independentTesting = (docTypeName.contains('Neuro'));

		Psych_Testing_Request__c requestObj = new Psych_Testing_Request__c(Patient_Account__c = patientId, RecordTypeId = requestRTId, Independent_Testing__c = independentTesting);
		insert requestObj;
		PsychTestingResult res = new PsychTestingResult();
		res.requestId = requestObj.Id;
		res.docTypeName = requestDocTypeRecordTypeNameMap.get(docTypeName);
		return new List<PsychTestingResult>{ res };
	}
	public class PsychTestingWrapper {
		@InvocableVariable
		public String patientId;

		@InvocableVariable
		public String docTypeName;
	}
}
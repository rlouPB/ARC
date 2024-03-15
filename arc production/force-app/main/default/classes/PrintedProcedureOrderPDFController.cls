public with sharing class PrintedProcedureOrderPDFController {
	public String poId { get; set; }
	public Procedure_Order__c procedureOrder { get; set; }
	public Account patient { get; set; }
	public Id logoContentVersionId { get; set; }
	public String eSignatureFilename { get; set; }
	public String eSignatureProfessionalName { get; set; }

	// public Boolean isLabOrder {get; private set;}
	public Boolean hasLabs { get; set; }

	public List<Lab_Observation__c> labs { get; set; }
	public List<Insurance_Policy__c> insurancePolicies { get; set; }

	public PrintedProcedureOrderPDFController() {
		poId = ApexPages.CurrentPage().getparameters().get('poId');
		labs = new List<Lab_Observation__c>();
		insurancePolicies = new List<Insurance_Policy__c>();
	}
	public PageReference init() {
		if (null != poId) {
			procedureOrder = [SELECT Date_of_Order__c, Activation_Date__c, Description__c, Id, Indication__c, MD_Comments__c, Patient_Account__c, Patient_Consultation_Requested_With__c, Patient_Name__c, Practice_Group__c, Procedure__c, RecordTypeId, Related_Records__c, Specific_Clinician__c, Status__c, Testing_Facility__r.Name, Testing_Facility__r.BillingStreet, Testing_Facility__r.BillingCity, Testing_Facility__r.BillingState, Testing_Facility__r.BillingPostalCode, Testing_Facility__r.Phone__c, Phone_Order_MD__c, Finalized_By_User__c, RecordType.Name FROM Procedure_Order__c WHERE Id = :poId];
			patient = [SELECT NAME, current_admission__c, Previous_Admissions_Numeric__c, Medical_Record_Number__c, Current_Admission__r.Admit_Date__c, Date_of_Birth__c, Sex_Assigned_at_Birth__c, Age__c, (SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode FROM Contacts) FROM Account WHERE Id = :procedureOrder.Patient_Account__c];
			hasLabs = false;
			if (procedureOrder.Recordtype.Name == 'Lab Order') {
				// isLabOrder = true;
				labs = [SELECT Compendium_Entry__r.Test_Name__c, Order_Date__c FROM Lab_Observation__c WHERE Procedure_Order__c = :poId ORDER BY Order_Date__c];

				if (!labs.isEmpty()) {
					hasLabs = true;
				}

				insurancePolicies = [SELECT Admission__c, Insurance_Provider_Name__c, Policy_Start_Date__c, Policy_End_Date__c, Policy_Number__c, Provider_Services_Phone__c FROM Insurance_Policy__c WHERE Admission__c = :patient.current_admission__c AND Policy_End_Date__c >= TODAY ORDER BY CreatedDate];
			}
			List<ContentVersion> logoContentVersions = [SELECT Id, VersionData, FileType FROM ContentVersion WHERE ContentDocument.Title = 'Riggs_Logo_Medical_Records' AND IsLatest = TRUE WITH SECURITY_ENFORCED];
			if (logoContentVersions.size() != 0) {
				logoContentVersionId = logoContentVersions[0].Id;
			}

			Id userIdForESig;
			if (null != procedureOrder.Phone_Order_MD__c) {
				userIdForESig = procedureOrder.Phone_Order_MD__c;
			} else if (null != procedureOrder.Finalized_By_User__c) {
				userIdForESig = procedureOrder.Finalized_By_User__c;
			}

			if (null == userIdForESig) {
				eSignatureFilename = 'NOT AVAILABLE';
			} else {
				User u = [SELECT ESignature_Resource_Name__c, Professional_Name__c FROM User WHERE Id = :userIdForESig LIMIT 1];
				eSignatureFilename = u.ESignature_Resource_Name__c;
				eSignatureProfessionalName = u.Professional_Name__c;
			}
		}
		return null;
	}
}
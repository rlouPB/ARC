public with sharing class PrintedMedicalRecordController {
	public String currentRecordId { get; set; }
	transient public List<List<TreeGridNode.PrintedIncludedObject>> includedObjects { get; set; }
	public Printed_Medical_Record_Request__c currentRecord { get; set; }
	public Id logoContentVersionId { get; set; }
	public PrintedMedicalRecordController() {
		currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
	}
	public PageReference init() {
		if (currentRecordId != null) {
			Printed_Medical_Record_Request__c req = [SELECT Id, Patient_Account__c, Patient_Account__r.current_admission__c, Patient_Account__r.Name, Patient_Account__r.Previous_Admissions_Numeric__c, Patient_Account__r.Medical_Record_Number__c, Patient_Account__r.Current_Admission__r.Admit_Date__c, Patient_Account__r.Date_of_Birth__c FROM Printed_Medical_Record_Request__c WHERE Id = :currentRecordId WITH SECURITY_ENFORCED];
			currentRecord = req;
			String admissionIds = ApexPages.CurrentPage().getparameters().get('admissions');
			if (String.isBlank(admissionIds)) {
				admissionIds = JSON.serialize(new List<String>{ req.Patient_Account__r.current_admission__c });
			}
			// List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = new List<PrintedMedicalRecordBase>{
			//     PrintedMedicalRecordFactory.createHandler('Patient_Note__c', req.Patient_Account__c, req.Id, admissionIds),
			//     PrintedMedicalRecordFactory.createHandler('disco__Form__c', req.Patient_Account__c, req.Id, admissionIds)
			// };
			List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = MedRecordHierarchy.createMedicalRecordHandlers(req.Patient_Account__c, req.Id, admissionIds);
			List<TreeGridNode.PrintedIncludedObject> mrList = new List<TreeGridNode.PrintedIncludedObject>();
			for (PrintedMedicalRecordBase base : printedMedicalRecordHandlers) {
				mrList.addAll(base.getMedicalRecordAsHTMLs());
			}
			mrList.sort();
			List<List<TreeGridNode.PrintedIncludedObject>> vIncludedObjects = new List<List<TreeGridNode.PrintedIncludedObject>>();
			String currDocType = null;
			List<TreeGridNode.PrintedIncludedObject> currentTreeNodeList = null;

			for (Integer i = 0; i < mrList.size(); i++) {
				if (i == 0) {
					currDocType = mrList[0].Name;
					currentTreeNodeList = new List<TreeGridNode.PrintedIncludedObject>{ mrList[0] };
				} else {
					if (mrList[i].Name == currDocType) {
						currentTreeNodeList.add(mrList[i]);
						currDocType = mrList[i].Name;
					} else {
						vIncludedObjects.add(currentTreeNodeList);
						currentTreeNodeList = new List<TreeGridNode.PrintedIncludedObject>{ mrList[i] };
						currDocType = mrList[i].Name;
					}
				}
			}
			vIncludedObjects.add(currentTreeNodeList);

			includedObjects = vIncludedObjects;
			List<ContentVersion> logoContentVersions = [SELECT Id, VersionData, FileType FROM ContentVersion WHERE ContentDocument.Title = 'Riggs_Logo_Medical_Records' AND IsLatest = TRUE WITH SECURITY_ENFORCED];
			if (logoContentVersions.size() != 0) {
				logoContentVersionId = logoContentVersions[0].Id;
			}
		}
		return null;
	}
}
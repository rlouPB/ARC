public with sharing class PrintedLastDispensedMedsPDFController {
    public String accountId {get;set;}
    public List<Allergy__c> allergies { get; set; }
    public List<Prescription__c> prescriptions { get; set; }
    public Account patient {get; set;}
    public Id logoContentVersionId { get; set;}
    public PrintedLastDispensedMedsPDFController() {
        accountId = ApexPages.CurrentPage().getparameters().get('accountId');
        allergies = new List<Allergy__c>();
        prescriptions = new List<Prescription__c>();
    }
    public PageReference init() {
        if(null != accountId) {
            patient = [SELECT NAME, current_admission__c, Previous_Admissions_Numeric__c, Medical_Record_Number__c, Current_Admission__r.Admit_Date__c, Date_of_Birth__c FROM Account WHERE Id = :accountId];
            
            allergies = [SELECT Name__c, Adverse_Event_Code_Text__c, Reaction_Text__c, Severity_Code_Text__c, Comment__c, Onset_Date__c, End_Date__c FROM Allergy__c WHERE Account__c = :accountId ORDER BY Name__c];

            prescriptions = [SELECT Account__c, Medication_Filled_with__c, Medication_Format__c, Last_Dispensed__c, Dispensing_Comment__c FROM Prescription__c WHERE Status__c = 'Active' AND Account__c = :accountId ORDER BY Medication_Filled_with__c];

            List<ContentVersion> logoContentVersions = [SELECT Id, VersionData, FileType FROM ContentVersion WHERE ContentDocument.Title = 'Riggs_Logo_Medical_Records' AND IsLatest = true WITH SECURITY_ENFORCED];
            if(logoContentVersions.size() != 0) {
                logoContentVersionId = logoContentVersions[0].Id;
            }
        }
        return null;
    }
}
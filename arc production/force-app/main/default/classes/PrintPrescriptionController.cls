public with sharing class PrintPrescriptionController {
    Id prescriptionId;
    public Prescription__c currentRecord {get; set;}
    public String getHtmlText() {
        return null;
    }
    public PrintPrescriptionController(ApexPages.standardController stdcon) {
        prescriptionId = stdcon.getId();
    }
    public PageReference init() {
        Prescription__c req = [SELECT Id, Name, Status__c, CreatedDate, LastModifiedDate, Medication_Format__c, Start_Date__c, End_Date__c,
                                    Medication_Filled_with__c, Account__c, Account__r.name, Account__r.current_admission__c, 
                                    Account__r.Medical_Record_Number__c, Account__r.Current_Admission__r.Admit_Date__c, 
                                    Account__r.Date_of_Birth__c, Prescriber_Professional_Name__c FROM Prescription__c
                                    WHERE Id = :prescriptionId 
                                    WITH SECURITY_ENFORCED];
            currentRecord = req;
        return null;
    }
}
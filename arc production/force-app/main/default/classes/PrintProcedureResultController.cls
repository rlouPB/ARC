public with sharing class PrintProcedureResultController {
    Id procedureResultId;
    public Procedure_Result__c currentRecord {get; set;}
    public String getHtmlText() {
        return PrintedProcedureResultMedicalRecord.convert(procedureResultId);
    }
    public PrintProcedureResultController(ApexPages.standardController stdcon) {
        procedureResultId = stdcon.getId();
    }
    public PageReference init() {
        Procedure_Result__c req = [SELECT Id, Procedure_Order__r.Admission__r.Patient_Account__c, Procedure_Order__r.Admission__r.Patient_Account__r.current_admission__c, Procedure_Order__r.Procedure__c,
                                        Procedure_Order__r.Admission__r.Patient_Account__r.Name, Procedure_Order__r.Admission__r.Patient_Account__r.Previous_Admissions_Numeric__c,Procedure_Order__r.Admission__r.Patient_Account__r.Medical_Record_Number__c,
                                        Procedure_Order__r.Admission__r.Patient_Account__r.Current_Admission__r.Admit_Date__c,Procedure_Order__r.Admission__r.Patient_Account__r.Date_of_Birth__c,
                                        Status__c,Reviewed__c, Reviewed_Date_Time__c, Reviewed_By_Name__c, Procedure_Order__r.Finalized_By__c, Procedure_Order__r.Finalized_Date_Time__c, Testing_Facility_Name__c,
                                        Procedure_Order__r.Activation_Date__c, Procedure_Order__r.Order_Provider_Name__c,Received_Date__c,Result_Details__c
                                    FROM Procedure_Result__c WHERE Id = :procedureResultId 
                                    WITH SECURITY_ENFORCED];
            currentRecord = req;
        return null;
    }
}
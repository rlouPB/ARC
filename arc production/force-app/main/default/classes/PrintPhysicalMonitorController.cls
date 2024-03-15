public with sharing class PrintPhysicalMonitorController {
    Id physicalMonitorId;
    public Physical_Monitor__c currentRecord {get; set;}
    public String getHtmlText() {
        return PrintedPhysicalMonitorMedicalRecord.convertPhysicalMonitor(physicalMonitorId);
    }
    public PrintPhysicalMonitorController(ApexPages.standardController stdcon) {
        physicalMonitorId = stdcon.getId();
    }
    public PageReference init() {
        Physical_Monitor__c req = [SELECT Id, Account__c, Account__r.current_admission__c,
                                        Account__r.Name, Account__r.Previous_Admissions_Numeric__c,Account__r.Medical_Record_Number__c,
                                        Account__r.Current_Admission__r.Admit_Date__c,Account__r.Date_of_Birth__c,
                                        Performed_Date_Time__c, Finalized_Date_Time__c, Finalized_By_User__r.Professional_Name__c
                                    FROM Physical_Monitor__c WHERE Id = :physicalMonitorId 
                                    WITH SECURITY_ENFORCED];
            currentRecord = req;
        return null;
    }
}
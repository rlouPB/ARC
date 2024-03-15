public with sharing class PrintDraftDDRController {
    Id ddrId;
    Boolean isDraft=true;
    String purpose;
    public Discharge_Disposition__c currentRecord {get; set;}
    String snapshotHtml;
    public String getHtmlText() {
        Discharge_Disposition__c dischargeDispositionObj=[SELECT Id, Snapshot__c, Snapshot__r.Name, Snapshot__r.Html__c 
                                                          FROM Discharge_Disposition__c 
                                                          WHERE Id = :ddrId];
        return dischargeDispositionObj.Snapshot__r.Html__c;
    }
    public PrintDraftDDRController() {
        ddrId = ApexPages.CurrentPage().getparameters().get('Id');
        purpose = ApexPages.CurrentPage().getparameters().get('purpose');
        isDraft = Boolean.valueOf(ApexPages.CurrentPage().getparameters().get('isDraft'));
    }
   
    public PageReference init() {
        Discharge_Disposition__c req = [SELECT Id, Name, Status__c, CreatedDate, LastModifiedDate, Patient_Account__c, Patient_Account__r.name, Patient_Account__r.current_admission__c, 
                                    Patient_Account__r.Medical_Record_Number__c, Patient_Account__r.Current_Admission__r.Admit_Date__c, 
                                    Patient_Account__r.Date_of_Birth__c FROM Discharge_Disposition__c
                                    WHERE Id = :ddrId 
                                    WITH SECURITY_ENFORCED];
            currentRecord = req;
        DischargeDispositionSnapshot snapshot = new DischargeDispositionSnapshot(ddrId);
        snapshot.generateSnapshots(isDraft, purpose);
        return null;
    }
}
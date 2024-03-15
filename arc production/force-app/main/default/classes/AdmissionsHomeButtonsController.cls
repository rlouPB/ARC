public with sharing class AdmissionsHomeButtonsController {
    public AdmissionsHomeButtonsController() {
    }

    @AuraEnabled
    public static Admission__c getOrCreateAdmission(){
        Admission__c admission;
        List<Admission__c> admissions = [SELECT Id FROM Admission__c LIMIT 1];
        if (admissions.size() > 0) {
            admission = admissions.get(0);
        } else {
            Account new_account = new Account();
            new_account.Name = 'Test Account';
            insert new_account;
            Admission__c new_admission = new Admission__c();
            new_admission.Patient_Account__c = new_account.Id;
            insert new_admission;
            admission = new_admission;
        }
        return admission;
    }
    
}
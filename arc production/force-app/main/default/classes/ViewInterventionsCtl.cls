public with sharing class ViewInterventionsCtl {
    @AuraEnabled
    public static List<Intervention__c> getInterventions(String treatmentPlanId, Boolean showAll) {
        String query = 'SELECT Id, Case__c, CreatedBy.Name, Description__c, Discipline__c, End_Date__c, Patient_specific_Details__c,'+
        'Start_Date__c, Status__c FROM Intervention__c WHERE Case__c =: treatmentPlanId';
        if(!showAll){
            query += ' AND End_Date__c = null';
        }
        query += ' ORDER BY Discipline__c DESC';
        List<Intervention__c> interventionList = (List<Intervention__c>)Database.query(query);
        return interventionList;
    }
}
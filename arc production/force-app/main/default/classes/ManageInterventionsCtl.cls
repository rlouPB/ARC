public with sharing class ManageInterventionsCtl {

    public class DisciplineIntervention{
        @AuraEnabled public string dicipline;
        @AuraEnabled public string role;
        @AuraEnabled public string intervention;
        @AuraEnabled public boolean specify;
        public DisciplineIntervention(Discipline_Intervention__mdt dt){
            this.dicipline = dt.Discipline__c;
            this.role = dt.Assigned_Clinician_Role__c;
            this.intervention = dt.Intervention__c;
            this.specify = dt.Must_Specify__c;
        }
    }

    @AuraEnabled
    public static list<DisciplineIntervention> getDiciplinesRecords(string treatmentPlanId) {
        set<string> roles = new set<string>();
        list<DisciplineIntervention> results = new list<DisciplineIntervention>();
        Case[] treadmentPlans = [Select AccountId from Case where id=:treatmentPlanId limit 1];
        id accountId = treadmentPlans.isEmpty()? null : treadmentPlans[0]?.AccountId;

        for(Assigned_Clinician__c ac : [select Role__c FROM Assigned_Clinician__c where Patient_Account__c!=null and Patient_Account__c=:accountId  and User__c=:userinfo.getuserid() and  Role__c != null] ){
            roles.add(ac.Role__c);
        }
        for(Discipline_Intervention__mdt dt: [Select Discipline__c, Assigned_Clinician_Role__c,Intervention__c,Must_Specify__c from Discipline_Intervention__mdt where Assigned_Clinician_Role__c in :roles]){
            results.add( new DisciplineIntervention(dt) );
        }
        return results;
    }

    @AuraEnabled
    public static list<DisciplineIntervention> getDiciplinesRecordsForDiscipline(string treatmentPlanId, String discipline) {
        list<DisciplineIntervention> results = new list<DisciplineIntervention>();
        for(Discipline_Intervention__mdt dt: [Select Discipline__c, Assigned_Clinician_Role__c,Intervention__c,Must_Specify__c from Discipline_Intervention__mdt where Discipline__c = :discipline]){
            results.add( new DisciplineIntervention(dt) );
        }
        return results;
    }

    @AuraEnabled
    public static string discontinueIntervention(string interventionId) {
        for(Intervention__c inter : [Select Id, end_Date__c from Intervention__c where id=:interventionId]){
            try{
                update new Intervention__c(Id=inter.Id,End_Date__c=system.today());
            }catch(Exception ex){
                return ex.getMessage();
            }
        }
        return null;
    }

    @AuraEnabled
    public static string saveNewIntervention(string treatmentPlanId, string dicipline, string intervention, string patientSpecificDetail, date startDate) {
        try{
            insert new Intervention__c(
                Case__c=treatmentPlanId,
                Discipline__c = dicipline,
                description__c = intervention,
                Patient_specific_Details__c = patientSpecificDetail,
                Start_Date__c=startDate
            );
        }catch(Exception ex){
            return ex.getMessage();
        }
        return null;
    }
    
    @AuraEnabled
    public static boolean hasPermissions(string treatmentPlanId){
        return true;
        //ARC-1713 - Commented this functionality
        // for( Case treadmentPlan : [Select AccountId from Case where id=:treatmentPlanId limit 1] ){
        //     return [select count() FROM Assigned_Clinician__c where Patient_Account__c=:treadmentPlan.AccountId and User__c=:userinfo.getuserid()] > 0;
        // }
        // return false;
    }

    public static list<string> allowedDisiplines(string patientId){
        set<string> disciplines = new set<string>();
        set<string> roles = new set<string>();
        for(Assigned_Clinician__c ac : [select Role__c from Assigned_Clinician__c where Patient_Account__c=:patientId and User__c=:userinfo.getuserid() and Role__c != null]){
            roles.add(ac.Role__c);
        }
        if(roles.size() > 0){
            for(Discipline_Intervention__mdt dt: [Select Discipline__c, Assigned_Clinician_Role__c,Intervention__c,Must_Specify__c from Discipline_Intervention__mdt where Assigned_Clinician_Role__c in :roles]){
                disciplines.add( dt.Discipline__c );
            }
        }
        return new list<string>(disciplines);
    }

    @AuraEnabled
    public static List<Intervention__c> getInterventions(String treatmentPlanId, Boolean showAll, boolean showOnlyToAllowedDiciplines) {
        Case[] treadmentPlans = [Select AccountId from Case where id=:treatmentPlanId limit 1];

        Id patientId = treadmentPlans.isEmpty()? null : treadmentPlans[0].AccountId;

        list<string> assignedClinitianDisciplines = patientId != null? allowedDisiplines(patientId) : new string[]{};

        string[] wherePart = new string[]{
            //' Case__c != null ',
            //' Case__r.AccountId != null ',
            ' Case__c =:treatmentPlanId ',
            ' Case__r.AccountId =:patientId '
        };
        
        if(showAll != true){
            wherePart.add(' End_Date__c = null ');
        }

        if(showOnlyToAllowedDiciplines == true){
            wherePart.add(' Discipline__c in :assignedClinitianDisciplines ');
        }

        string query = 'SELECT Id, Case__c, CreatedDate, Description__c, Discipline__c, End_Date__c, Patient_specific_Details__c,Start_Date__c, Status__c FROM Intervention__c  WHERE ' + 
        string.join(wherePart,' AND ') + 
        ' ORDER BY Discipline__c DESC, Start_Date__c DESC ';

        // if(userinfo.getUserName().contains('danny.robles') ){
        //     system.assert(false, 'Query: ' + query );
        // }

        // String query = 'SELECT Id, Case__c, CreatedDate, Description__c, Discipline__c, End_Date__c, Patient_specific_Details__c,'+
        // 'Start_Date__c, Status__c FROM Intervention__c WHERE Case__c =: treatmentPlanId and Case__r.AccountId =:patientId AND Discipline__c in :assignedClinitianDisciplines ';
        // if(!showAll){
        //     query += ' AND End_Date__c = null';
        // }
        // query += ' ORDER BY Discipline__c DESC, Start_Date__c DESC';
        return (List<Intervention__c>)Database.query(query);
    }

    @AuraEnabled
    public static List<Intervention__c> getInterventionsForDiscipline(String treatmentPlanId, String discipline, Boolean showAll) {
        Case[] treadmentPlans = [Select AccountId from Case where id=:treatmentPlanId limit 1];

        Id patientId = treadmentPlans.isEmpty()? null : treadmentPlans[0].AccountId;

        string[] wherePart = new string[]{
            ' Case__c =:treatmentPlanId ',
            ' Case__r.AccountId =:patientId '
        };
        
        if(showAll != true){
            wherePart.add(' End_Date__c = null ');
        }

        if(null != discipline){
            wherePart.add(' Discipline__c = :discipline ');
        }

        string query = 'SELECT Id, Case__c, CreatedDate, Description__c, Discipline__c, End_Date__c, Patient_specific_Details__c,Start_Date__c, Status__c FROM Intervention__c  WHERE ' + 
        string.join(wherePart,' AND ') + 
        ' ORDER BY Discipline__c DESC, Start_Date__c DESC ';

        return (List<Intervention__c>)Database.query(query);
    }
}
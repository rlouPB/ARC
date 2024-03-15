public class NoteViewTreatmentPlanCtl {
    static String treatmentPlanQuery = 'SELECT Id,Goal__c, Admission__r.Medical_Care_Plan__c FROM CASE';

    @AuraEnabled
    public static NoteViewTreatmentPlanCtl.TreatmentPlan getTreatmentPlan(String treatmentPlanId)
    {
        return queryTreatmentPlan(' WHERE Id = \''+treatmentPlanId+'\'');
    }

    static NoteViewTreatmentPlanCtl.TreatmentPlan queryTreatmentPlan(String whereClause)
    {
        Case treatmentPlanObj = Database.query(treatmentPlanQuery + whereClause);
        String caseId = treatmentPlanObj.Id;

        NoteViewTreatmentPlanCtl.TreatmentPlan treatmentPlan = new NoteViewTreatmentPlanCtl.TreatmentPlan();
        treatmentPlan.treatmentPlanObj = treatmentPlanObj;
        treatmentPlan.goalList = new List<NoteViewTreatmentPlanCtl.Goal>();

        List<Goal__c> goalList = [SELECT Id, Label__c, Treatment_Plan__c FROM Goal__c WHERE Treatment_Plan__c =: caseId AND (Status__c = NULL OR Status__c = 'Continue goal')];
        List<Objective__c> objectiveList = [SELECT Id, Label__c, Goal__c FROM Objective__c WHERE Goal__c =: goalList AND (Status__c = NULL OR Status__c = 'Continue') ORDER BY Goal__c];
        Integer index = 0;
        Map<Id, List<Integer>> goalIdObjectiveMap = new Map<Id, List<Integer>>();
        for(Objective__c objectiveObj : objectiveList)
        {
            List<Integer> indexList = goalIdObjectiveMap.get(objectiveObj.Goal__c);
            if(indexList == null)
            {
                indexList = new List<Integer>();
            }
            indexList.add(index);
            goalIdObjectiveMap.put(objectiveObj.Goal__c, indexList);
            index++;
        }

        for(Goal__c  goalObj : goalList)
        {
            NoteViewTreatmentPlanCtl.Goal noteGoal = new NoteViewTreatmentPlanCtl.Goal();
            noteGoal.goalObj = goalObj;
            noteGoal.objectiveList = new List<Objective__c>();
            List<Integer> objectiveIndexList = goalIdObjectiveMap.get(goalObj.Id);
            if(objectiveIndexList != null && !objectiveIndexList.isEmpty())
            {
                for(Integer objectiveIndex : objectiveIndexList)
                {
                    Objective__c objectiveObj = objectiveList.get(objectiveIndex);
                    if(objectiveObj != null)
                    {
                        noteGoal.objectiveList.add(objectiveObj);
                    }
                }
            }
            treatmentPlan.goalList.add(noteGoal);
        }

        return treatmentPlan;
    }

    public class TreatmentPlan
    {
        @AuraEnabled
        public Case treatmentPlanObj;

        @AuraEnabled
        public List<NoteViewTreatmentPlanCtl.Goal> goalList;
    }

    public class Goal
    {
        @AuraEnabled
        public Goal__c goalObj;

        @AuraEnabled
        public List<Objective__c> objectiveList;
    }
}
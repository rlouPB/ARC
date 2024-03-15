public class AdmittedProgramDaysUtils {
    public static string getType(date targetDate, date startDate, date endDate){
        string resultType;
        if( targetDate == startDate ){
            resultType ='Starting';
        }else if(targetDate == endDate){
            resultType ='Ending';
        }else{
            resultType ='Full Day';
        }
        return resultType;
    }

    public static string getKey (Id rid, Date d){
        return rid+':'+d.year()+'-'+d.month()+'-'+d.day();
    }

    public static Admitted_Program_Day__c[] getFirstMatchedByDate(Admitted_Program_Day__c[] items){
        Admitted_Program_Day__c[] matchedResult = new Admitted_Program_Day__c[]{};
        if(items != null){
            for(Admitted_Program_Day__c apd : items){
                matchedResult.add(apd);
            }
        }
        return matchedResult;
    }
}
public class InsuranceCoveredDates 
{
    private List<Insurance_Covered_Date__c> datesToUpsert = new List<Insurance_Covered_Date__c>();
    private List<Insurance_Covered_Date__c> datesToDelete  = new List<Insurance_Covered_Date__c>();
    
	public InsuranceCoveredDates(List<Insurance_Review__c> reviews)
    {        
        Set<Id> reviewIds = new Map<Id, Insurance_Review__c>(reviews).keySet();
        
        List<Insurance_Review__c> queriedReviews = [
                SELECT Id, Authorization_Start_Date__c, Authorization_End_Date__c, Days_Covered__c, Last_Date_Covered__c, 
                        Insurance_Policy__r.Admission__r.Discharge_Date__c, Insurance_Policy__r.Admission__r.Patient_Contact__c,
                    (SELECT Id, Covered_Date__c, Status__c 
                        FROM Insurance_Covered_Dates__r 
                        ORDER BY Covered_Date__c ASC)
                FROM Insurance_Review__c 
                WHERE Id IN :reviewIds];
        calculateDates(queriedReviews);
    }
    
    
    private void calculateDates(List<Insurance_Review__c> reviews)
    {	
    	for(Insurance_Review__c review: reviews)
        {
            Date dischargeDate = review.Insurance_Policy__r.Admission__r.Discharge_Date__c;
            Date startDate = review.Authorization_Start_Date__c;
            Integer noOfDays = startDate.daysBetween(review.Last_Date_Covered__c)+1;
            
            Set<Date> remainingDateSet  = new Set<Date>();
            for(Integer i=0; i< noOfDays; i++ )
            {
                Date d = startDate.addDays(i);
                remainingDateSet.add(d);                
            }
            
            for(Insurance_Covered_Date__c ic: review.Insurance_Covered_Dates__r)
            {
                remainingDateSet.remove(ic.Covered_Date__c);
                
                // JN 220310 reversed order of if() and else if() ARC-1974
                if(ic.Covered_Date__c < review.Authorization_Start_Date__c || ic.Covered_Date__c > review.Last_Date_Covered__c)
                {
                    datesToDelete.add(ic);
                } else if(ic.Covered_Date__c >= dischargeDate)
                {
                    ic.Status__c = 'Patient Discharged';
                    datesToUpsert.add(ic);
                }
            }

            Id patientContact = review.Insurance_Policy__r.Admission__r.Patient_Contact__c;
            for(Date rDt: remainingDateSet)
            {
                Insurance_Covered_Date__c inCovDate = new Insurance_Covered_Date__c(
                	Covered_Date__c = rDt,
                    Insurance_Review__c = review.Id,
                    Patient_Contact__c = patientContact,
                    Status__c = 'Active' 
                );
                
                if(rDt >= dischargeDate)
                {
                    inCovDate.Status__c = 'Patient Discharged';
                }
                datesToUpsert.add(inCovDate);
            }
        }
     }

	public void fixDates()
    {  
        upsert datesToUpsert;
        delete datesToDelete;
	}
    	
	public static void updateCoveredDates(List<Insurance_Review__c> triggerNew, Map<Id, Insurance_Review__c> triggerOldMap)
    {
 		List<Insurance_Review__c> reviewsTofixDates = new List<Insurance_Review__c>();
		for(Insurance_Review__c ir: triggerNew)
        {	
			if(ir.Insurance_Review_Status__c == 'Authorized' && 
               ir.Authorization_Start_Date__c != null && 
               ir.Last_Date_Covered__c != null &&
               (triggerOldMap == null ||
                triggerOldMap.get(ir.Id).Authorization_Start_Date__c != ir.Authorization_Start_Date__c ||
                triggerOldMap.get(ir.Id).Last_Date_Covered__c != ir.Last_Date_Covered__c ||
                triggerOldMap.get(ir.Id).Insurance_Review_Status__c != ir.Insurance_Review_Status__c))
            {
                reviewsToFixDates.add(ir);
            }
        }
            
        InsuranceCoveredDates icdates = new InsuranceCoveredDates(reviewsToFixDates);
        icdates.fixDates();
    }
}
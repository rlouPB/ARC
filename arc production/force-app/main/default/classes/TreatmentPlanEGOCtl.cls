/**
Controller class for the TreatmentPlan_EGO
*/
public class TreatmentPlanEGOCtl {
	/**
	 * Save draft EGO.  Although Treatment Plan is passed as parameter, the treatmentPlan reference inside should ONLY be current treatment plan and
	 * will be linked to EGO.
	 *
	 * All Goals will have link to EGO when EGO is still in draft.
	 */
	@AuraEnabled
	public static String saveDraftEGO(TreatmentPlan tPlan) {
		// TreatmentPlan treatmentPlan = (TreatmentPlan)JSON.deserialize(tPlan, TreatmentPlan.class);
		// return tPlan;
		return TreatmentPlan.saveDraftEGO(tPlan);
	}

	@AuraEnabled
	public static String finalizeEGOToDraftTreatmentPlan(TreatmentPlan tPlan) {
		return TreatmentPlan.finalizeEGOToDraftTreatmentPlan(tPlan);
	}
	/**
	 * Get TreatmentPlan by EGO ID.
	 */
	@AuraEnabled
	public static TreatmentPlan getTreatmentPlanByEGOId(String egoId) {
		return TreatmentPlan.getTreatmentPlanByEGOId(egoId);
	}
	/**
	 * Get TreatmentPlan by ID.
	 */
	@AuraEnabled
	public static TreatmentPlan getTreatmentPlanById(Id treatmentPlanId) {
		return TreatmentPlan.getTreatmentPlan(treatmentPlanId);
	}
	/**
	 * Conduct EGO / EGO-R.  This will create a new EGO or load draft EGO.  This is reusing existing constructor that it will try to
	 * load everything from Active Treatment Plan, and then create an EGO and attach this EGO to this Draft Treatment Plan.
	 *
	 * @param treatmentPlanId The active treatment plan, as this must be conducted from the Active Treatment Plan page
	 * and this will not be executed when there is an existing Draft Treatment Plan already.
	 */
	@AuraEnabled
	public static TreatmentPlan conductEGO(Id treatmentPlanId) {
		/*
        TreatmentPlan draftTreatmentPlan=TreatmentPlan.getTreatmentPlan(treatmentPlanId);
        EGO__c ego;
        try{
            // Try searching for existing empty EGO that could be created for Draft Treatment Plan but the EGO got cancelled on UI.
            Id currentTreatmentPlanId=draftTreatmentPlan.currentTreatmentPlan.Id;
            ego=[SELECT Id,Overall_Goal__c,Current_Treatment_Plan__c,Program__c FROM EGO__c WHERE Current_Treatment_Plan__c=:currentTreatmentPlanId AND Draft_Treatment_Plan__c=NULL AND Status__c='Draft' limit 1];
        }catch(exception e){
            // No empty EGO to be reused, create new EGO.
            ego=new EGO__c(Current_Treatment_Plan__c=draftTreatmentPlan.currentTreatmentPlan.Id, Status__c='Draft');
            insert ego;
        }
        draftTreatmentPlan.ego=ego;
*/
		TreatmentPlan tPlan = TreatmentPlan.conductEGO(treatmentPlanId);
		return tPlan;
	}
}
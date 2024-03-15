public with sharing class FinalizedTreatmentPlanInvocable {
	@InvocableMethod(label='Retrieve Finalized Treatment Plan' category='Treatment Plan' description='Retrieve the finalized Treatment Plan, snapshot html included, related to a specfic patient')
	public static List<TreatmentPlanWrapper> retrieveFinalizedTreatmentPlan(List<TreatmentPlanWrapper> wrappers) {
		TreatmentPlanWrapper wrapper = wrappers[0];
		Id patientId = (Id) wrapper.patientId;

		List<Case> plans = [SELECT Id, Type, Status, AccountId, Patient_Account__c, CaseNumber, snapshot__r.html__c, snapshot__r.Mobile_Html__c FROM Case WHERE Patient_Account__c = :patientId AND status = 'Finalized' ORDER BY Finalized_Date_Time__c DESC];
		if (plans.size() > 0 && String.isNotBlank(plans[0].snapshot__r?.html__c)) {
			wrapper.treatmentPlanId = plans[0].Id;
			wrapper.snapshotHtml = plans[0].snapshot__r?.html__c;
			wrapper.snapshotMobile = plans[0].snapshot__r?.Mobile_Html__c;
		}
		return new List<TreatmentPlanWrapper>{ wrapper };
	}

	public class TreatmentPlanWrapper { //used for invocable method
		@InvocableVariable(label='Patient Account Id' required=true)
		public String patientId;

		@InvocableVariable(label='Treatment Plan Id' required=false)
		public String treatmentPlanId;

		@InvocableVariable(label='Finalized Treatment Plan Snapshot Html' description='' required=false)
		public String snapshotHtml;

		// 2022-08-06 DES Added for viewability on small screens
		// Related to ARC-1735: Modify Flow: 'Create New Form' for Treatment Plan lookup
		@InvocableVariable(label='Finalized Treatment Plan Mobile' description='' required=false)
		public String snapshotMobile;
	}
}
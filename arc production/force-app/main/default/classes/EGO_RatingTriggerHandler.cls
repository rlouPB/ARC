/**
*  @description EGO_RatingTriggerHandler for the EGO_Rating__c SObject. This class implements the ITrigger
*  Please check ITrigger and TriggerFactory to understand the order execution and methods used
*/
public without sharing class EGO_RatingTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	*/
    private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
    
    private Map<Id, Admission__c> admissionsMap;
    private Map<Id, Ego__c> egosMap;
    private Map<String, Id> groupIdsByName;

	/*******************************************************************************************************
	* @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore() {}

	/*******************************************************************************************************
	* @description This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter() {
        If (Trigger.isInsert)
		{
			Set<Id> egoIds = new Set<Id>();
			for (EGO_Rating__c egoRating: (List<EGO_Rating__c>)Trigger.new)
			{
				egoIds.add(egoRating.EGO__c);
			}
			List<EGO__c> egos = [
				SELECT Admission__c
				FROM EGO__c
				WHERE Id IN :egoIds
			];

			Set<Id> relatedAdmissions = new Set<Id>();
			for (EGO__c ego: egos)
			{
				relatedAdmissions.add(ego.Admission__c);
			}

			admissionsMap = new Map<Id, Admission__c>([
				SELECT Id, Stage__c, Chart_Closed__c,
					(SELECT Id 
						FROM EGOs__r)
				FROM Admission__c
				WHERE Id IN :relatedAdmissions
			]);

			Set<Id> relatedEGOs = new Set<Id>();
			for (Admission__c admission: admissionsMap.values())
			{
				for (Ego__c ego: admission.EGOs__r)
				{
					relatedEGOs.add(ego.Id);
				}
			}

			egosMap = new Map<Id, Ego__c>([
				SELECT Id, Admission__c
				// ,
				// (SELECT Id FROM Ego_Ratings__r)
				FROM EGO__c
				WHERE Id IN :relatedEGOs
			]);

			List<Group> allGroups = [
				SELECT Name
				FROM Group
			];
			groupIdsByName = new Map<String, Id>();
			for (Group currentGroup: allGroups)
			{
				groupIdsByName.put(currentGroup.Name, currentGroup.Id);
			}
		}
    }

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be deleted during a BEFORE
	* trigger.
	*/
	public void beforeDelete(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record inserted during an AFTER
	* trigger. Always put field validation in the 'After' methods in case another trigger
	* has modified any values. The record is 'read only' by this point.
	*/
	public void afterInsert(SObject so) {
        EGO_Rating__c egoRating = (EGO_Rating__c)so;
		EGO__c ego = egosMap.get(egoRating.EGO__c);
		if (ego == null) {ego = new EGO__c();}
        Admission__c admission = admissionsMap.get(ego.Admission__c);

        List<Id> groupsToShare = new List<Id>{groupIdsByName.get('Admissions')};
        List<String> stagesToShareWithClinical = new List<String>{
            'Consultation Pending',
            'Admitted'
        };
        if (admission != null && admission.Stage__c != null && (stagesToShareWithClinical.contains(admission.Stage__c) || ('Discharged' == admission.Stage__c && false == admission.Chart_Closed__c)))
        {
            groupsToShare.add(groupIdsByName.get('Clinical'));
        }

        String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{egoRating.Id}, groupsToShare, 'Edit');
        // System.debug('CaseTriggerHandler afterInsert shareResult: ' + shareResult);
    }

	/*******************************************************************************************************
	* @description This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record deleted during an AFTER
	* trigger.
	*/
	public void afterDelete(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called once all records have been processed by the trigger. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void andFinally() {
		if(alertsToBePublished.size() > 0) {
			EventBus.publish(alertsToBePublished);
		}
	}
}
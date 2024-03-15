/**
*  @description EGOTriggerHandler for the EGO__c SObject. This class implements the ITrigger
*  Please check ITrigger and TriggerFactory to understand the order execution and methods used
*/
public without sharing class EGOTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	*/
    private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
    
	private Map<Id, Admission__c> admissionsMap;
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
        If (Trigger.isInsert || Trigger.isUpdate)
		{
			Set<Id> relatedAdmissions = new Set<Id>();
			for (EGO__c ego: (List<EGO__c>)Trigger.new)
			{
				relatedAdmissions.add(ego.Admission__c);
			}

			admissionsMap = new Map<Id, Admission__c>([
				SELECT Stage__c, Chart_Closed__c
				FROM Admission__c
				WHERE Id IN :relatedAdmissions
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
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.s
	*/
	public void beforeInsert(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {
        EGO__c ego = (EGO__c)so;
        EGO__c OldEgo = (EGO__c)oldSo;

        System.debug('ego.Status__c : ' + ego.Status__c);
		System.debug('OldEgo.Status__c : ' + OldEgo.Status__c);
		System.debug('OldEgo.SDoc_Junction__c : ' + OldEgo.SDoc_Junction__c);
        ego = ego.Status__c == 'Finalized' && OldEgo.Status__c != 'Finalized' && OldEgo.SDoc_Junction__c == null ? createSdDocJunction(ego) : ego;

    }

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
        EGO__c ego = (EGO__c)so;
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

        String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{ego.Id}, groupsToShare, 'Edit');
        System.debug('CaseTriggerHandler afterInsert shareResult: ' + shareResult);
    }

	/*******************************************************************************************************
	* @description This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
    public void afterUpdate(SObject oldSo, SObject so) {
        ego__c ego = (ego__c) so;
        ego__c oldEgo = (ego__c) oldSo;
        
        List<Id> groupsToShare = new List<Id>{groupIdsByName.get('Clinical')};
            String result = ego.Status__c == 'Finalized' && oldEgo.Status__c != 'Finalized' ? SharingRecord_Utils.deleteSharingRecords(new list<Id>{ego.id}, groupsToShare) : '';
        	result = result == 'Success' ? SharingRecord_Utils.createSharingRecords(new List<Id>{ego.Id}, groupsToShare, 'Read') : '';
    }

	/*******************************************************************************************************
	* @description This method is called iteratively for each record deleted during an AFTER
	* trigger.
	*/
	public void afterDelete(SObject so) {}
    
    @testVisible
    private static ego__c createSdDocJunction(EGO__c ego){
        SDoc_Junction__c sDocJunction = new SDoc_Junction__c(ego__c = ego.Id);
        insert sDocJunction;
        ego.SDoc_Junction__c = sDocJunction.Id;
		System.debug('just created SDocJuntion and set it on EGO.');
        return ego;
    }
    
    
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
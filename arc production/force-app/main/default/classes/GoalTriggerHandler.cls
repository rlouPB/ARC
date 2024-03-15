/**
 *  @description GoalTriggerHandler for the Goal__c SObject. This class implements the ITrigger
 *  Please check ITrigger and TriggerFactory to understand the order execution and methods used
 */
public without sharing class GoalTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	 */
	private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
	private Map<String, Id> groupIdsByName;

	/*******************************************************************************************************
	 * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
	}

	/*******************************************************************************************************
	 * @description This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		if (Trigger.isInsert) {
			List<Group> allGroups = [SELECT Name, Id FROM Group];
			groupIdsByName = new Map<String, Id>();
			for (Group currentGroup : allGroups) {
				groupIdsByName.put(currentGroup.Name, currentGroup.Id);
			}
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public void afterInsert(SObject so) {
		Goal__c goal = (Goal__c) so;
		List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Admissions') };
		groupsToShare.add(groupIdsByName.get('Clinical'));
		String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{ goal.Id }, groupsToShare, 'Edit');
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
		if (alertsToBePublished.size() > 0) {
			EventBus.publish(alertsToBePublished);
		}
	}
}
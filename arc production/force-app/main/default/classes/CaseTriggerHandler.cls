/**
 *  @description CaseTriggerHandler for the Case SObject. This class implements the ITrigger
 *  Please check ITrigger and TriggerFactory to understand the order execution and methods used
 */
public without sharing class CaseTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	 */
	private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();

	private Map<Id, Account> accountsMap;
	private Map<String, Id> groupIdsByName;
	private List<Case> casesToDeleteOpenItemsFor = new List<Case>();

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
		if (Trigger.isInsert || Trigger.isUpdate) {
			Set<Id> accountIds = new Set<Id>();
			for (Case currentCase : (List<Case>) Trigger.new) {
				accountIds.add(currentCase.AccountId);
			}

			accountsMap = new Map<Id, Account>([SELECT Id, Current_Admission__r.Stage__c FROM Account WHERE Id IN :accountIds]);

			List<Group> allGroups = [SELECT Name FROM Group];
			groupIdsByName = new Map<String, Id>();
			for (Group currentGroup : allGroups) {
				groupIdsByName.put(currentGroup.Name, currentGroup.Id);
			}
		}

		if (!Trigger.isDelete) {
			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);
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
		Case currentCase = (Case) so;
		Case oldCase = (Case) oldSo;

		currentCase = currentCase.Status == 'Finalized' && oldCase.Status != 'Finalized' && oldCase.SDoc_Junction__c == null ? createSdDocJunction(currentCase) : currentCase;
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
		Case currentCase = (Case) so;
		Account account = accountsMap.get(currentCase.AccountId);

		List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Admissions') };
		List<String> stagesToShareWithClinical = new List<String>{ 'Consultation Pending', 'Admitted' };
		if (account != null && account.Current_Admission__c != null && account.Current_Admission__r.Stage__c != null && stagesToShareWithClinical.contains(account.Current_Admission__r.Stage__c)) {
			groupsToShare.add(groupIdsByName.get('Clinical'));
		}

		String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{ currentCase.Id }, groupsToShare, 'Edit');
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		Case currentCase = (Case) so;
		Case oldCase = (Case) oldSo;

		List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Clinical') };
		if (currentCase.Status.equals('Finalized') && currentCase.Status != oldCase.Status) {
			casesToDeleteOpenItemsFor.add(currentCase);
			String result = SharingRecord_Utils.deleteSharingRecords(new List<Id>{ currentCase.id }, groupsToShare);
			result = result == 'Success' ? SharingRecord_Utils.createSharingRecords(new List<Id>{ currentCase.Id }, groupsToShare, 'Read') : '';
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	private static Case createSdDocJunction(Case currentCase) {
		SDoc_Junction__c sDocJunction = new SDoc_Junction__c(Treatment_Plan__c = currentCase.Id);
		insert sDocJunction;
		currentCase.SDoc_Junction__c = sDocJunction.Id;
		return currentCase;
	}
	/*******************************************************************************************************
	 * @description This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
		if (alertsToBePublished.size() > 0) {
			EventBus.publish(alertsToBePublished);
		}

		if (!casesToDeleteOpenItemsFor.isEmpty()) {
			OutstandingItems.deleteRelatedTags(casesToDeleteOpenItemsFor);
		}
	}
}
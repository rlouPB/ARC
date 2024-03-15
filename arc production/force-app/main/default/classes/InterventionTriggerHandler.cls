/**
*  @description InterventionTriggerHandler for the Intervention__c SObject. This class implements the ITrigger
*  Please check ITrigger and TriggerFactory to understand the order execution and methods used
*/
public without sharing class InterventionTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	*/
    private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
    
    private Map<Id, Account> accountsMap;
	private Map<Id, Case> casesMap;
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
			Set<Id> caseIds = new Set<Id>();
			for (Intervention__c intervention: (List<Intervention__c>)Trigger.new)
			{
				caseIds.add(intervention.Case__c);
			}
			List<Case> cases = [
				SELECT AccountId
				FROM Case
				WHERE Id IN : caseIds
			];

			Set<Id> accountIds = new Set<Id>();
			for (Case currentCase: cases)
			{
				accountIds.add(currentCase.AccountId);
			}

			accountsMap = new Map<Id, Account>([
				SELECT Id, Current_Admission__r.Stage__c, Current_Admission__r.Chart_Closed__c, 
				(SELECT Id FROM Cases)
				FROM Account
				WHERE Id IN: accountIds
			]);

			Set<Id> relatedCases = new Set<Id>();
			for (Account acc: accountsMap.values())
			{
				for (Case currentCase: acc.Cases)
				{
					relatedCases.add(currentCase.Id);
				}
			}

			casesMap = new Map<Id, Case>([
				SELECT AccountId,
				(SELECT Id FROM Interventions__r)
				FROM Case
				WHERE Id IN :relatedCases
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
        Intervention__c intervention = (Intervention__c)so;
        Case currentCase = casesMap.get(intervention.Case__c);
        Account account = accountsMap.get(currentCase.AccountId);

        List<Id> groupsToShare = new List<Id>{groupIdsByName.get('Admissions')};
        List<String> stagesToShareWithClinical = new List<String>{
            'Consultation Pending',
            'Admitted'
        };
        if (account != null && account.Current_Admission__c != null && account.Current_Admission__r.Stage__c != null && 
				(stagesToShareWithClinical.contains(account.Current_Admission__r.Stage__c) || ('Discharged' == account.Current_Admission__r.Stage__c && account.Current_Admission__r.Chart_Closed__c)))
        {
            groupsToShare.add(groupIdsByName.get('Clinical'));
        }

        String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{intervention.Id}, groupsToShare, 'Edit');
        System.debug('CaseTriggerHandler afterInsert shareResult: ' + shareResult);
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
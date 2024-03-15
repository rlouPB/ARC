/**
 * @author ben.efigenio@synapticap.com
 * @date 08/19/2010
 *
 * @group Access_Pass__c
 *
 * @description Access_PassTriggerHandler for the Access_Pass__c SObject. This class implements the ITrigger
 *  Please check ITrigger and TriggerFactory to understand the order execution and methods used
 */
public without sharing class Access_PassTriggerHandler implements ITrigger {
	/* @description List of Alerts to be published in the andFinally method
	 */
	private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();

	// private Map<Id, List<Goal__c>> goalMap = new Map<Id, List<Goal__c>>();
	// private Map<Id, List<Objective__c>> objectiveMap = new Map<Id, List<Objective__c>>();

	private Map<Id, Account> accountsMap;
	private Map<Id, Case> casesMap;
	private Map<Id, Admission__c> admissionsMap;
	private Map<Id, Goal__c> goalsMap;
	private Map<Id, Ego__c> egosMap;
	private Set<Id> relatedSnapshotIds;

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
			Set<Id> relatedAccountIds = new Set<Id>();
			for (Access_Pass__c accessPass : (List<Access_Pass__c>) Trigger.new) {
				relatedAccountIds.add(accessPass.Patient__c);
			}

			accountsMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Admission_Files__r), (SELECT Id FROM Cases), (SELECT Id FROM Patient_Notes__r) FROM Account WHERE Id IN :relatedAccountIds]);

			Set<Id> relatedCases = new Set<Id>();
			Set<Id> relatedPatientNotes = new Set<Id>();
			Set<Id> relatedAdmissions = new Set<Id>();
			for (Account acc : accountsMap.values()) {
				for (Case currentCase : acc.Cases) {
					relatedCases.add(currentCase.Id);
				}
				for (Admission__c admission : acc.Admission_Files__r) {
					relatedAdmissions.add(admission.Id);
				}
				// Get related Patient Notes Ids for chosen Patient
				for (Patient_Note__c pNote : acc.Patient_Notes__r) {
					relatedPatientNotes.add(pNote.Id);
				}
			}

			casesMap = new Map<Id, Case>([SELECT Id, (SELECT Id FROM Interventions__r), (SELECT Id FROM Goals_Draft_Treatment_Plan__r) FROM Case WHERE Id IN :relatedCases]);

			admissionsMap = new Map<Id, Admission__c>([SELECT Id, (SELECT Id FROM EGOs__r), (SELECT Id FROM Diagnoses__r) FROM Admission__c WHERE Id IN :relatedAdmissions]);

			Set<Id> relatedGoals = new Set<Id>();
			for (Case currentCase : casesMap.values()) {
				for (Goal__c goal : currentCase.Goals_Draft_Treatment_Plan__r) {
					relatedGoals.add(goal.Id);
				}
			}

			goalsMap = new Map<Id, Goal__c>([SELECT Id, (SELECT Id FROM Objectives__r) FROM Goal__c WHERE Id IN :relatedGoals]);

			Set<Id> relatedEGOs = new Set<Id>();
			for (Admission__c admission : admissionsMap.values()) {
				for (Ego__c ego : admission.EGOs__r) {
					relatedEGOs.add(ego.Id);
				}
			}

			relatedSnapshotIds = new Set<Id>();
			for (Snapshot__C snapshot : [SELECT Id FROM Snapshot__c WHERE Treatment_Plan__c IN :relatedCases OR EGO__c IN :relatedEGOs OR Patient_Note__c IN :relatedPatientNotes]) {
				relatedSnapshotIds.add(snapshot.Id);
			}

			egosMap = new Map<Id, Ego__c>([SELECT Id, (SELECT Id FROM Ego_Ratings__r) FROM EGO__c WHERE Id IN :relatedEGOs]);
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
		Access_Pass__c accessPass = (Access_Pass__c) so;
		Account patient = accountsMap.get(accessPass.Patient__c);

		List<Id> allRecordIds = new List<Id>{ patient.Id };

		// Get related Admission Files and related objects Ids for the chosen Patient
		for (Admission__c admission : patient.Admission_Files__r) {
			for (EGO__c ego : admission.EGOs__r) {
				allRecordIds.add(ego.Id);
				for (EGO_Rating__c egoRating : ego.EGO_Ratings__r) {
					allRecordIds.add(egoRating.Id);
				}
			}
			for (Diagnosis__c diagnosis : admission.Diagnoses__r) {
				allRecordIds.add(diagnosis.Id);
			}
		}

		allRecordIds.addAll(relatedSnapshotIds);
		// Get related Cases and related objects Ids for chosen Patient
		for (Case currentCase : patient.Cases) {
			allRecordIds.add(currentCase.Id);
			for (Intervention__c intervention : currentCase.Interventions__r) {
				allRecordIds.add(intervention.Id);
			}
			for (Goal__c goal : currentCase.Goals_Draft_Treatment_Plan__r) {
				allRecordIds.add(goal.Id);
				for (Objective__c objective : goal.Objectives__r) {
					allRecordIds.add(objective.Id);
				}
			}
		}

		// Get related Patient Notes Ids for chosen Patient
		for (Patient_Note__c pNote : patient.Patient_Notes__r) {
			allRecordIds.add(pNote.Id);
		}

		String result = SharingRecord_Utils.createSharingRecords(allRecordIds, new List<String>{ accessPass.Requesting_User__c }, 'Read');
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
// NOTE: the test coverage for this is in the Admission_TriggerHandlerTest class.
public without sharing class PatientRecordSharingBatch implements Database.Batchable<sObject> {

    Map<String, Id> groupIdsByName;

    public PatientRecordSharingBatch() {
        List<Group> allGroups = [SELECT Name FROM Group];
		groupIdsByName = new Map<String, Id>();
		for (Group currentGroup : allGroups) {
			groupIdsByName.put(currentGroup.Name, currentGroup.Id);
		}
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Sharing_Clinical__c, Sharing_NPSP__c FROM Account WHERE Sharing_Clinical__c IN (\'Share\',\'Remove\') OR Sharing_NPSP__c IN (\'Share\',\'Remove\')';
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<Account> scope){
        Account[] patients = scope;
        System.debug('patients : ' + patients);
        List<Account> clinicalPatientsToShareRecords = new List<Account>();
        List<Account> clinicalPatientsToRemoveSharingRecords = new List<Account>();
        List<Account> npspPatientsToShareRecords = new List<Account>();
        List<Account> npspPatientsToRemoveSharingRecords = new List<Account>();
        
        for(Account a : patients) {
            if('Share'.equals(a.Sharing_Clinical__c)) {
                clinicalPatientsToShareRecords.add(a);
            } else if('Remove'.equals(a.Sharing_Clinical__c)) {
                clinicalPatientsToRemoveSharingRecords.add(a);
            } 

            if('Share'.equals(a.Sharing_NPSP__c)) {
                npspPatientsToShareRecords.add(a);
            } else if('Remove'.equals(a.Sharing_NPSP__c)) {
                npspPatientsToRemoveSharingRecords.add(a);
            } 
        }

        if(!clinicalPatientsToShareRecords.isEmpty()){
            runSharingUpdates(clinicalPatientsToShareRecords, true);
        }

        if(!clinicalPatientsToRemoveSharingRecords.isEmpty()){
            runSharingUpdates(clinicalPatientsToRemoveSharingRecords, false);
        }

        if(!npspPatientsToShareRecords.isEmpty()){
            runSharingUpdatesNPSP(npspPatientsToShareRecords, true);
        }

        if(!npspPatientsToRemoveSharingRecords.isEmpty()){
            runSharingUpdatesNPSP(npspPatientsToRemoveSharingRecords, false);
        }

    }
  
    public void finish(Database.BatchableContext BC){
    }

    public void runSharingUpdates(List<Account> patients, Boolean isCreate) {
		Map<Id, Account> accountsMap;
		Map<Id, Case> casesMap;
		Map<Id, Admission__c> admissionsMap;
		Map<Id, Goal__c> goalsMap;
		Map<Id, Ego__c> egosMap;
		
		Set<Id> accountIds = new Set<Id>();
		for (Account a : patients) {
			accountIds.add(a.Id);
		}

		accountsMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Admission_Files__r), (SELECT Id FROM Cases), (SELECT Id, Status__c FROM Patient_Notes__r) FROM Account WHERE Id IN :accountIds]);
        System.debug('accountsMap : ' + accountsMap);

		Set<Id> relatedCases = new Set<Id>();
		Set<Id> relatedAdmissions = new Set<Id>();
		for (Account acc : accountsMap.values()) {
			for (Case currentCase : acc.Cases) {
				relatedCases.add(currentCase.Id);
			}
			for (Admission__c admission : acc.Admission_Files__r) {
				relatedAdmissions.add(admission.Id);
			}
		}

		casesMap = new Map<Id, Case>([SELECT Id, (SELECT Id FROM Interventions__r), (SELECT Id FROM Goals_Draft_Treatment_Plan__r) FROM Case WHERE Id IN :relatedCases]);
        System.debug('casesMap : ' + casesMap);

		admissionsMap = new Map<Id, Admission__c>([SELECT Id, (SELECT Id FROM EGOs__r), (SELECT Id FROM Diagnoses__r) FROM Admission__c WHERE Id IN :relatedAdmissions]);
        System.debug('admissionsMap : ' + admissionsMap);

		Set<Id> relatedGoals = new Set<Id>();
		for (Case currentCase : casesMap.values()) {
			for (Goal__c goal : currentCase.Goals_Draft_Treatment_Plan__r) {
				relatedGoals.add(goal.Id);
			}
		}

		goalsMap = new Map<Id, Goal__c>([SELECT Id, (SELECT Id FROM Objectives__r) FROM Goal__c WHERE Id IN :relatedGoals]);
        System.debug('goalsMap : ' + goalsMap);

		Set<Id> relatedEGOs = new Set<Id>();
		for (Admission__c admission : admissionsMap.values()) {
			for (Ego__c ego : admission.EGOs__r) {
				relatedEGOs.add(ego.Id);
			}
		}

		egosMap = new Map<Id, Ego__c>([SELECT Id, (SELECT Id FROM Ego_Ratings__r) FROM EGO__c WHERE Id IN :relatedEGOs]);
        System.debug('egosMap : ' + egosMap);

		for (Account a : patients) {
			Account patient = accountsMap.get(a.Id);

			List<Id> allRecordIds = new List<Id>{ patient.Id };

			// Get related Admission Files and related objects Ids for the chosen Patient
			for (Admission__c admission : patient.Admission_Files__r) {
				for (EGO__c ego : admission.EGOs__r) {
					allRecordIds.add(ego.Id);
					for (EGO_Rating__c egoRating : ego.EGO_Ratings__r) {
						allRecordIds.add(egoRating.Id);
					}
				}
			}

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
                if('Finalized'.equals(pNote.Status__c))
				    allRecordIds.add(pNote.Id);
			}

			if (isCreate) {
                System.debug('allRecordIds : ' + allRecordIds);
				List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Admissions') };
				String result = SharingRecord_Utils.createSharingRecords(allRecordIds, groupsToShare, 'Edit');
                System.debug('sharing result for Admissions : ' + result);

                groupsToShare = new List<Id>{ groupIdsByName.get('Clinical') };
				result = SharingRecord_Utils.createSharingRecords(allRecordIds, groupsToShare, 'Edit');
                System.debug('sharing result for Clinical : ' + result);

                // Share any related Snapshot records
                List<Snapshot__c> snapshots = [SELECT Id from Snapshot__c WHERE EGO__c IN :allRecordIds OR Patient_Note__c IN :allRecordIds OR Treatment_Plan__c IN :allRecordIds];
                List<Id> snapshotIds = new List<Id>();
                for(Snapshot__c s : snapshots) {
                    snapshotIds.add(s.Id);
                }
                result = SharingRecord_Utils.createSharingRecords(snapshotIds, groupsToShare, 'Read');
                System.debug('sharing result for snapshots for Clinical : ' + result);
                if('Success'.equals(result)) {
                    a.Sharing_Clinical__c = 'Completed';
                }
			} else {
                List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Clinical') };
                for (Snapshot__C snapshot : [SELECT Id FROM Snapshot__c WHERE Treatment_Plan__c IN :allRecordIds OR EGO__c IN :allRecordIds OR Patient_Note__c IN :allRecordIds]) {
                    allRecordIds.add(snapshot.Id);
                }
                String result = SharingRecord_Utils.deleteSharingRecords(allRecordIds, groupsToShare);
                System.debug('delete sharing result for Clinical : ' + result);
                if('Success'.equals(result)) {
                    a.Sharing_Clinical__c = 'Completed';
                }
			}
		}
        update patients;
	}

	public void runSharingUpdatesNPSP(List<Account> patients, Boolean isCreate) {
		Map<Id, Account> accountsMap;
		Map<Id, Admission__c> admissionsMap;
		Map<Id, Related_Contact__c> relatedContactsMap;

		Set<Id> accountIds = new Set<Id>();
		for (Account a : patients) {
			accountIds.add(a.Id);
		}

		accountsMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Admission_Files__r), (SELECT Id FROM Related_Contacts__r) FROM Account WHERE Id IN :accountIds]);

		Set<Id> relatedContacts = new Set<Id>();
		Set<Id> relatedAdmissions = new Set<Id>();
		for (Account acc : accountsMap.values()) {
			for (Related_Contact__c relatedContact : acc.Related_Contacts__r) {
				relatedContacts.add(relatedContact.Id);
			}
			for (Admission__c admission : acc.Admission_Files__r) {
				relatedAdmissions.add(admission.Id);
			}
		}

		relatedContactsMap = new Map<Id, Related_Contact__c>([SELECT Id, Type__c FROM Related_Contact__c WHERE Id IN :relatedContacts]);

		admissionsMap = new Map<Id, Admission__c>([SELECT Id FROM Admission__c WHERE Id IN :relatedAdmissions]);

		for (Account a : patients) {
			Account patient = accountsMap.get(a.Id);

			List<Id> allRecordIds = new List<Id>{ patient.Id };
			List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Communications and Marketing'), groupIdsByName.get('Fundraising and Development') };
			
			if (isCreate) {
				if (!relatedContactsMap.isEmpty()) {
					for (Related_Contact__c relatedContact : relatedContactsMap.values()) {
						if ('Professional;Patient;Personal'.contains(relatedContact.Type__c)) {
							allRecordIds.add(relatedContact.Id);
						}
					}
				}
				String result = SharingRecord_Utils.createSharingRecords(allRecordIds, groupsToShare, 'Edit');
                if('Success'.equals(result)) {
                    a.Sharing_NPSP__c = 'Completed';
                }
			} else {
				if (!relatedContactsMap.isEmpty()) {
					for (Related_Contact__c relatedContact : relatedContactsMap.values()) {
						if ('Patient;Personal'.contains(relatedContact.Type__c)) {
							allRecordIds.add(relatedContact.Id);
						}
					}
				}
				String result = SharingRecord_Utils.deleteSharingRecords(allRecordIds, groupsToShare);
                if('Success'.equals(result)) {
                    a.Sharing_NPSP__c = 'Completed';
                }
			}
		}
        update patients;
	}
}
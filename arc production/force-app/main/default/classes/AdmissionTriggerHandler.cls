public without sharing class AdmissionTriggerHandler implements ITrigger {
	public static PsychHelper psychHelper = new PsychHelper();
	public List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
	String triggerObject = String.valueOf((Trigger.new != null) ? Trigger.new.getSObjectType() : Trigger.old.getSObjectType());
	List<String> stagesToRunSharingCreate = new List<String>{ 'Consultation Pending', 'Admitted' };
	List<String> stagesToRunSharingRemove = new List<String>{ 'Declined by Riggs', 'Withdrawn', 'Inactive' };
	List<String> stagesToRunSharingCreateNPSP = new List<String>{ 'Open Inquiry', 'Discharged', 'Withdrawn', 'Declined' };
	List<String> stagesToRunSharingRemoveNPSP = new List<String>{ 'Active Inquiry', 'Waitlist', 'Consultation Pending', 'Admitted' };
	Map<Id, List<Case>> activeDraftTreatmentPlansByAdmission = new Map<Id, List<Case>>();
	List<Case> treatmentPlansToInactivate = new List<Case>();

	static List<Account> accountsToShare = new List<Account>();
	static List<Account> accountsToRemoveSharing = new List<Account>();
	static List<Account> accountsToShareNPSP = new List<Account>();
	static List<Account> accountsToRemoveSharingNPSP = new List<Account>();

	@TestVisible
	Map<String, Set<Id>> newStage2AdmIdsMap = new Map<String, Set<Id>>();

	static Map<Id, Patient_Note__c[]> dispensingOrdersByAccountId;

	// Keep track of Admission records to clean up draft or future records on chart closed.
	Map<Id, Admission__c> chartClosedAdmissionsByIdMap = new Map<Id, Admission__c>();

	/*******************************************************************************************************
	 * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		if (!Trigger.isDelete) {
			WaitlistReorder.addToWaitlist((List<Admission__c>) Trigger.new, (Map<Id, Admission__c>) Trigger.oldMap);

			Set<Id> accountIds = new Set<Id>();
			for (Admission__c admission : (List<Admission__c>) Trigger.new) {
				if (null != Trigger.oldMap) {
					Admission__c oldAdmission = ((Map<Id, Admission__c>) Trigger.oldMap).get(admission.Id);
					if (null != oldAdmission && admission.Dispensing_Status__c != oldAdmission.Dispensing_Status__c && ('MSA'.equals(admission.Dispensing_Status__c) || 'Away'.equals(admission.Dispensing_Status__c))) {
						accountIds.add(admission.Patient_Account__c);
					}
				}
			}

			if (!accountIds.isEmpty()) {
				dispensingOrdersByAccountId = DispensingService.getOrdersByAccountId(accountIds);
			}
		}

		if (Trigger.IsBefore && Trigger.IsUpdate) {
			ChangeAdmittedProgramHelper.validateDischargeDatesOnChilds(Trigger.New, Trigger.oldMap);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		if (!Trigger.isDelete) {
			WaitlistReorder.reorderWaitlist((List<Admission__c>) Trigger.new, (Map<Id, Admission__c>) Trigger.oldMap);
		}

		Set<Id> admissionIds = new Set<Id>();
		if (Trigger.new != null) {
			for (Admission__c admission : (List<Admission__c>) Trigger.new) {
				admissionIds.add(admission.Id);
			}
		}

		List<Case> treatmentPlansActiveDraft = [SELECT Id, Admission__c, Status FROM Case WHERE Admission__c IN :admissionIds AND Status IN ('Active', 'Draft')];
		for (Case tp : treatmentPlansActiveDraft) {
			if (activeDraftTreatmentPlansByAdmission.containsKey(tp.Admission__c)) {
				List<Case> treatmentPlans = activeDraftTreatmentPlansByAdmission.get(tp.Admission__c);
				treatmentPlans.add(tp);
				activeDraftTreatmentPlansByAdmission.put(tp.Admission__c, treatmentPlans);
			} else {
				List<Case> treatmentPlans = new List<Case>();
				treatmentPlans.add(tp);
				activeDraftTreatmentPlansByAdmission.put(tp.Admission__c, treatmentPlans);
			}
		}

		if (Trigger.isUpdate) {
			//update Admitted Program end dates
			ChangeAdmittedProgramHelper.processDischarge(Trigger.New, Trigger.OldMap);
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
		Admission__c admission = (Admission__c) so;
		Admission__c oldAdmission = (Admission__c) oldSo;
		if ((admission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
			admission.Chart_Closed_DateTime__c = DateTime.now();
			chartClosedAdmissionsByIdMap.put(admission.Id, admission);

			// We will never be able to change the admission chart close in a batch fashion so allowing a SOQL in this method which is not a best practice.
			Patient_Note__c[] completedPatientNotes = [SELECT Id, Status__c FROM Patient_Note__c WHERE Admission__c = :admission.Id AND Status__c = 'Completed'];
			if(!completedPatientNotes.isEmpty()) {
				admission.addError('There is one or more completed patients notes for this admission. Please finalize or cancel them before setting the admission to chart closed.');
			}
		}

		if ('Away' != oldAdmission.Dispensing_Status__c && admission.Dispensing_Status__c != oldAdmission.Dispensing_Status__c && ('MSA'.equals(admission.Dispensing_Status__c) || 'Away'.equals(admission.Dispensing_Status__c))) {
			Patient_Note__c[] dispensingOrders = dispensingOrdersByAccountId.get(admission.Patient_Account__c);
			Boolean validationError = true;
			if (null != dispensingOrders) {
				for (Patient_Note__c pn : dispensingOrders) {
					if ('MSA'.equals(admission.Dispensing_Status__c) && 'Medication Self Administration (MSA) Order'.equals(pn.Type__c)) {
						validationError = false;
					} else if ('Away'.equals(admission.Dispensing_Status__c) && 'Away Medication Order'.equals(pn.Type__c)) {
						validationError = false;
					}
				}
			}
			if (validationError)
				admission.addError('You cannot update the Dispensing Status without a corresponding order finalized within the last 30 days.');
		}

		if (null == admission.Dispensing_Status__c) {
			admission.Dispensing_Status__c = 'Closet';
		}
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
		Admission__c admission = (Admission__c) so;
		AlertsFilter.execute(null, admission, this.alertsToBePublished, triggerObject, 'Insert');
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		Admission__c admission = (Admission__c) so;
		Admission__c oldAdmission = (Admission__c) oldSo;

		Set<Id> admittedAdmissionIds = new Set<Id>();
		if (('Discharged'.equals(admission.Stage__c) && admission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false) || (!'Discharged'.equals(admission.Stage__c) && (admission.Stage__c != oldAdmission.Stage__c))) {
			if (!newStage2AdmIdsMap.containsKey(admission.Stage__c)) {
				newStage2AdmIdsMap.put(admission.Stage__c, new Set<Id>());
			}

			newStage2AdmIdsMap.get(admission.Stage__c).add(admission.Id);

			if ('Admitted' == admission.Stage__c) {
				admittedAdmissionIds.add(admission.Id);
			}

			if (stagesToRunSharingCreate.contains(admission.Stage__c) || ('Discharged' == admission.Stage__c && false == admission.Chart_Closed__c)) {
				runSharingUpdates(new List<Admission__c>{ admission }, new Map<Id, Admission__c>{ oldAdmission.Id => oldAdmission }, true);
			} else if (stagesToRunSharingRemove.contains(admission.Stage__c) || (admission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
				runSharingUpdates(new List<Admission__c>{ admission }, new Map<Id, Admission__c>{ oldAdmission.Id => oldAdmission }, false);
			}

			if ((stagesToRunSharingRemove.contains(admission.Stage__c) || ('Discharged'.equals(admission.Stage__c) && admission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) && activeDraftTreatmentPlansByAdmission.containsKey(admission.Id)) {
				treatmentPlansToInactivate.addAll(activeDraftTreatmentPlansByAdmission.get(admission.Id));
			}

			// NPSP Updates - DAvery - 11/17/2022
			if (stagesToRunSharingCreateNPSP.contains(admission.Stage__c)) {
				runSharingUpdatesNPSP(new List<Admission__c>{ admission }, new Map<Id, Admission__c>{ oldAdmission.Id => oldAdmission }, true);
			} else if (stagesToRunSharingRemoveNPSP.contains(admission.Stage__c)) {
				runSharingUpdatesNPSP(new List<Admission__c>{ admission }, new Map<Id, Admission__c>{ oldAdmission.Id => oldAdmission }, false);
			}
		}

		if (!admittedAdmissionIds.isEmpty()) {
			psychHelper.fetchInfo(admittedAdmissionIds);
			for (Id admittedId : admittedAdmissionIds) {
				psychHelper.createPsychTestingRequest(admittedId);
			}
		}

		AlertsFilter.execute(null, admission, this.alertsToBePublished, triggerObject, 'Insert');
		AlertsFilter.execute(oldAdmission, admission, this.alertsToBePublished, triggerObject, 'Update');

		// Send Updates to ScriptSure if Patient's Consent to Download Medical History has changed.
		if (null != admission.Patient_External_ID__c && null != admission.Patient_Consent_to_Download_Medi_History__c && admission.Patient_Consent_to_Download_Medi_History__c != oldAdmission.Patient_Consent_to_Download_Medi_History__c && !Test.isRunningTest()) {
			ScriptSure_ServiceUtil.updateScriptSurePatient(admission.Patient_Account__c);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
		Admission__c admission = (Admission__c) so;
		if (stagesToRunSharingRemove.contains(admission.Stage__c) && activeDraftTreatmentPlansByAdmission.containsKey(admission.Id)) {
			treatmentPlansToInactivate.addAll(activeDraftTreatmentPlansByAdmission.get(admission.Id));
		}
	}

	/*******************************************************************************************************
	 * @description This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
		if (!Trigger.isDelete) {
			//Admissions ending so need to update Assigned Clinicians
			List<Admission__c> endingAdms = new List<Admission__c>();
			for (String endingStage : AssignedClinicians.endingStagesForAssignedClinicians) {
				//get correct value from restricted picklist
				String validatedStage = AssignedClinicians.getAdmStagePicklistValue(endingStage);
				if (newStage2AdmIdsMap.containsKey(validatedStage)) {
					Set<Id> admIds = newStage2AdmIdsMap.get(validatedStage);
					for (Id admId : admIds) {
						endingAdms.add((Admission__c) Trigger.newMap.get(admId));
					}
				}
			}
			if (!endingAdms.isEmpty()) {
				AssignedClinicians.fixClinicianEndDates(endingAdms);
			}

			psychHelper.insertPsychTestingRequests();

			if (this.alertsToBePublished.size() > 0) {
				List<Database.SaveResult> results = EventBus.publish(this.alertsToBePublished);
				for (Database.SaveResult result : results) {
					if (!result.isSuccess()) {
						ProcessLogging.quickProcessLog('AdmissionTriggerHandler.andFinally(alertsToBePublished)', '', 'Database.saveResult not success:  \nresult.getErrors(): \n' + JSON.serialize(result.getErrors()));
					}
				}
			}
		}

		if (!treatmentPlansToInactivate.isEmpty()) {
			List<Case> tpsToUpdate = new List<Case>();
			for (Case c : treatmentPlansToInactivate) {
				tpsToUpdate.add(new Case(Id = c.Id, Status = 'Inactive'));
			}
			update tpsToUpdate;
		}

		if(!chartClosedAdmissionsByIdMap.isEmpty()) {
			processChartClosedAdmissions();
		}

		Boolean triggerSharingBatch = false;
		System.debug('in andFinally (trigger.isBefore : ' + Trigger.isBefore + ') - accountsToShare : ' + accountsToShare);
		if(!accountsToShare.isEmpty()) {
			update accountsToShare;
			triggerSharingBatch = true;
		}

		System.debug('in andFinally (trigger.isBefore : ' + Trigger.isBefore + ') - accountsToRemoveSharing : ' + accountsToRemoveSharing);
		if(!accountsToRemoveSharing.isEmpty()) {
			update accountsToRemoveSharing;
			triggerSharingBatch = true;
		}

		System.debug('in andFinally (trigger.isBefore : ' + Trigger.isBefore + ') - accountsToShareNPSP : ' + accountsToShareNPSP);
		if(!accountsToShareNPSP.isEmpty()) {
			update accountsToShareNPSP;
			triggerSharingBatch = true;
		}

		System.debug('in andFinally (trigger.isBefore : ' + Trigger.isBefore + ') - accountsToRemoveSharingNPSP : ' + accountsToRemoveSharingNPSP);
		if(!accountsToRemoveSharingNPSP.isEmpty()) {
			update accountsToRemoveSharingNPSP;
			triggerSharingBatch = true;
		}

		if(triggerSharingBatch) {
			PatientRecordSharingBatch batch = new PatientRecordSharingBatch();
			database.executeBatch(batch);
		}
	}

	public void processChartClosedAdmissions() {

		Set<Id> admissionIds = chartClosedAdmissionsByIdMap.keySet();

		Patient_Note__c[] draftPatientNotes = [SELECT Id, Status__c FROM Patient_Note__c WHERE Admission__c IN :admissionIds AND Status__c = 'Draft'];
		for(Patient_Note__c p : draftPatientNotes) {
			p.Status__c = 'Cancelled';
		}
		update draftPatientNotes;
		
		Procedure_Order__c[] draftProcedureOrders = [SELECT Id, Status__c FROM Procedure_Order__c WHERE Admission__c IN :admissionIds AND (Status__c = 'Draft' OR (Status__c = 'Completed' AND Received_Procedure_Results__c = 0 AND Closed_Procedure_Results__c = 0))];
		for(Procedure_Order__c p : draftProcedureOrders) {
			p.Status__c = 'Cancelled';
		}
		update draftProcedureOrders;

		Procedure_Result__c[] draftProcedureResults = [SELECT Id, Status__c FROM Procedure_Result__c WHERE Procedure_Order__r.Admission__c IN :admissionIds AND Status__c NOT IN ('Received', 'Reviewed', 'Cancelled')];
		for(Procedure_Result__c p : draftProcedureResults) {
			p.Status__c = 'Cancelled';
		}
		update draftProcedureResults;

		Procedure_Result__c[] procedureResultsToFireOpenItemsCheck = [SELECT Id, Status__c FROM Procedure_Result__c WHERE Procedure_Order__r.Admission__c IN :admissionIds AND Status__c IN ('Received', 'Reviewed')];
		if(procedureResultsToFireOpenItemsCheck.size() > 0) {
			OutstandingItems.fireCheckOutstandingEvent(procedureResultsToFireOpenItemsCheck);
		}

		disco__Form__c[] forms = [SELECT Id FROM disco__Form__c WHERE Admission__c IN :admissionIds AND (NOT disco__Form_Template_Name__c LIKE 'Admissions Screening Checklist%') AND disco__Status__c != 'LOCKED'];
		delete forms;

		Nursing_Shift_Item__c[] futureNsis = [SELECT Id, Status__c FROM Nursing_Shift_Item__c WHERE Admission__c IN :admissionIds AND Status__c = 'Open'];
		for(Nursing_Shift_Item__c o : futureNsis) {
			o.Status__c = 'Cancelled';
		}
		update futureNsis;
		
		Set<Id> accountIds = new Set<Id>();
		for(Admission__c a : chartClosedAdmissionsByIdMap.values()) {
			accountIds.add(a.Patient_Account__c);
		}

		Prescription__c[] prescriptionsToEnd = [SELECT Id, Admission__c, Status__c, End_Date__c FROM Prescription__c WHERE Admission__c IN :admissionIds AND Status__c = 'Active'];
		for(Prescription__c o : prescriptionsToEnd) {
			o.Status__c = 'Discontinued';
			Admission__c a = chartClosedAdmissionsByIdMap.get(o.Admission__c);
			o.End_Date__c = null != a && null != a.Discharge_Date__c ? a.Discharge_Date__c : System.today();
		}
		update prescriptionsToEnd;

		EGO__c[] draftEgos = [SELECT Id, Status__c FROM EGO__c WHERE Admission__c IN :admissionIds AND Status__c = 'Draft'];
		for(EGO__c o : draftEgos) {
			o.Status__c = 'Cancelled';
		}
		update draftEgos;

		Physical_Monitor__c[] draftPhysicalMonitors = [SELECT Id, Status__c FROM Physical_Monitor__c WHERE Admission__c IN :admissionIds AND Status__c = 'Draft'];
		for(Physical_Monitor__c o : draftPhysicalMonitors) {
			o.Status__c = 'Cancelled';
		}
		update draftPhysicalMonitors;

		Case_Abstract__c[] draftCaseAbstracts = [SELECT Id, Status__c FROM Case_Abstract__c WHERE Admission__c IN :admissionIds AND Status__c = 'Draft'];
		for(Case_Abstract__c o : draftCaseAbstracts) {
			o.Status__c = 'Cancelled';
		}
		update draftCaseAbstracts;

		Psych_Testing_Request__c[] openPsychTestingRequests = [SELECT Id, Patient_Note__r.Status__c FROM Psych_Testing_Request__c WHERE Admission__c IN :admissionIds AND Patient_Note__r.Status__c != 'Finalized'];
		delete openPsychTestingRequests;

		Action_Item__c[] openActionItems = [SELECT Id, Status__c FROM Action_Item__c WHERE Admission__c IN :admissionIds AND Status__c = 'Open'];
		for(Action_Item__c o : openActionItems) {
			o.Status__c = 'Cancelled';
		}
		update openActionItems;

	}

	/****** Sharing Model ******/
	public void runSharingUpdates(List<Admission__c> newRecords, Map<Id, Admission__c> oldMap, Boolean isCreate) {
		Map<Id, Account> accountsMap;
		Set<Id> relatedAccountIds = new Set<Id>();
		for (Admission__c admission : newRecords) {
			relatedAccountIds.add(admission.Patient_Account__c);
		}

		accountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :relatedAccountIds]);

		for (Admission__c currentAdmission : newRecords) {
			Account patient = accountsMap.get(currentAdmission.Patient_Account__c);

			if (isCreate) {
				System.debug('sharing records for currentAdmission : ' + currentAdmission);
				Admission__c oldAdmission = oldMap.get(currentAdmission.Id);
				if (currentAdmission.Stage__c != oldAdmission.Stage__c || (currentAdmission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
					List<String> stagesToShareWithClinical = new List<String>{ 'Consultation Pending', 'Admitted' };
					if (stagesToShareWithClinical.contains(currentAdmission.Stage__c) || ('Discharged' == currentAdmission.Stage__c && currentAdmission.Chart_Closed__c)) {
						patient.Sharing_Clinical__c = 'Share';
						accountsToShare.add(patient);
					}
				}
				system.debug('accountsToShare in isCreate : ' + accountsToShare);
			} else {
				Admission__c oldAdmission = oldMap.get(currentAdmission.Id);
				if (currentAdmission.Stage__c != oldAdmission.Stage__c || (currentAdmission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
					List<String> stagesToRemoveFromClinical = new List<String>{ 'Declined by Riggs', 'Withdrawn', 'Inactive' };
					if (stagesToRemoveFromClinical.contains(currentAdmission.Stage__c) || (currentAdmission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
						patient.Sharing_Clinical__c = 'Remove';
						accountsToRemoveSharing.add(patient);
					}
				}
			}
		}
	}

	public void runSharingUpdatesNPSP(List<Admission__c> newRecords, Map<Id, Admission__c> oldMap, Boolean isCreate) {
		Map<Id, Account> accountsMap;
		Set<Id> relatedAccountIds = new Set<Id>();
		for (Admission__c admission : newRecords) {
			relatedAccountIds.add(admission.Patient_Account__c);
		}

		accountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :relatedAccountIds]);

		for (Admission__c currentAdmission : newRecords) {
			Account patient = accountsMap.get(currentAdmission.Patient_Account__c);

			if (isCreate) {
				patient.Sharing_NPSP__c = 'Share';
				accountsToShareNPSP.add(patient);
			} else {
				patient.Sharing_NPSP__c = 'Remove';
				accountsToRemoveSharingNPSP.add(patient);
			}
		}
	}



	// This should be optimized to cache queries. Redo if we near SOQL governor limits. This really shouldn't be in this class either.
	// public void runSharingUpdates(List<Admission__c> newRecords, Map<Id, Admission__c> oldMap, Boolean isCreate) {
	// 	Map<Id, Account> accountsMap;
	// 	Map<Id, Case> casesMap;
	// 	Map<Id, Admission__c> admissionsMap;
	// 	Map<Id, Goal__c> goalsMap;
	// 	Map<Id, Ego__c> egosMap;
	// 	Map<String, Id> groupIdsByName;

	// 	Set<Id> relatedAccountIds = new Set<Id>();
	// 	for (Admission__c admission : newRecords) {
	// 		relatedAccountIds.add(admission.Patient_Account__c);
	// 	}

	// 	accountsMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Admission_Files__r), (SELECT Id FROM Cases), (SELECT Id FROM Patient_Notes__r) FROM Account WHERE Id IN :relatedAccountIds]);

	// 	Set<Id> relatedCases = new Set<Id>();
	// 	Set<Id> relatedAdmissions = new Set<Id>();
	// 	for (Account acc : accountsMap.values()) {
	// 		for (Case currentCase : acc.Cases) {
	// 			relatedCases.add(currentCase.Id);
	// 		}
	// 		for (Admission__c admission : acc.Admission_Files__r) {
	// 			relatedAdmissions.add(admission.Id);
	// 		}
	// 	}

	// 	casesMap = new Map<Id, Case>([SELECT Id, (SELECT Id FROM Interventions__r), (SELECT Id FROM Goals_Draft_Treatment_Plan__r) FROM Case WHERE Id IN :relatedCases]);

	// 	admissionsMap = new Map<Id, Admission__c>([SELECT Id, (SELECT Id FROM EGOs__r), (SELECT Id FROM Diagnoses__r) FROM Admission__c WHERE Id IN :relatedAdmissions]);

	// 	Set<Id> relatedGoals = new Set<Id>();
	// 	for (Case currentCase : casesMap.values()) {
	// 		for (Goal__c goal : currentCase.Goals_Draft_Treatment_Plan__r) {
	// 			relatedGoals.add(goal.Id);
	// 		}
	// 	}

	// 	goalsMap = new Map<Id, Goal__c>([SELECT Id, (SELECT Id FROM Objectives__r) FROM Goal__c WHERE Id IN :relatedGoals]);

	// 	Set<Id> relatedEGOs = new Set<Id>();
	// 	for (Admission__c admission : admissionsMap.values()) {
	// 		for (Ego__c ego : admission.EGOs__r) {
	// 			relatedEGOs.add(ego.Id);
	// 		}
	// 	}

	// 	egosMap = new Map<Id, Ego__c>([SELECT Id, (SELECT Id FROM Ego_Ratings__r) FROM EGO__c WHERE Id IN :relatedEGOs]);

	// 	List<Group> allGroups = [SELECT Name FROM Group];
	// 	groupIdsByName = new Map<String, Id>();
	// 	for (Group currentGroup : allGroups) {
	// 		groupIdsByName.put(currentGroup.Name, currentGroup.Id);
	// 	}

	// 	for (Admission__c currentAdmission : newRecords) {
	// 		Account patient = accountsMap.get(currentAdmission.Patient_Account__c);

	// 		List<Id> allRecordIds = new List<Id>{ patient.Id };

	// 		// Get related Admission Files and related objects Ids for the chosen Patient
	// 		for (Admission__c admission : patient.Admission_Files__r) {
	// 			for (EGO__c ego : admission.EGOs__r) {
	// 				allRecordIds.add(ego.Id);
	// 				for (EGO_Rating__c egoRating : ego.EGO_Ratings__r) {
	// 					allRecordIds.add(egoRating.Id);
	// 				}
	// 			}
	// 			// 12/5/2022 - DAvery - removed this as the OWD is controlled by parent (Admission)
	// 			// for (Diagnosis__c diagnosis : admission.Diagnoses__r) {
	// 			// 	allRecordIds.add(diagnosis.Id);
	// 			// }
	// 		}

	// 		// Get related Cases and related objects Ids for chosen Patient
	// 		for (Case currentCase : patient.Cases) {
	// 			allRecordIds.add(currentCase.Id);
	// 			for (Intervention__c intervention : currentCase.Interventions__r) {
	// 				allRecordIds.add(intervention.Id);
	// 			}
	// 			for (Goal__c goal : currentCase.Goals_Draft_Treatment_Plan__r) {
	// 				allRecordIds.add(goal.Id);
	// 				for (Objective__c objective : goal.Objectives__r) {
	// 					allRecordIds.add(objective.Id);
	// 				}
	// 			}
	// 		}

	// 		// Get related Patient Notes Ids for chosen Patient
	// 		for (Patient_Note__c pNote : patient.Patient_Notes__r) {
	// 			allRecordIds.add(pNote.Id);
	// 		}

	// 		if (isCreate) {
	// 			List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Admissions') };
	// 			String result = SharingRecord_Utils.createSharingRecords(allRecordIds, groupsToShare, 'Edit');

	// 			Admission__c oldAdmission = oldMap.get(currentAdmission.Id);
	// 			if (currentAdmission.Stage__c != oldAdmission.Stage__c || (currentAdmission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
	// 				List<String> stagesToShareWithClinical = new List<String>{ 'Consultation Pending', 'Admitted' };

	// 				if (stagesToShareWithClinical.contains(currentAdmission.Stage__c) || ('Discharged' == currentAdmission.Stage__c && currentAdmission.Chart_Closed__c)) {
	// 					groupsToShare = new List<Id>{ groupIdsByName.get('Clinical') };
	// 					result = SharingRecord_Utils.createSharingRecords(allRecordIds, groupsToShare, 'Edit');

	// 					// Share any related Snapshot records
	// 					List<Snapshot__c> snapshots = [SELECT Id from Snapshot__c WHERE EGO__c IN :allRecordIds OR Patient_Note__c IN :allRecordIds OR Treatment_Plan__c IN :allRecordIds];
	// 					List<Id> snapshotIds = new List<Id>();
	// 					for(Snapshot__c s : snapshots) {
	// 						snapshotIds.add(s.Id);
	// 					}
	// 					result = SharingRecord_Utils.createSharingRecords(snapshotIds, groupsToShare, 'Read');
	// 				}
	// 			}
	// 		} else {
	// 			Admission__c oldAdmission = oldMap.get(currentAdmission.Id);
	// 			if (currentAdmission.Stage__c != oldAdmission.Stage__c || (currentAdmission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
	// 				List<String> stagesToRemoveFromClinical = new List<String>{ 'Declined by Riggs', 'Withdrawn', 'Inactive' };
	// 				if (stagesToRemoveFromClinical.contains(currentAdmission.Stage__c) || (currentAdmission.Chart_Closed__c == true && oldAdmission.Chart_Closed__c == false)) {
	// 					List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Clinical') };
	// 					for (Snapshot__C snapshot : [SELECT Id FROM Snapshot__c WHERE Treatment_Plan__c IN :allRecordIds OR EGO__c IN :allRecordIds OR Patient_Note__c IN :allRecordIds]) {
	// 						allRecordIds.add(snapshot.Id);
	// 					}
	// 					String result = SharingRecord_Utils.deleteSharingRecords(allRecordIds, groupsToShare);
	// 					//Database.delete([SELECT Id FROM Outstanding_Tag__c WHERE Record_ID__c IN :allRecordIds]);
	// 				}
	// 			}
	// 		}
	// 	}
	// }

	// public void runSharingUpdatesNPSP(List<Admission__c> newRecords, Map<Id, Admission__c> oldMap, Boolean isCreate) {
	// 	Map<Id, Account> accountsMap;
	// 	Map<Id, Admission__c> admissionsMap;
	// 	Map<Id, Related_Contact__c> relatedContactsMap;
	// 	Map<String, Id> groupIdsByName;

	// 	Set<Id> relatedAccountIds = new Set<Id>();
	// 	for (Admission__c admission : newRecords) {
	// 		relatedAccountIds.add(admission.Patient_Account__c);
	// 	}

	// 	accountsMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Admission_Files__r), (SELECT Id FROM Related_Contacts__r) FROM Account WHERE Id IN :relatedAccountIds]);

	// 	Set<Id> relatedContacts = new Set<Id>();
	// 	Set<Id> relatedAdmissions = new Set<Id>();
	// 	for (Account acc : accountsMap.values()) {
	// 		for (Related_Contact__c relatedContact : acc.Related_Contacts__r) {
	// 			relatedContacts.add(relatedContact.Id);
	// 		}
	// 		for (Admission__c admission : acc.Admission_Files__r) {
	// 			relatedAdmissions.add(admission.Id);
	// 		}
	// 	}

	// 	relatedContactsMap = new Map<Id, Related_Contact__c>([SELECT Id, Type__c FROM Related_Contact__c WHERE Id IN :relatedContacts]);

	// 	admissionsMap = new Map<Id, Admission__c>([SELECT Id FROM Admission__c WHERE Id IN :relatedAdmissions]);

	// 	List<Group> allGroups = [SELECT Name FROM Group];
	// 	groupIdsByName = new Map<String, Id>();
	// 	for (Group currentGroup : allGroups) {
	// 		groupIdsByName.put(currentGroup.Name, currentGroup.Id);
	// 	}

	// 	for (Admission__c currentAdmission : newRecords) {
	// 		Account patient = accountsMap.get(currentAdmission.Patient_Account__c);

	// 		List<Id> allRecordIds = new List<Id>{ patient.Id };
	// 		List<Id> groupsToShare = new List<Id>{ groupIdsByName.get('Communications and Marketing'), groupIdsByName.get('Fundraising and Development') };
	// 		System.debug('In runSharingUpdatesNPSP - groupsToShare : ' + groupsToShare);
	// 		System.debug('In runSharingUpdatesNPSP - isCreate : ' + isCreate);

	// 		if (isCreate) {
	// 			if (!relatedContactsMap.isEmpty()) {
	// 				for (Related_Contact__c relatedContact : relatedContactsMap.values()) {
	// 					if ('Professional;Patient;Personal'.contains(relatedContact.Type__c)) {
	// 						allRecordIds.add(relatedContact.Id);
	// 					}
	// 				}
	// 			}
	// 			String result = SharingRecord_Utils.createSharingRecords(allRecordIds, groupsToShare, 'Edit');
	// 			System.debug('In runSharingUpdatesNPSP. Just shared Edit for allRecordIds : ' + allRecordIds);
	// 			System.debug('In runSharingUpdatesNPSP - result : ' + result);
	// 		} else {
	// 			if (!relatedContactsMap.isEmpty()) {
	// 				for (Related_Contact__c relatedContact : relatedContactsMap.values()) {
	// 					if ('Patient;Personal'.contains(relatedContact.Type__c)) {
	// 						allRecordIds.add(relatedContact.Id);
	// 					}
	// 				}
	// 			}
	// 			String result = SharingRecord_Utils.deleteSharingRecords(allRecordIds, groupsToShare);
	// 			System.debug('In runSharingUpdatesNPSP. Just deleted sharing for allRecordIds : ' + allRecordIds);
	// 			System.debug('In runSharingUpdatesNPSP - result : ' + result);
	// 		}
	// 	}
	// }
	/****** END Sharing Model ******/
}
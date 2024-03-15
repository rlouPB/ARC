public class AssignedClinicians {
	@invocableMethod
	public static void invocableSyncAssignedClinicians(List<String> AssignedClinicians) {
		syncAssignedClinicians(assignedClinicians);
	}

	// public static void syncAssignedClinicians(String assignedClinicians)
	// {
	// 	List<String> newList = new List<String>();
	// 	newList.add(assignedClinicians);
	// 	syncAssignedClinicians(newList);
	// }

	public static List<String> endingStagesForAssignedClinicians = new List<String>{ 'Declined', 'Withdrawn', 'Discharged' };

	//Populate lookup fields on Admission record based on current Assigned Clinicians
	@future
	public static void syncAssignedClinicians(List<String> admIdStrings) {
		List<ID> admissionIDs = new List<ID>();
		for (String admId : admIdStrings) {
			admissionIDs.add(admId);
		}

		List<String> roleStrings = new List<String>();
		Schema.DescribeFieldResult assignedClinicianRoleResult = Assigned_Clinician__c.Role__c.getDescribe();
		List<Schema.PicklistEntry> assignedClinicianRoleValues = assignedClinicianRoleResult.getPicklistValues();
		for (Schema.PicklistEntry currentRoleValue : assignedClinicianRoleValues) {
			roleStrings.add(currentRoleValue.getLabel());
		}

		List<Admission__c> relatedAdmissions = [SELECT Psychotherapist__c, Psychiatrist__c, Nurse_Care_Coordinator__c, Clinical_Social_Worker__c, Substance_Use_Counselor__c, Registered_Dietitian_Nutritionist__c, Team_Leader__c, Community_Program_Rep__c, Program_Manager__c FROM Admission__c WHERE ID IN :admissionIDs];

		List<Assigned_Clinician__c> allRelatedClinicians = [SELECT Role__c, Admission__c, User__c FROM Assigned_Clinician__c WHERE Admission__c IN :admissionIDs AND Start_Date__c <= :Date.today() AND (End_Date__c = NULL OR End_Date__c > :Date.today()) ORDER BY End_Date__c ASC NULLS LAST];

		Map<ID, Map<String, Assigned_Clinician__c>> cliniciansByRoleAdmissionMap = new Map<ID, Map<String, Assigned_Clinician__c>>();
		for (Assigned_Clinician__c currentClinician : allRelatedClinicians) {
			Map<String, Assigned_Clinician__c> currentAdmissionMap = cliniciansByRoleAdmissionMap.get(currentClinician.Admission__c);
			if (currentAdmissionMap == null) {
				currentAdmissionMap = new Map<String, Assigned_Clinician__c>();
			}
			currentAdmissionMap.put(currentClinician.Role__c, currentClinician);
			cliniciansByRoleAdmissionMap.put(currentClinician.Admission__c, currentAdmissionMap);
		}

		List<Admission__c> admissionsToUpdate = new List<Admission__c>();
		String missingFields = '';
		for (Admission__c currentAdmission : relatedAdmissions) {
			Boolean updateNeeded = false;
			Admission__c updatedAdmission = new Admission__c(ID = currentAdmission.ID);
			Map<String, Assigned_Clinician__c> currentAdmissionMap = cliniciansByRoleAdmissionMap.get(currentAdmission.ID);
			if (currentAdmissionMap == null) {
				currentAdmissionMap = new Map<String, Assigned_Clinician__c>();
			}

			for (String currentRole : roleStrings) {
				String regExp = '[ ]';
				String roleAsAPI = currentRole.replaceAll(regExp, '_') + '__c';
				try {
					Assigned_Clinician__c clinician = currentAdmissionMap.get(currentRole);
					if (clinician == null) {
						clinician = new Assigned_Clinician__c();
					}

					updateNeeded = true;
					if (clinician.User__c == null) {
						updatedAdmission.put(roleAsAPI, null);
					} else {
						updatedAdmission.put(roleAsAPI, clinician.User__c);
					}
				} catch (Exception ex) {
					if (!missingFields.contains(roleAsAPI)) {
						missingFields += roleAsAPI + ';';
					}
				}
			}

			if (updateNeeded) {
				admissionsToUpdate.add(updatedAdmission);
			}
		}

		update admissionsToUpdate;

		if (missingFields != '') {
			// ProcessLogging.quickProcessLog('AssignedClinicians.syncAssignedClinicians', 'missing fields',
			// 								'The following fields are missing from Admission object: ' + missingFields);
		}
	}

	//called by Admission trigger when Stage has changed to a new key stage, need to add End Dates to Assigned Clinicians
	public static void fixClinicianEndDates(List<Admission__c> admsWithChangedStages) {
		Set<Id> admIds = new Map<Id, Admission__c>(admsWithChangedStages).keySet();

		List<Admission__c> queriedAdms = [SELECT Id, Stage__c, Admit_Date__c, Consultation_Date__c, Discharge_Date__c, (SELECT Id, Start_Date__c, End_Date__c FROM Assigned_Clinicians__r WHERE End_Date__c = NULL OR End_Date__c > :System.today()) FROM Admission__c WHERE Id IN :admIds];
		List<Assigned_Clinician__c> clinsToUpdate = new List<Assigned_Clinician__c>();
		for (Admission__c adm : queriedAdms) {
			Date newEndDate;
			switch on adm.Stage__c {
				when 'Discharged' {
					newEndDate = adm.Discharge_Date__c;
				}
				when 'Declined' {
					newEndDate = adm.Consultation_Date__c;
				}
				when 'Withdrawn' {
					newEndDate = adm.Consultation_Date__c;
				}
			}
			for (Assigned_Clinician__c clin : adm.Assigned_Clinicians__r) {
				if (clin.End_Date__c == null || clin.End_Date__c > newEndDate) {
					clinsToUpdate.add(new Assigned_Clinician__c(Id = clin.Id, End_Date__c = newEndDate));
				}
			}
		}
		update clinsToUpdate;
	}

	//return picklist value on Restricted Picklist, there are a couple of Stage Picklist values that changed
	public static String getAdmStagePicklistValue(String searchText) {
		String objectName = 'Admission__c';
		String fieldName = 'Stage__c';
		String foundValue;

		List<PicklistCtl.PicklistOption> options = PicklistCtl.getPicklistOptions(objectName, fieldName);
		for (PicklistCtl.PicklistOption plo : options) {
			if (plo.value.contains(searchText) || plo.label.contains(searchText)) {
				foundValue = plo.value;
				break;
			}
		}
		return foundValue;
	}
}
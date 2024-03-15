public without sharing class ChangeAdmittedProgramHelper {
	public static final string[] stageList = 'Discharged;Inactive;Declined by Riggs;Withdrawn;Inactive'.split(';');

	public static final string dischargeDatesOnChildsErrorMessage = 'REQUIRED: Review and update the End Date(s) for the Program and/or Status before updating the Discharge Date.';

	public static void processDischarge(Admission__c[] newList, Map<Id, SObject> oldMap) {
		Admission__c[] discharges = new List<Admission__c>{};
		if (newList != null) {
			for (Admission__c record : newList) {
				Admission__c old = (oldMap != null && oldMap.containsKey(record.Id)) ? (Admission__c) oldMap.get(record.Id) : null;
				if (old != null && record.Stage__c != old.Stage__c && stageList.contains(record.Stage__c) && record.Discharge_Date__c != null) {
					discharges.add(record);
				}
			}
		}
		if (discharges.size() > 0) {
			dischargeRelatedRecords(discharges);
		}
	}

	public static void dischargeRelatedRecords(Admission__c[] discharges) {
		Map<Id, Admission__c> admissionByAdmittedProgram = new Map<Id, Admission__c>();

		// set<id> currentAdmittedProgramIds = new set<id>();
		for (Admission__c a : discharges) {
			if (a.Current_Admitted_Program__c != null) {
				// currentAdmittedProgramIds.add(a.Current_Admitted_Program__c);
				admissionByAdmittedProgram.put(a.Current_Admitted_Program__c, a);
			}
		}
		map<id, Admitted_Program__c> admittedProgramMap = new Map<id, Admitted_Program__c>([SELECT Id, Start_Date__c, End_Date__c, (SELECT Id, End_Date_Time__c FROM Admitted_Program_Statuses__r WHERE End_Date_Time__c = NULL) FROM Admitted_Program__c WHERE Id IN :admissionByAdmittedProgram.keySet()]);

		Admitted_Program__c[] apToUpdate = new List<Admitted_Program__c>{};
		Admitted_Program_Status__c[] apsToUpdate = new List<Admitted_Program_Status__c>{};
		for (Admitted_Program__c ap : admittedProgramMap.values()) {
			Admission__c adm = admissionByAdmittedProgram.get(ap.Id);
			if (ap.End_Date__c != adm.Discharge_Date__c) {
				apToUpdate.add(new Admitted_Program__c(Id = ap.Id, End_Date__c = adm.Discharge_Date__c));
			}
			Datetime newStatusEndDateTime = DateTime.newInstance(adm.Discharge_Date__c, Time.newInstance(0, 0, 0, 0));
			for (Admitted_Program_Status__c aps : ap.Admitted_Program_Statuses__r) {
				if (aps.End_Date_Time__c != newStatusEndDateTime) {
					apsToUpdate.add(new Admitted_Program_Status__c(Id = aps.Id, End_Date_Time__c = newStatusEndDateTime));
				}
			}
		}

		update apToUpdate;
		update apsToUpdate;
	}

	/**
	 * @description validates wether the child objects from admission have a endDate the same as the discharge date of the admission
	 * @runAt       before update
	 */
	public static void validateDischargeDatesOnChilds(Admission__c[] newList, Map<Id, SObject> oldMap) {
		id[] targetAdmissionIds = new List<id>{};
		map<id, id> currentAdmittedProgramToAdmissionIdMap = new Map<id, id>();
		map<id, Admission__c> newMap = new Map<id, Admission__c>(newList);

		if (newList != null) {
			for (Admission__c record : newList) {
				Admission__c old = (oldMap != null && oldMap.containsKey(record.Id)) ? (Admission__c) oldMap.get(record.Id) : null;
				if (old != null && record.Discharge_Date__c != old.Discharge_Date__c) {
					targetAdmissionIds.add(record.Id);
					if (record.Current_Admitted_Program__c != null) {
						currentAdmittedProgramToAdmissionIdMap.put(record.Current_Admitted_Program__c, record.Id);
					}
				}
			}
		}
		if (targetAdmissionIds.size() > 0) {
			set<id> currentAdmittedProgramIds = currentAdmittedProgramToAdmissionIdMap.keyset();
			map<id, Admitted_Program__c> admittedProgramMap = new Map<id, Admitted_Program__c>([SELECT Id, End_Date__c, (SELECT Id, End_Date_Time__c FROM Admitted_Program_Statuses__r) FROM Admitted_Program__c WHERE id IN :currentAdmittedProgramIds]);
			for (Admitted_Program__c am : admittedProgramMap.values()) {
				Id admissionId = currentAdmittedProgramToAdmissionIdMap.get(am.Id);
				Admission__c admission = newMap.get(admissionId);
				Admission__c old = (Admission__c) oldMap.get(admission.Id);
				if (am.End_Date__c == old.Discharge_Date__c) {
					admission.Discharge_Date__c.addError(dischargeDatesOnChildsErrorMessage);
				}
				if (am.Admitted_Program_Statuses__r != null) {
					for (Admitted_Program_Status__c aps : am.Admitted_Program_Statuses__r) {
						if (aps.End_Date_Time__c.Date() == old.Discharge_Date__c) {
							admission.Discharge_Date__c.addError(dischargeDatesOnChildsErrorMessage);
						}
					}
				}
			}
		}
	}
}
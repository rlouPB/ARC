public with sharing class Admitted_ProgramStatusTriggerHandler {
	private static final String OPEN_STATUS = 'Open';
	private static final String CLOSED_STATUS = 'Closed';
	private static final String NEW_STATUS = 'New';
	private static final String ADMITTED_PAS_STATUS = 'Program Assessment Status (PAS)';
	private static final String DOC_TEMPLETE_NAME = 'Patient_Certification_of_Dispensed';

	public static void createNursingShiftItemsAndForms(List<Admitted_Program_Status__c> newProgramStatuses) {
		List<Admitted_Program_Status__c> pasAdmittedProgramStatusList = new List<Admitted_Program_Status__c>();
		Set<Id> admittedProgramIds = new Set<Id>();

		for (Admitted_Program_Status__c aps : newProgramStatuses) {
			if (aps.Status__c == ADMITTED_PAS_STATUS) {
				pasAdmittedProgramStatusList.add(aps);
				admittedProgramIds.add(aps.Admitted_Program__c);
			}
		}

		if (pasAdmittedProgramStatusList.isEmpty()) {
			return;
		}

		Map<Id, Admitted_Program__c> admittedProgramsByIdMap = new Map<Id, Admitted_Program__c>([SELECT Id, Admission__c, Admission__r.Patient_Account__c, Admission__r.Patient_Account__r.Patient_Contact__c FROM Admitted_Program__c WHERE Id IN :admittedProgramIds]);

		List<Nursing_Shift__c> nursingShifts = [SELECT Id, Name, Date__c FROM Nursing_Shift__c WHERE Status__c = :NEW_STATUS AND Date__c >= TODAY];

		List<disco__Form__c> discoFormsToInsert = new List<disco__Form__c>();
		Map<String, disco__Form__c> discoFormsByAPSAndShiftMap = new Map<String, disco__Form__c>();

		for (Admitted_Program_Status__c aps : pasAdmittedProgramStatusList) {
			for (Nursing_Shift__c shift : nursingShifts) {
				if (admittedProgramsByIdMap.containsKey(aps.Admitted_Program__c)) {
					Disco__Form__c df = new disco__Form__c(disco__Form_Account__c = admittedProgramsByIdMap.get(aps.Admitted_Program__c).Admission__r.Patient_Account__c, disco__Form_Template__c = DispensingService.PSAT_FORM_TEMPLATE.Id, Admission__c = admittedProgramsByIdMap.get(aps.Admitted_Program__c).Admission__c, disco__Form_Contact__c = admittedProgramsByIdMap.get(aps.Admitted_Program__c).Admission__r.Patient_Account__r.Patient_Contact__c);
					discoFormsToInsert.add(df);
					String key = aps.Id + '_' + shift.Id;
					discoFormsByAPSAndShiftMap.put(key, df);
				}
			}
		}
		insert discoFormsToInsert;

		List<Nursing_Shift_Item__c> nursingShiftItems = new List<Nursing_Shift_Item__c>();
		for (Admitted_Program_Status__c aps : pasAdmittedProgramStatusList) {
			for (Nursing_Shift__c shift : nursingShifts) {
				String key = aps.Id + '_' + shift.Id;
				if (admittedProgramsByIdMap.containsKey(aps.Admitted_Program__c)) {
					nursingShiftItems.add(new Nursing_Shift_Item__c(Nursing_Shift__c = shift.Id, Due_Date__c = null != aps.End_Date_Time__c ? aps.End_Date_Time__c.Date() : null, Status__c = OPEN_STATUS, Patient__c = admittedProgramsByIdMap.get(aps.Admitted_Program__c).Admission__r.Patient_Account__c, Form__c = discoFormsByAPSAndShiftMap.get(key).Id));
				}
			}
		}
		insert nursingShiftItems;
	}

	public static void deleteNursingShiftItemsAndForms(List<Admitted_Program_Status__c> admittedProgramStatuses, Map<Id, Admitted_Program_Status__c> oldMap) {
		List<Admitted_Program_Status__c> pasAdmittedProgramStatusList = new List<Admitted_Program_Status__c>();
		Set<Id> admittedProgramIds = new Set<Id>();

		for (Admitted_Program_Status__c aps : admittedProgramStatuses) {
			if (aps.Status__c == ADMITTED_PAS_STATUS) {
				pasAdmittedProgramStatusList.add(aps);
				admittedProgramIds.add(aps.Admitted_Program__c);
			}
		}

		if (pasAdmittedProgramStatusList.isEmpty()) {
			return;
		}

		Map<Id, Admitted_Program__c> admittedProgramsByIdMap = new Map<Id, Admitted_Program__c>([SELECT Id, Admission__c, Admission__r.Patient_Account__c, Admission__r.Patient_Account__r.Patient_Contact__c FROM Admitted_Program__c WHERE Id IN :admittedProgramIds]);

		List<Nursing_Shift__c> newNursingShifts = [SELECT Id, Name, Date__c FROM Nursing_Shift__c WHERE Status__c = :NEW_STATUS LIMIT :Limits.getLimitQueryRows()];

		Set<Id> patientIdsForAPSUpdates = new Set<Id>();
		for (Admitted_Program_Status__c aps : admittedProgramStatuses) {
			if (admittedProgramsByIdMap.containsKey(aps.Admitted_Program__c)) {
				patientIdsForAPSUpdates.add(admittedProgramsByIdMap.get(aps.Admitted_Program__c).Admission__r.Patient_Account__c);
			}
		}

		Set<Id> nursingShiftIds = new Set<Id>();
		for (Nursing_Shift__c shift : newNursingShifts) {
			nursingShiftIds.add(shift.Id);
		}

		List<Nursing_Shift_Item__c> nursingShiftItemsWithFormsForPatientsInNewShifts = [SELECT Id, Form__c, Form__r.disco__Form_Template__c, Nursing_Shift__c, Nursing_Shift__r.Date__c, Patient__c, Status__c FROM Nursing_Shift_Item__c WHERE Patient__c IN :patientIdsForAPSUpdates AND Nursing_Shift__c IN :nursingShiftIds AND Form__c != NULL AND Form__r.disco__Form_Template__c = :DispensingService.PSAT_FORM_TEMPLATE.Id];

		List<Nursing_Shift_Item__c> nsisToDelete = new List<Nursing_Shift_Item__c>();
		List<disco__Form__c> formsToDelete = new List<disco__Form__c>();
		for (Nursing_Shift_Item__c nsi : nursingShiftItemsWithFormsForPatientsInNewShifts) {
			for (Admitted_Program_Status__c aps : admittedProgramStatuses) {
				if (aps.End_Date_Time__c.Date() < nsi.Nursing_Shift__r.Date__c) {
					formsToDelete.add(new disco__Form__c(Id = nsi.Form__c));
					nsisToDelete.add(nsi);
				}
			}
		}

		delete formsToDelete;
		delete nsisToDelete;
	}
}
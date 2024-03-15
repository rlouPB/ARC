public with sharing class DailyNursingShiftBatch implements Database.Batchable<sObject> {
	private static final String ADMITTED_PAS_STATUS = 'Program Assessment Status (PAS)';
	private static final String OPEN_STATUS = 'Open';
	public static Date today {
		get {
			if (today == null) {
				today = system.today();
			}
			return today;
		}
		set;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator('SELECT Id, Current_Admission__c, Current_Admission__r.In_PAS__c, Current_Admission__r.Current_Admitted_Program__r.Program__r.Product_Code__c, Current_Admission__r.Current_Admitted_Program__c, Patient_Contact__c from Account WHERE Current_Admission__r.Stage__c = \'Admitted\' AND Service_Type__c = \'Residential\' AND Current_Admission__r.Current_Admitted_Program__r.Program__r.Product_Code__c != null');
	}

	public void execute(Database.BatchableContext bc, List<Account> scope) {
		Nursing_Shift__c[] toInsert = new List<Nursing_Shift__c>{};
		Nursing_Shift__c[] shiftsForProcessing = new List<Nursing_Shift__c>{};
		Map<Id, Id> patientIdByNursingShiftMap = new Map<Id, Id>();

		Account[] patients = scope;

		for (integer i = 0; i < 3; i++) {
			date currentDate = today.addDays(i);
			Nursing_Shift__c[] shifts = [SELECT Id, Shift_Number__c, Date__c, Status__c, Type_of_Day__c FROM Nursing_Shift__c WHERE Date__c = :currentDate];
			string typeOfday = getTypeOfDay(today.addDays(i));

			//Asumption: If there's a shift in a targeted date, it is assumed that it was created manually, and no mote shifts in that day will be created
			if (shifts.size() == 0) {
				toInsert.addAll(new List<Nursing_Shift__c>{ new Nursing_Shift__c(Shift_Number__c = '1st', Date__c = today.addDays(i), Status__c = 'New', Type_of_Day__c = typeOfday), new Nursing_Shift__c(Shift_Number__c = '2nd', Date__c = today.addDays(i), Status__c = 'New', Type_of_Day__c = typeOfday), new Nursing_Shift__c(Shift_Number__c = '3rd', Date__c = today.addDays(i), Status__c = 'New', Type_of_Day__c = typeOfday) });
			} else {
				shiftsForProcessing.addAll(shifts);
			}
		}

		if (toInsert.size() > 0) {
			insert toInsert;
			shiftsForProcessing.addAll(toInsert);
		}

		if (shiftsForProcessing.size() > 0) {
			Nursing_Shift_Patient_Assignment__c[] patientAssignments = new List<Nursing_Shift_Patient_Assignment__c>{};

			Set<Id> nsIds = new Set<Id>();
			Set<Id> patientIds = new Set<Id>();
			for (Nursing_Shift__c ns : shiftsForProcessing) {
				nsIds.add(ns.Id);
			}
			for (Account p : patients) {
				patientIds.add(p.Id);
			}
			Nursing_Shift_Patient_Assignment__c[] existingPatientAssignments = [SELECT Id, Patient__c, Nursing_Shift__c FROM Nursing_Shift_Patient_Assignment__c WHERE Patient__c IN :patientIds AND Nursing_Shift__c IN :nsIds];
			Map<String, Nursing_Shift_Patient_Assignment__c> existingPatientAssignmentsByKey = new Map<String, Nursing_Shift_Patient_Assignment__c>();
			for (Nursing_Shift_Patient_Assignment__c nspa : existingPatientAssignments) {
				existingPatientAssignmentsByKey.put(nspa.Patient__c + '_' + nspa.Nursing_Shift__c, nspa);
			}

			Id Custom_Note_RecordtypeId = Schema.SObjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName().get('Custom_Note').getRecordtypeId();

			Patient_Note__c[] patientNotes = new List<Patient_Note__c>{};
			Map<Id, Patient_Note__c[]> patientNotesByNursingShiftIdMap = new Map<Id, Patient_Note__c[]>();
			List<Nursing_Shift_Item__c> psatNursingShiftItems = new List<Nursing_Shift_Item__c>();
			List<disco__Form__c> psatForms = new List<disco__Form__c>();
			Map<String, disco__Form__c> discoFormsByPatientIdAndShiftIdKey = new Map<String, disco__Form__c>();

			for (Nursing_Shift__c ns : shiftsForProcessing) {
				patientNotesByNursingShiftIdMap.put(ns.Id, new List<Patient_Note__c>{});

				// Checking for PAS and adding a PSAT form and NSI if needed. I know performing a query and DML statement in a
				// for loop is not a best practice but we are guanranteed to only loop 3 times.
				List<Admitted_Program_Status__c> pasProgramStatus = [SELECT Id, Admitted_Program__c, Admitted_Program__r.Admission__r.Patient_Account__c FROM Admitted_Program_Status__c WHERE Start_Date_Time__c <= :ns.Date__c AND End_Date_Time__c >= :ns.Date__c AND Status__c = :ADMITTED_PAS_STATUS];
				Map<Id, Admitted_Program_Status__c> admittedProgramStatusByPatientIdMap = new Map<Id, Admitted_Program_Status__c>();
				for (Admitted_Program_Status__c aps : pasProgramStatus) {
					admittedProgramStatusByPatientIdMap.put(aps.Admitted_Program__r.Admission__r.Patient_Account__c, aps);
				}

				for (Account acc : patients) {
					// Now that this is batch interface we need to ensure we didn't already process the patient for the given shift.
					if (existingPatientAssignmentsByKey.containsKey(acc.Id + '_' + ns.Id)) {
						continue;
					}

					patientIdByNursingShiftMap.put(acc.Id, ns.Id);
					patientAssignments.add(new Nursing_Shift_Patient_Assignment__c(Nursing_Shift__c = ns.Id, Patient__c = acc.Id, Status__c = 'Open'));

					if (acc?.Current_Admission__r?.In_PAS__c == true || 'IRP-N;IRP-Ne;VHP;VHP-e'.split(';').contains(acc?.Current_Admission__r?.Current_Admitted_Program__r?.Program__r?.Product_Code__c)) {
						Patient_Note__c pn = new Patient_Note__c(Account__c = acc.Id, Admission__c = acc.Current_Admission__c, Type__c = 'Nursing Process Note', RecordTypeId = Custom_Note_RecordtypeId, Nursing_Shift__c = ns.Id, Contact_Date__c = ns.Date__c);
						patientNotesByNursingShiftIdMap.get(ns.Id).add(pn);
						patientNotes.add(pn);
					} else if ('2nd,3rd'.split(',').contains(ns.Shift_Number__c) && (acc?.Current_Admission__r?.In_PAS__c == true || 'IRP-G;IRP-Ge'.split(';').contains(acc?.Current_Admission__r?.Current_Admitted_Program__r?.Program__r?.Product_Code__c))) {
						Patient_Note__c pn = new Patient_Note__c(Account__c = acc.Id, Admission__c = acc.Current_Admission__c, Type__c = 'Nursing Process Note', RecordTypeId = Custom_Note_RecordtypeId, Nursing_Shift__c = ns.Id, Contact_Date__c = ns.Date__c);
						patientNotesByNursingShiftIdMap.get(ns.Id).add(pn);
						patientNotes.add(pn);
					}

					// Check if this patient will be in PAS for the given shift.
					if (admittedProgramStatusByPatientIdMap.containsKey(acc.Id)) {
						disco__Form__c form = new disco__Form__c(disco__Form_Account__c = acc.Id, disco__Form_Template__c = DispensingService.PSAT_FORM_TEMPLATE.Id, disco__Form_Contact__c = acc.Patient_Contact__c, Admission__c = acc.Current_Admission__c);
						String key = acc.Id + '_' + ns.Id;
						discoFormsByPatientIdAndShiftIdKey.put(key, form);

						psatNursingShiftItems.add(new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id, Status__c = OPEN_STATUS, Patient__c = acc.Id));
					}
				}
			}

			if (!discoFormsByPatientIdAndShiftIdKey.isEmpty()) {
				insert discoFormsByPatientIdAndShiftIdKey.values();
			}

			if (psatNursingShiftItems.size() > 0) {
				for (Nursing_Shift_Item__c nsi : psatNursingShiftItems) {
					String key = nsi.Patient__c + '_' + nsi.Nursing_Shift__c;
					nsi.Form__c = discoFormsByPatientIdAndShiftIdKey.get(key).Id;
				}
				insert psatNursingShiftItems;
			}

			if (patientAssignments.size() > 0) {
				insert patientAssignments;
			}

			if (patientNotes.size() > 0) {
				insert patientNotes;
			}

			Nursing_Shift_Item__c[] items = new List<Nursing_Shift_Item__c>{};

			for (Id nsId : patientNotesByNursingShiftIdMap.keyset()) {
				for (Patient_Note__c pn : patientNotesByNursingShiftIdMap.get(nsId)) {
					items.add(new Nursing_Shift_Item__c(Patient__c = pn.Account__c, Patient_Note__c = pn.Id, Nursing_Shift__c = nsId, Item_Name__c = 'Nursing Process Note'));
				}
			}

			if (items.size() > 0) {
				insert items;
			}
		}

		processLeftOverShiftItems();
	}

	public void finish(Database.BatchableContext bc) {
	}

	public static void processLeftOverShiftItems() {
		Set<Date> dates = new Set<Date>();
		String[] numbers = '1st;2nd;3rd'.split(';');
		Nursing_Shift_Item__c[] nsiToUpdate = new List<Nursing_Shift_Item__c>{};

		Map<Id, Nursing_Shift_Item__c> nsiMap = new Map<Id, Nursing_Shift_Item__c>([SELECT Id, Shift_Date__c, Shift_Number__c FROM Nursing_Shift_Item__c WHERE Nursing_Shift__c = NULL AND Shift_Date__c != NULL AND Shift_Number__c IN :numbers]);

		if (nsiMap.isEmpty())
			return;

		for (Nursing_Shift_Item__c nsi : nsiMap.values())
			dates.add(nsi.Shift_Date__c);

		Map<Id, Nursing_Shift__c> nsMap = new Map<Id, Nursing_Shift__c>([SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c WHERE Date__c IN :dates AND Shift_Number__c IN :numbers AND Status__c IN ('New', 'Open')]);

		if (nsMap.isEmpty())
			return;

		Nursing_Shift__c[] nsList = nsMap.values();

		for (Nursing_Shift_Item__c nsi : nsiMap.values()) {
			Nursing_Shift__c nsFound = getNursingShiftFromList(nsList, nsi.Shift_Date__c, nsi.Shift_Number__c);
			if (nsFound != null) {
				nsiToUpdate.add(new Nursing_Shift_Item__c(Id = nsi.Id, Nursing_Shift__c = nsFound.Id));
			}
		}

		if (nsiToUpdate.size() > 0) {
			update nsiToUpdate;
		}
	}

	public static string getTypeOfDay(Date day) {
		if ([SELECT COUNT() FROM Holiday WHERE ActivityDate = :day] > 0) {
			return 'Holiday';
		} else if ('Sat;Sun'.split(';').contains(DateTime.newInstance(day, Time.newInstance(1, 0, 0, 0)).format('E'))) {
			return 'Weekend';
		}
		return 'Weekday';
	}

	public static Nursing_Shift__c getNursingShiftFromList(Nursing_Shift__c[] nsList, Date nsDate, String nsNumber) {
		for (Nursing_Shift__c ls : nsList) {
			if (ls.Date__c == nsDate && ls.Shift_Number__c == nsNumber) {
				return ls;
			}
		}
		return null;
	}
}
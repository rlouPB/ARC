public with sharing class SIP_DailyNursingShifts implements SystemScheduling.ScheduledItemProcessor {
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

	public static void process(List<Scheduled_Item_Definition__mdt> scheduledItemDefs) {
		Map<String, Scheduled_Item_Run__c> scheduledRunByDefinitionID = new Map<String, Scheduled_Item_Run__c>();
		try {
			Set<Id> scheduledDefIds = new Map<Id, Scheduled_Item_Definition__mdt>(scheduledItemDefs).keySet();

			List<Scheduled_Item_Run__c> scheduledRuns = SystemScheduling.queryScheduledItemRuns(scheduledDefIds);

			for (Scheduled_Item_Run__c currentRun : scheduledRuns) {
				scheduledRunByDefinitionID.put(currentRun.Scheduled_Item_Def__c, currentRun);
			}

			for (Scheduled_Item_Definition__mdt currentDef : scheduledItemDefs) {
				Scheduled_Item_Run__c relatedRun = scheduledRunByDefinitionID.get(currentDef.ID);
				if (relatedRun == null) {
					relatedRun = new Scheduled_Item_Run__c(Name = currentDef.MasterLabel, Scheduled_Item_Def__c = currentDef.ID, Scheduled_Item_Def_Status__c = 'Inactive', Retry_Count__c = 0);

					scheduledRunByDefinitionID.put(currentDef.ID, relatedRun);
				} else {
					// if (relatedRun.Scheduled_Item_Def_Status__c == 'Active') { relatedRun.Scheduled_Item_Def_Status__c = 'Inactive'; }

					//if Next_Run_Datetime__c is null on the Run record,
					if (relatedRun.Next_Run_Datetime__c == null || relatedRun.Next_Run_Datetime__c < System.now()) {
						relatedRun.Next_Run_Datetime__c = null;
					}
				}

				try {
					// main processing here, nothing for Prototype
					//MainProcessorClass.runMyJob();
					if (relatedRun.Next_Run_Datetime__c <= DateTime.now() && 'Active' == relatedRun.Scheduled_Item_Def_Status__c) {
						processLogic();
						Date tomorrow = today.addDays(1);
						relatedRun.Next_Run_Datetime__c = DateTime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day(), 0, 0, 0);
						//On success, clear out the retry fields
						relatedRun.Retry_Count__c = 0;
						relatedRun.Retry_Detail__c = null;
					}
				} catch (Exception ex) {
					relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
					relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
					ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
				}
				// relatedRun.Scheduled_Item_Def_Status__c = 'Active';
			}

			upsert scheduledRunByDefinitionID.values();
		} catch (Exception ex) {
			for (Scheduled_Item_Run__c relatedRun : scheduledRunByDefinitionID.values()) {
				relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
				relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
			}
			upsert scheduledRunByDefinitionID.values();
			ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
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

	public static void processLogic() {
		Nursing_Shift__c[] toInsert = new List<Nursing_Shift__c>{};
		Map<Id, Id> patientIdByNursingShiftMap = new Map<Id, Id>();

		Account[] patients = [SELECT Id, Current_Admission__c, Current_Admission__r.In_PAS__c, Current_Admission__r.Current_Admitted_Program__r.Program__r.Product_Code__c, Current_Admission__r.Current_Admitted_Program__c, Patient_Contact__c FROM Account WHERE Current_Admission__r.Stage__c = 'Admitted' AND Service_Type__c = 'Residential' AND Current_Admission__r.Current_Admitted_Program__r.Program__r.Product_Code__c != NULL];

		for (integer i = 0; i < 3; i++) {
			date currentDate = today.addDays(i);
			Nursing_Shift__c[] shifts = [SELECT Id FROM Nursing_Shift__c WHERE Date__c = :currentDate];
			string typeOfday = getTypeOfDay(today.addDays(i));
			//Asumption: If there's a shit in a targeted date, it is assumed that it was created manually, and no mote shifts in that day will be created
			if (shifts.size() == 0) {
				toInsert.addAll(new List<Nursing_Shift__c>{ new Nursing_Shift__c(Shift_Number__c = '1st', Date__c = today.addDays(i), Status__c = 'New', Type_of_Day__c = typeOfday), new Nursing_Shift__c(Shift_Number__c = '2nd', Date__c = today.addDays(i), Status__c = 'New', Type_of_Day__c = typeOfday), new Nursing_Shift__c(Shift_Number__c = '3rd', Date__c = today.addDays(i), Status__c = 'New', Type_of_Day__c = typeOfday) });
			}
		}

		if (toInsert.size() > 0) {
			insert toInsert;

			Nursing_Shift_Patient_Assignment__c[] patientAssignments = new List<Nursing_Shift_Patient_Assignment__c>{};

			/*
            1 Nursing Process Note required every shift for patients in IRP-N,Ne, VHP, VHPe or using PAS. This info is found on the
            Account.Current_Admitted_Program_Name__c. The In PAS? is found on Account -> Current Admission -> In_PAS__c

            1 note required for day and evening shift (not night) for patients in IRP-G, Ge

            When creating the Note (Patient_Note__c) we will set the following fields:
                Account__c
                Admission__c
                Type__c = 'Nursing Process Note'
                RecordTypeId = ID for record type of Custom_Note

            We will also create a corresponding Nursing_Shift_Item__c with the following fields:
                Nursing_Shift__c
                Patient_Note__c
                Item_Name__c = 'Nursing Process Note'

            */
			Id Custom_Note_RecordtypeId = Schema.SObjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName().get('Custom_Note').getRecordtypeId();

			Patient_Note__c[] patientNotes = new List<Patient_Note__c>{};
			Map<Id, Patient_Note__c[]> patientNotesByNursingShiftIdMap = new Map<Id, Patient_Note__c[]>();
			List<Nursing_Shift_Item__c> psatNursingShiftItems = new List<Nursing_Shift_Item__c>();
			List<disco__Form__c> psatForms = new List<disco__Form__c>();
			Map<String, disco__Form__c> discoFormsByPatientIdAndShiftIdKey = new Map<String, disco__Form__c>();

			for (Nursing_Shift__c ns : toInsert) {
				patientNotesByNursingShiftIdMap.put(ns.Id, new List<Patient_Note__c>{});

				// Checking for PAS and adding a PSAT form and NSI if needed. I know performing a query and DML statement in a
				// for loop is not a best practice but we are guanranteed to only loop 3 times.
				List<Admitted_Program_Status__c> pasProgramStatus = [SELECT Id, Admitted_Program__c, Admitted_Program__r.Admission__r.Patient_Account__c FROM Admitted_Program_Status__c WHERE Start_Date_Time__c <= :ns.Date__c AND End_Date_Time__c >= :ns.Date__c AND Status__c = :ADMITTED_PAS_STATUS];
				Map<Id, Admitted_Program_Status__c> admittedProgramStatusByPatientIdMap = new Map<Id, Admitted_Program_Status__c>();
				for (Admitted_Program_Status__c aps : pasProgramStatus) {
					admittedProgramStatusByPatientIdMap.put(aps.Admitted_Program__r.Admission__r.Patient_Account__c, aps);
				}

				for (Account acc : patients) {
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

	public static void processLeftOverShiftItems() {
		Set<Date> dates = new Set<Date>();
		String[] numbers = '1st;2nd;3rd'.split(';');
		Nursing_Shift_Item__c[] nsiToUpdate = new List<Nursing_Shift_Item__c>{};

		Map<Id, Nursing_Shift_Item__c> nsiMap = new Map<Id, Nursing_Shift_Item__c>([SELECT Id, Shift_Date__c, Shift_Number__c FROM Nursing_Shift_Item__c WHERE Nursing_Shift__c = NULL AND Shift_Date__c != NULL AND Shift_Number__c IN :numbers]);

		if (nsiMap.isEmpty())
			return;

		for (Nursing_Shift_Item__c nsi : nsiMap.values())
			dates.add(nsi.Shift_Date__c);

		Map<Id, Nursing_Shift__c> nsMap = new Map<Id, Nursing_Shift__c>([SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c WHERE Date__c IN :dates AND Shift_Number__c IN :numbers]);

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

	public static void processLeftOverShiftItemsFromTrigger(Nursing_Shift_Item__c[] nsiList) {
		Set<Date> dates = new Set<Date>();
		String[] numbers = '1st;2nd;3rd'.split(';');

		Map<String, Nursing_Shift_Item__c[]> nsiMap = new Map<String, Nursing_Shift_Item__c[]>();

		for (Nursing_Shift_Item__c nsi : nsiList) {
			if (nsi.Shift_Date__c != null && nsi.Shift_Number__c != null && nsi.Nursing_Shift__c == null) {
				String key = nsi.Shift_Number__c + '--' + nsi.Shift_Date__c.format();
				if (!nsiMap.containsKey(key)) {
					nsiMap.put(key, new List<Nursing_Shift_Item__c>{});
				}
				nsiMap.get(key).add(nsi);
				dates.add(nsi.Shift_Date__c);
				numbers.add(nsi.Shift_Number__c);
			}
		}

		if (nsiMap.isEmpty())
			return;

		Map<Id, Nursing_Shift__c> nsMap = new Map<Id, Nursing_Shift__c>([SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c WHERE Date__c IN :dates AND Shift_Number__c IN :numbers]);

		for (Nursing_Shift__c ns : nsMap.values()) {
			String key = ns.Shift_Number__c + '--' + ns.Date__c.format();
			if (nsiMap.containsKey(key)) {
				for (Nursing_Shift_Item__c nsi : nsiMap.get(key)) {
					nsi.Nursing_Shift__c = ns.Id;
				}
			}
		}
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
public without sharing class NursingShiftService {
	//fields required in query that are not specifically on the Nursing Shift object
	static Set<String> extraNursingShiftFields = new Set<String>{ 'Med_Nurse__r.Professional_Name__c', 'Charge_Nurse__r.Professional_Name__c', 'Backup_Med_Nurse__r.Professional_Name__c' };
	static Set<String> extraNursingShiftItemFields = new Set<String>{ 'Nursing_Shift_Assignment__r.Owner__c', 'Nursing_Shift_Assignment__r.Open_Shift_Items__c', 'Patient__r.Team__c', 'Patient__r.Current_Admitted_Program_Name__c', 'Patient__r.Current_Admission__r.In_PAS__c', 'Nurse__r.Professional_Name__c' };
	static List<Nursing_Shift__c> allNursingShifts { //lazy load
		get {
			if (allNursingShifts == null) {
				extraNursingShiftFields.add(QueryUtils.getSubQueryAll('Nursing_Shift_Item__c', 'Nursing_Shift_Items__r', new List<String>(extraNursingShiftItemFields), ''));
				String nursingShiftQueryString = QueryUtils.getQueryAll('Nursing_Shift__c', new List<String>(extraNursingShiftFields)) + ' ORDER BY Date__c ASC, Shift_Number__c ASC';
				allNursingShifts = (List<Nursing_Shift__c>) Database.query(nursingShiftQueryString);
			}
			return allNursingShifts;
		}
		private set;
	}

	static Map<String, List<Nursing_Shift__c>> nursingShiftsByStatusMap { //lazy load create map from allNursingShifts
		get {
			if (nursingShiftsByStatusMap == null) {
				nursingShiftsByStatusMap = new Map<String, List<Nursing_Shift__c>>();
				for (Nursing_Shift__c shift : allNursingShifts) {
					List<Nursing_Shift__c> shiftsForStatus = nursingShiftsByStatusMap.get(shift.Status__c);
					if (shiftsForStatus == null)
						shiftsForStatus = new List<Nursing_Shift__c>();
					shiftsForStatus.add(shift);
					nursingShiftsByStatusMap.put(shift.Status__c, shiftsForStatus);
				}
			}
			return nursingShiftsByStatusMap;
		}
		private set;
	}
	@AuraEnabled
	public static List<Nursing_Shift__c> getNursingShifts(List<String> statuses) {
		List<Nursing_Shift__c> nursingShifts = new List<Nursing_Shift__c>();
		for (String status : statuses) {
			if (nursingShiftsByStatusMap.containsKey(status)) {
				nursingShifts.addAll(nursingShiftsByStatusMap.get(status));
			}
		}
		// List<Nursing_Shift__c> nursingShifts = [
		//     SELECT
		//         Id,
		//         Name,
		//         Shift_Number__c,
		//         Shift__c,
		//         Status__c,
		//         Date__c,
		//         Med_Nurse__c,
		//         Med_Nurse__r.Professional_Name__c,
		//         Charge_Nurse__c,
		//         Charge_Nurse__r.Professional_Name__c,
		//         Backup_Med_Nurse__c,
		//         Backup_Med_Nurse__r.Professional_Name__c,
		//         Type_of_Day__c,
		//         Shift_Open_Date_Time__c,
		//         Shift_Closed_Date_Time__c,
		//         Scheduled_Start_Date_Time__c,
		//         Scheduled_Closed_Date_Time__c,
		//         (
		//             SELECT
		//                 Id,
		//                 Form__c,
		//                 Nursing_Shift_Assignment__c,Nursing_Shift_Assignment__r.Owner__c,
		//                 Nursing_Shift_Assignment__r.Open_Shift_Items__c,
		//                 Patient__c,
		//                 Patient__r.Team__c,Patient__r.Current_Admitted_Program_Name__c,
		//                 Patient__r.Current_Admission__r.In_PAS__c,
		//                 Nurse__r.Professional_Name__c,
		//                 Patient_Note__c,
		//                 Physical_Monitor__c,
		//                 Procedure_Order__c,
		//                 Status__c
		//             FROM Nursing_Shift_Items__r
		//         )
		//     FROM Nursing_Shift__c
		//     WHERE Status__c IN :statuses
		//     ORDER BY Date__c ASC, Shift_Number__c ASC
		// ];

		return nursingShifts;
	}
	@AuraEnabled
	public static Nursing_Shift__c getNursingShift(Date shiftDate, String shiftNumber) {
		Nursing_Shift__c returnShift;
		for (Nursing_Shift__c ns : allNursingShifts) {
			if (ns.Date__c == shiftDate && ns.Shift_Number__c == shiftNumber) {
				returnShift = ns;
			}
			if (ns.Date__c > shiftDate || returnShift == null) {
				break;
			}
		}
		// for(Nursing_Shift__c ns : [
		//     SELECT
		//         Id,
		//         Name,
		//         Shift_Number__c,
		//         Status__c,
		//         Date__c,
		//         Med_Nurse__c,
		//         Charge_Nurse__c,
		//         Backup_Med_Nurse__c,
		//         Type_of_Day__c,
		//         (
		//             SELECT
		//                 Id,
		//                 Form__c,
		//                 Nursing_Shift_Assignment__c,Nursing_Shift_Assignment__r.Owner__c,
		//                 Nursing_Shift_Assignment__r.Open_Shift_Items__c,
		//                 Patient__c,
		//                 Patient__r.Team__c,Patient__r.Current_Admitted_Program_Name__c,
		//                 Patient__r.Current_Admission__r.In_PAS__c,
		//                 Nurse__r.Professional_Name__c,
		//                 Patient_Note__c,
		//                 Physical_Monitor__c,
		//                 Procedure_Order__c,
		//                 Status__c
		//             FROM Nursing_Shift_Items__r
		//         )
		//     FROM Nursing_Shift__c
		//     WHERE Date__c = :shiftDate
		//     AND Shift_Number__c = :shiftNumber
		//     LIMIT 1
		// ]){
		//     return ns;
		// }
		// return null;
		return returnShift;
	}

	@AuraEnabled
	public static Nursing_Shift__c getNursingShiftSingle(string recordId) {
		for (Nursing_Shift__c ns : [SELECT Id, Name, Shift_Number__c, Status__c, Date__c, Med_Nurse__c, Charge_Nurse__c, Backup_Med_Nurse__c, Type_of_Day__c FROM Nursing_Shift__c WHERE Id = :recordId]) {
			return ns;
		}
		return null;
	}

	@AuraEnabled
	public static SearchResult[] SearchNurse(string SearchText, string SobjectType, string FieldName) {
		SearchResult[] results = new List<SearchResult>{};
		return results;
	}

	@AuraEnabled
	public static Nursing_Shift_Item__c[] getNursingShiftItems(id nursingShiftId) {
		return [
			SELECT
				Id,
				Form__c,
				Form__r.disco__Form_Template__r.DocType_Name__c,
				Item_Name__c,
				Due_Date__c,
				Patient__r.Id,
				Patient__r.Name,
				Procedure_Order__r.Name,
				Form__r.disco__Form_Template__r.Name,
				Nursing_Shift__c,
				Nursing_Shift__r.Shift__c,
				Nursing_Shift__r.Date__c,
				Nursing_Shift__r.Shift_Number__c,
				Nursing_Shift_Assignment__c,
				Nursing_Shift_Assignment__r.Owner__c,
				Nursing_Shift_Assignment__r.Open_Shift_Items__c,
				Patient__c,
				Patient__r.Team__c,
				Patient__r.Current_Admitted_Program_Name__c,
				Patient__r.Current_Admission__r.In_PAS__c,
				Patient__r.Current_Admission__r.Stage__c,
				Nurse__r.Professional_Name__c,
				Patient_Note__c,
				Physical_Monitor__c,
				Procedure_Order__c,
				Additional_Information__c,
				Status__c,
				DocTypeLabel__c
			FROM Nursing_Shift_Item__c
			WHERE Nursing_Shift__c = :nursingShiftId
		];
	}

	@AuraEnabled
	public static Nursing_Shift_Item__c[] getMyNursingShiftItems(id nursingShiftId) {
		return [
			SELECT
				Id,
				Form__c,
				Form__r.disco__Form_Template__r.DocType_Name__c,
				Item_Name__c,
				Due_Date__c,
				Patient__r.Id,
				Patient__r.Name,
				Procedure_Order__r.Name,
				Form__r.disco__Form_Template__r.Name,
				Nursing_Shift__c,
				Nursing_Shift__r.Shift__c,
				Nursing_Shift__r.Date__c,
				Nursing_Shift__r.Shift_Number__c,
				Nursing_Shift_Assignment__c,
				Nursing_Shift_Assignment__r.Owner__c,
				Nursing_Shift_Assignment__r.Open_Shift_Items__c,
				Patient__c,
				Patient__r.Team__c,
				Patient__r.Current_Admitted_Program_Name__c,
				Patient__r.Current_Admission__r.In_PAS__c,
				Patient__r.Current_Admission__r.Stage__c,
				Nurse__r.Professional_Name__c,
				Patient_Note__c,
				Physical_Monitor__c,
				Procedure_Order__c,
				Additional_Information__c,
				Status__c,
				DocTypeLabel__c
			FROM Nursing_Shift_Item__c
			WHERE Nursing_Shift__c = :nursingShiftId AND Nurse__c = :UserInfo.getUserId()
		];
	}

	@AuraEnabled
	public static Nursing_Shift_Item__c[] getNursingShiftPatientItems(id nursingShiftId) {
		return [
			SELECT
				Id,
				Form__c,
				Item_Name__c,
				Due_Date__c,
				Procedure_Order__c,
				Procedure_Order__r.Name,
				Form__r.disco__Form_Template__r.Name,
				Form__r.disco__Form_Template__r.DocType_Name__c,
				Nursing_Shift__c,
				Nursing_Shift__r.Shift__c,
				Nursing_Shift__r.Date__c,
				Nursing_Shift__r.Shift_Number__c,
				Nursing_Shift_Assignment__c,
				Nursing_Shift_Assignment__r.Owner__c,
				Nursing_Shift_Assignment__r.Open_Shift_Items__c,
				Patient__c,
				Patient__r.Name,
				Patient__r.Team__c,
				Patient__r.Current_Admitted_Program_Name__c,
				Patient__r.Current_Admission__r.In_PAS__c,
				Patient__r.Current_Admission__r.Stage__c,
				Nurse__r.Professional_Name__c,
				Patient_Note__c,
				Physical_Monitor__c,
				Status__c,
				Additional_Information__c,
				DocTypeLabel__c
			FROM Nursing_Shift_Item__c
			WHERE Nursing_Shift__c = :nursingShiftId AND Patient__c != NULL
		];
	}

	@AuraEnabled
	public static Nursing_Shift_Item__c[] getMyNursingShiftPatientItems(id nursingShiftId) {
		return [
			SELECT
				Id,
				Form__c,
				Item_Name__c,
				Due_Date__c,
				Procedure_Order__c,
				Procedure_Order__r.Name,
				Form__r.disco__Form_Template__r.Name,
				Form__r.disco__Form_Template__r.DocType_Name__c,
				Nursing_Shift__c,
				Nursing_Shift__r.Shift__c,
				Nursing_Shift__r.Date__c,
				Nursing_Shift__r.Shift_Number__c,
				Nursing_Shift_Assignment__c,
				Nursing_Shift_Assignment__r.Owner__c,
				Nursing_Shift_Assignment__r.Open_Shift_Items__c,
				Patient__c,
				Patient__r.Name,
				Patient__r.Team__c,
				Patient__r.Current_Admitted_Program_Name__c,
				Patient__r.Current_Admission__r.In_PAS__c,
				Patient__r.Current_Admission__r.Stage__c,
				Nurse__r.Professional_Name__c,
				Patient_Note__c,
				Physical_Monitor__c,
				Status__c,
				Additional_Information__c,
				DocTypeLabel__c
			FROM Nursing_Shift_Item__c
			WHERE Nursing_Shift__c = :nursingShiftId AND Patient__c != NULL AND Nurse__c = :UserInfo.getUserId()
		];
	}

	@AuraEnabled
	public static Nursing_Shift_Item__c[] getNursingShiftItemsForPatient(id accountId) {
		return [
			SELECT
				Id,
				Form__c,
				Item_Name__c,
				Due_Date__c,
				Shift_Date__c,
				Shift_Number__c,
				Shift_Index__c,
				Nursing_Shift__c,
				Nursing_Shift__r.Shift__c,
				Nursing_Shift__r.Date__c,
				Nursing_Shift__r.Shift_Number__c,
				Nursing_Shift_Assignment__c,
				Nursing_Shift_Assignment__r.Owner__c,
				Nursing_Shift_Assignment__r.Open_Shift_Items__c,
				Patient__c,
				Patient__r.Name,
				Patient__r.Team__c,
				Patient__r.Current_Admitted_Program_Name__c,
				Procedure_Order__r.Name,
				Form__r.disco__Form_Template__r.Name,
				Form__r.disco__Form_Template__r.DocType_Name__c,
				Patient__r.Current_Admission__r.In_PAS__c,
				Nurse__r.Professional_Name__c,
				Patient_Note__c,
				Physical_Monitor__c,
				Procedure_Order__c,
				Additional_Information__c,
				Status__c,
				DocTypeLabel__c
			FROM Nursing_Shift_Item__c
			WHERE Patient__c = :accountId
		];
	}

	@AuraEnabled
	public static Nursing_Shift_Item__c[] getMyNursingShiftItemsForPatient(id accountId) {
		return [
			SELECT
				Id,
				Form__c,
				Item_Name__c,
				Due_Date__c,
				Shift_Date__c,
				Shift_Number__c,
				Shift_Index__c,
				Nursing_Shift__c,
				Nursing_Shift__r.Shift__c,
				Nursing_Shift__r.Date__c,
				Nursing_Shift__r.Shift_Number__c,
				Nursing_Shift_Assignment__c,
				Nursing_Shift_Assignment__r.Owner__c,
				Nursing_Shift_Assignment__r.Open_Shift_Items__c,
				Patient__c,
				Patient__r.Name,
				Patient__r.Team__c,
				Patient__r.Current_Admitted_Program_Name__c,
				Procedure_Order__r.Name,
				Form__r.disco__Form_Template__r.Name,
				Form__r.disco__Form_Template__r.DocType_Name__c,
				Patient__r.Current_Admission__r.In_PAS__c,
				Nurse__r.Professional_Name__c,
				Patient_Note__c,
				Physical_Monitor__c,
				Procedure_Order__c,
				Additional_Information__c,
				Status__c,
				DocTypeLabel__c
			FROM Nursing_Shift_Item__c
			WHERE Patient__c = :accountId AND Nurse__c = :UserInfo.getUserId()
		];
	}

	@AuraEnabled
	public static Nursing_Shift_Item__c getNursingShiftItem(Id nursingShiftItemId) {
		return [
			SELECT
				Id,
				Form__c,
				Item_Name__c,
				Due_Date__c,
				Shift_Date__c,
				Shift_Number__c,
				Shift_Index__c,
				Form__r.disco__Form_Template__r.Name,
				Procedure_Order__r.Name,
				Nursing_Shift__c,
				Nursing_Shift__r.Shift__c,
				Nursing_Shift__r.Date__c,
				Nursing_Shift__r.Shift_Number__c,
				Nursing_Shift_Assignment__c,
				Nursing_Shift_Assignment__r.Owner__c,
				Nursing_Shift_Assignment__r.Open_Shift_Items__c,
				Patient__c,
				Patient__r.Team__c,
				Patient__r.Current_Admitted_Program_Name__c,
				Patient__r.Current_Admission__r.In_PAS__c,
				Nurse__r.Professional_Name__c,
				Patient_Note__c,
				Physical_Monitor__c,
				Procedure_Order__c,
				Status__c
			FROM Nursing_Shift_Item__c
			WHERE Id = :nursingShiftItemId
			LIMIT 1
		];
	}

	@AuraEnabled
	public static Nursing_Shift_Assignment__c[] getMyNursingShiftAssigments() {
		Id userId = UserInfo.getUserId();
		return [SELECT Id, Nursing_Shift__c, Nursing_Shift__r.Shift__c, Nursing_Shift__r.Date__c, Nursing_Shift__r.Shift_Number__c FROM Nursing_Shift_Assignment__c WHERE Owner__c = :userId AND Nursing_Shift__c != NULL AND Status__c = 'Open'];
	}

	@AuraEnabled
	public static Nursing_Shift_Assignment__c[] getAllNursingShiftAssigments() {
		Id userId = UserInfo.getUserId();
		return [SELECT Id, Nursing_Shift__c, Nursing_Shift__r.Shift__c, Nursing_Shift__r.Date__c, Nursing_Shift__r.Shift_Number__c FROM Nursing_Shift_Assignment__c WHERE Sign_Out_Date_Time__c = NULL AND Owner__c = :userId AND Nursing_Shift__c != NULL];
	}

	@AuraEnabled
	public static Nursing_Shift_Assignment__c[] getNursingShiftAssigments(Id nursingShiftId, string searchText) {
		Datetime now = System.now();
		string likeSearch = string.isNotBlank(searchText) ? '%' + searchText + '%' : null;
		string query = 'SELECT  Id, Name, Owner__r.Name FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :nursingShiftId AND ';
		if (string.isNotBlank(searchText)) {
			query += ' Owner__r.Name LIKE :likeSearch AND ';
		}
		query += '(Sign_Out_Date_Time__c = null OR Sign_Out_Date_Time__c < :now)';

		return (Nursing_Shift_Assignment__c[]) Database.query(query);
	}

	@AuraEnabled
	public static string setNSAId(Id[] nursingPatientIds, Id nursingShiftAssignmentId) {
		try {
			Nursing_Shift_Patient_Assignment__c[] toUpdate = new List<Nursing_Shift_Patient_Assignment__c>{};
			for (Id npid : nursingPatientIds) {
				toUpdate.add(new Nursing_Shift_Patient_Assignment__c(Id = npid, Nursing_Shift_Assignment__c = nursingShiftAssignmentId));
			}
			update toUpdate;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
		return null;
	}

	@AuraEnabled
	public static string setShiftAssignedToUser(Id[] nspaIds, Id userId, Id nursingShiftId) {
		try {
			Nursing_Shift_Assignment__c nsaToUpsert;
			Nursing_Shift_Patient_Assignment__c[] nspaToUpdateList = new List<Nursing_Shift_Patient_Assignment__c>{};

			//Gathering NSPA map
			Map<Id, Nursing_Shift_Patient_Assignment__c> nspaMap = new Map<Id, Nursing_Shift_Patient_Assignment__c>([SELECT Id, Patient__c, Nursing_Shift_Assignment__c FROM Nursing_Shift_Patient_Assignment__c WHERE Nursing_Shift__c = :nursingShiftId AND Patient__c != NULL]);

			//Calculate Nurse/NursingShift
			Map<Id, Nursing_Shift_Assignment__c> nsaMap = new Map<Id, Nursing_Shift_Assignment__c>([SELECT Id, Owner__c, Status__c, Sign_In_Date_Time__c, Sign_Out_Date_Time__c FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :nursingShiftId]);

			Map<Id, Nursing_Shift_Assignment__c> nurseIdToAssignmentMap = new Map<Id, Nursing_Shift_Assignment__c>();
			for (Nursing_Shift_Assignment__c nsa : nsaMap.values()) {
				//There will only be one by user/patient/nursingShift
				if (!nurseIdToAssignmentMap.containsKey(nsa.Owner__c)) {
					nurseIdToAssignmentMap.put(nsa.Owner__c, nsa);
				}
			}

			if (nurseIdToAssignmentMap.containsKey(userId)) {
				Nursing_Shift_Assignment__c nsa = nurseIdToAssignmentMap.get(userId);
				nsaToUpsert = new Nursing_Shift_Assignment__c(
					Id = nsa.Id,
					Status__c = 'Open'
					//Sign_In_Date_Time__c= System.now()
				);
				update nsaToUpsert;
			} else {
				nsaToUpsert = new Nursing_Shift_Assignment__c(Owner__c = userId, OwnerId = userId, Nursing_Shift__c = nursingShiftId, Sign_In_Date_Time__c = System.now(), Status__c = 'Open');

				insert nsaToUpsert;

				nurseIdToAssignmentMap.put(userId, nsaToUpsert);
			}

			for (Id nspaId : nspaIds) {
				if (nspaMap.containsKey(nspaId)) {
					Nursing_Shift_Patient_Assignment__c nspa = nspaMap.get(nspaId);
					nspaToUpdateList.add(new Nursing_Shift_Patient_Assignment__c(Id = nspa.Id, Shift_Assigned_To__c = userId, Nursing_Shift_Assignment__c = nsaToUpsert.Id, Status__c = 'Open'));
				}
			}

			if (nspaToUpdateList.size() > 0) {
				update nspaToUpdateList;

				Set<Id> nsaIds = new Set<Id>();
				for (Nursing_Shift_Patient_Assignment__c nsa : nspaToUpdateList) {
					if (nsa.Nursing_Shift_Assignment__c != null) {
						nsaIds.add(nsa.Nursing_Shift_Assignment__c);
					}
				}
				Nursing_Shift__c[] nursingShiftsToOpen = new List<Nursing_Shift__c>{};
				for (Nursing_Shift_Assignment__c nsa : [SELECT Id, Nursing_Shift__c FROM Nursing_Shift_Assignment__c WHERE Id IN :nsaIds AND Nursing_Shift__c != NULL AND Nursing_Shift__r.Status__c != 'Open']) {
					nursingShiftsToOpen.add(new Nursing_Shift__c(Id = nsa.Nursing_Shift__c, Status__c = 'Open', Shift_Open_Date_Time__c = System.now()));
				}

				if (nursingShiftsToOpen.size() > 0) {
					update nursingShiftsToOpen;
				}
			}

			// //Update nursing shift items related to the patientsassignments
			// Set<Id> updatedNsaIds = new Map<Id,Nursing_Shift_Assignment__c>(nurseIdToAssignmentMap.values()).keyset();
			// Nursing_Shift_Item__c[] nsiIntialList = [
			//     SELECT Id FROM Nursing_Shift_Item__c
			//     WHERE Nursing_Shift__c=:nursingShiftId AND
			//     Nursing_Shift_Assignment__c in :updatedNsaIds AND
			//     Nurse__c != :userId
			// ];
			// if ( nsiIntialList.size() > 0 ){
			//     Nursing_Shift_Item__c[] itemsToUpdate = new Nursing_Shift_Item__c[]{};
			//     for (Nursing_Shift_Item__c nsi : nsiIntialList ){
			//         itemsToUpdate.add(new Nursing_Shift_Item__c(Id=nsi.Id, Nurse__c=userId));
			//     }
			//     update itemsToUpdate;
			// }

			// Update nursing shift items related to the patients. Also,
			// if the Nursing Shift Item is for a Patient Note, change the owner of the Patient Note to the nurse.
			set<Id> patientIds = new Set<Id>();
			for (Nursing_Shift_Patient_Assignment__c nspa : [SELECT Patient__c FROM Nursing_Shift_Patient_Assignment__c WHERE Id IN :nspaIds AND Patient__c != NULL]) {
				patientIds.add(nspa.Patient__c);
			}
			Nursing_Shift_Item__c[] nsiIntialList = [SELECT Id, Patient__c, Patient_Note__c FROM Nursing_Shift_Item__c WHERE Nursing_Shift__c = :nursingShiftId AND Patient__c IN :patientIds AND Nurse__c != :userId];
			if (nsiIntialList.size() > 0) {
				Nursing_Shift_Item__c[] itemsToUpdate = new List<Nursing_Shift_Item__c>{};
				Patient_Note__c[] patientNotesToUpdate = new List<Patient_Note__c>{};
				for (Nursing_Shift_Item__c nsi : nsiIntialList) {
					itemsToUpdate.add(new Nursing_Shift_Item__c(Id = nsi.Id, Nurse__c = userId, Nursing_Shift_Assignment__c = nurseIdToAssignmentMap.get(userId).Id));

					if (null != nsi.Patient_Note__c) {
						patientNotesToUpdate.add(new Patient_Note__c(Id = nsi.Patient_Note__c, OwnerId = userId));
					}
				}
				update itemsToUpdate;

				if (patientNotesToUpdate.size() > 0)
					update patientNotesToUpdate;
			}
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
		return null;
	}

	/**
	 * Need: Only 1 Nursing_Shift_Patient_Assignment__c/userId/PatientId/nursingShiftId
	 * Need: Only 1 Nursing_Shift_Assignment__c/nursingShiftId/NurseId
	 */
	@AuraEnabled
	public static string setShiftAssignedToUser_depricated(Id[] nursingPatientIds, Id userId, Id nursingShiftId) {
		try {
			Map<Id, Nursing_Shift_Patient_Assignment__c> nspaToUpdateMap = new Map<Id, Nursing_Shift_Patient_Assignment__c>();
			Map<Id, Nursing_Shift_Assignment__c[]> nsaListByUserIdMap = new Map<Id, Nursing_Shift_Assignment__c[]>();
			Map<Id, Nursing_Shift_Assignment__c[]> nsaListMapByUserId = new Map<Id, Nursing_Shift_Assignment__c[]>();

			Map<Id, Nursing_Shift_Assignment__c> assignmentsToUpdateMap = new Map<Id, Nursing_Shift_Assignment__c>();

			Map<Id, Nursing_Shift_Assignment__c> nsaMap = new Map<Id, Nursing_Shift_Assignment__c>([SELECT Id, Owner__c, Status__c, Sign_In_Date_Time__c, Sign_Out_Date_Time__c FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :nursingShiftId]);

			for (Nursing_Shift_Assignment__c nsa : nsaMap.values()) {
				if (!nsaListByUserIdMap.containsKey(nsa.Owner__c)) {
					nsaListByUserIdMap.put(nsa.Owner__c, new List<Nursing_Shift_Assignment__c>{});
				}
				nsaListByUserIdMap.get(nsa.Owner__c).add(nsa);

				if (!nsaListMapByUserId.containsKey(nsa.Owner__c)) {
					nsaListMapByUserId.put(nsa.Owner__c, new List<Nursing_Shift_Assignment__c>{});
				}
				nsaListMapByUserId.get(nsa.Owner__c).add(nsa);
			}

			for (Id npid : nursingPatientIds) {
				if (nsaListByUserIdMap.containsKey(userId)) {
					for (Nursing_Shift_Assignment__c nsa : nsaListByUserIdMap.get(userId)) {
						if (!nspaToUpdateMap.containsKey(npid)) {
							nspaToUpdateMap.put(npid, new Nursing_Shift_Patient_Assignment__c(Id = npid));
						}
						Nursing_Shift_Patient_Assignment__c nspaToUpdate = nspaToUpdateMap.get(npid);
						nspaToUpdate.Shift_Assigned_To__c = userId;
						nspaToUpdate.Nursing_Shift_Assignment__c = nsa.Id;
						nspaToUpdate.Shift_Assigned_To__c = userId;
						nspaToUpdate.Status__c = 'Open';

						// if ( !assignmentsToUpdateMap.containsKey(nsa.Id) ) { assignmentsToUpdateMap.put(nsa.Id, new Nursing_Shift_Assignment__c(Id=nsa.Id)); }
						// Nursing_Shift_Assignment__c nsaToUpdate = assignmentsToUpdateMap.get(nsa.Id);
						// nsaToUpdate.Owner__c = userId;
						// nsaToUpdate.Sign_In_Date_Time__c = system.now();
						// nsaToUpdate.Sign_Out_Date_Time__c = null;
						// nsaToUpdate.Status__c='Open';
					}
				} else {
					//Note: This part needs improvement, potential 101 queries exception
					Nursing_Shift_Assignment__c nsa = new Nursing_Shift_Assignment__c(Owner__c = userId, OwnerId = userId, Nursing_Shift__c = nursingShiftId, Sign_In_Date_Time__c = System.now(), Sign_Out_Date_Time__c = null, Status__c = 'Open');
					insert nsa; // We will only ever do one insert per transaction.

					if (!nsaListByUserIdMap.containsKey(userId)) {
						nsaListByUserIdMap.put(userId, new List<Nursing_Shift_Assignment__c>{});
					}
					nsaListByUserIdMap.get(userId).add(nsa);

					if (!nspaToUpdateMap.containsKey(npid)) {
						nspaToUpdateMap.put(npid, new Nursing_Shift_Patient_Assignment__c(Id = npid));
					}
					Nursing_Shift_Patient_Assignment__c nspaToUpdate = nspaToUpdateMap.get(npid);
					nspaToUpdate.Shift_Assigned_To__c = userId;
					nspaToUpdate.Nursing_Shift_Assignment__c = nsa.Id;
					nspaToUpdate.Status__c = 'Open';
				}
			}

			if (assignmentsToUpdateMap.size() > 0) {
				update assignmentsToUpdateMap.values();
			}

			if (nspaToUpdateMap.size() > 0) {
				update nspaToUpdateMap.values();
			}
		} catch (Exception ex) {
			string message = ex.getMessage() + ' - ' + ex.getStackTraceString();
			for (User u : [SELECT profile.name FROM user WHERE id = :userinfo.getUserId() LIMIT 1]) {
				if (u.profile.name.toLowerCase().contains('admin')) {
					message += ' - ' + ex.getStackTraceString();
				}
			}
			return message;
		}
		return null;
	}

	@AuraEnabled
	public static string signIntoShift(Id shiftId) {
		try {
			Nursing_Shift_Assignment__c[] nsaList = [SELECT Id FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :shiftId AND Owner__c = :UserInfo.getuserid() ORDER BY CreatedDate ASC LIMIT 1];
			Nursing_Shift_Assignment__c toUpsert = new Nursing_Shift_Assignment__c(Nursing_Shift__c = shiftId, Status__c = 'Open', Owner__c = userinfo.getUserId(), Sign_In_Date_Time__c = System.now());
			if (!nsaList.isEmpty()) {
				toUpsert.Id = nsaList[0].Id;
			}
			upsert toUpsert;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
		return null;
	}

	@AuraEnabled
	public static string signOutFromShift(Id nursingShiftAssignmentId) {
		try {
			//Validating
			if ([SELECT COUNT() FROM Nursing_Shift_Item__c WHERE Nursing_Shift_Assignment__c = :nursingShiftAssignmentId AND (NOT Status__c IN ('Closed', 'Cancelled'))] > 0) {
				return 'Assignment still have open items';
			}

			update new Nursing_Shift_Assignment__c(Id = nursingShiftAssignmentId, Sign_Out_Date_Time__c = System.now(), Status__c = 'Closed');
			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static string signOutNurseFromShift(Id nursingShiftId, Id nurseId) {
		try {
			//Validating
			if ([SELECT COUNT() FROM Nursing_Shift_Item__c WHERE Nursing_Shift__c = :nursingShiftId AND Nurse__c = :nurseId AND (NOT Status__c IN ('Closed', 'Cancelled'))] > 0) {
				return 'Nurse still have open items';
			}

			Nursing_Shift_Assignment__c[] assignments = [SELECT Id FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :nursingShiftId AND Owner__c = :nurseId AND (NOT Status__c IN ('Closed', 'Cancelled'))];

			for (Nursing_Shift_Assignment__c nsa : assignments) {
				nsa.Sign_Out_Date_Time__c = System.now();
				nsa.Status__c = 'Closed';
			}

			if (assignments.size() > 0) {
				update assignments;
			}

			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static string removeNurseFromShift(Id nursingShiftId, Id nurseId) {
		try {
			//Validating
			Nursing_Shift_Item__c[] items = [SELECT Id FROM Nursing_Shift_Item__c WHERE Nursing_Shift__c = :nursingShiftId AND Nurse__c = :nurseId AND (NOT Status__c IN ('Closed', 'Cancelled'))];

			if (items.size() > 0) {
				return 'Assignment still have open items';
			}

			//Remove assignment
			Nursing_Shift_Assignment__c[] nsaList = [SELECT id FROM Nursing_Shift_Assignment__c WHERE Owner__c = :nurseId AND Nursing_Shift__c = :nursingShiftId];

			if (nsaList.size() > 0) {
				delete nsaList;
			}

			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static string removeShiftAssignment(Id nursingShiftAssignmentId) {
		try {
			//Validating
			if ([SELECT COUNT() FROM Nursing_Shift_Item__c WHERE Nursing_Shift_Assignment__c = :nursingShiftAssignmentId AND (NOT Status__c IN ('Closed', 'Cancelled'))] > 0) {
				return 'The nurse still has open shift items.';
			}

			if ([SELECT COUNT() FROM Nursing_Shift_Patient_Assignment__c WHERE Nursing_Shift_Assignment__c = :nursingShiftAssignmentId AND (NOT Status__c IN ('Closed', 'Cancelled'))] > 0) {
				return 'The nurse is assigned to one or more patients.';
			}

			update new Nursing_Shift_Assignment__c(Id = nursingShiftAssignmentId, Status__c = 'Removed');

			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static string cancelShiftItem(Id nursingShiftItemId) {
		try {
			Nursing_Shift_Item__c nsi = [SELECT Id, Physical_Monitor__c, Form__c, Procedure_Order__c FROM Nursing_Shift_Item__c WHERE Id = :nursingShiftItemId];

			Nursing_Shift_Item__c nsiToUpdate = new Nursing_Shift_Item__c(Id = nsi.Id, Status__c = 'Cancelled', Cancelled_By__c = UserInfo.getUserId(), Cancelled_Date_Time__c = System.now());

			if (nsi.Procedure_Order__c == null) {
				if (nsi.Procedure_Order__c != null) {
					Database.delete(nsi.Procedure_Order__c);
				}
				nsiToUpdate.Closed_By__c = UserInfo.getUserId();
				nsiToUpdate.Closed_Date_Time__c = System.now();
			}
			if (nsi.Physical_Monitor__c != null) {
				Database.delete(nsi.Physical_Monitor__c);
			}
			if (nsi.Form__c != null) {
				Database.delete(nsi.Form__c);
			}

			//Database.delete(nursingShiftItemId);
			update nsiToUpdate;

			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static string cancelShiftItemWithReasons(Id nursingShiftItemId, String NotPerformedReason, String NotPerformedOtherReason) {
		try {
			Nursing_Shift_Item__c nsi = [SELECT Id, Physical_Monitor__c, Form__c, Procedure_Order__c, Procedure_Result__c FROM Nursing_Shift_Item__c WHERE Id = :nursingShiftItemId];

			Nursing_Shift_Item__c nsiToUpdate = new Nursing_Shift_Item__c(Id = nsi.Id, Status__c = 'Cancelled', Cancelled_By__c = UserInfo.getUserId(), Cancelled_Date_Time__c = System.now(), Closed_By__c = UserInfo.getUserId(), Closed_Date_Time__c = System.now(), Not_Performed_Reason__c = NotPerformedReason, Not_Performed_Other_Reason__c = NotPerformedOtherReason);

			if (nsi.Procedure_Result__c != null) {
				update new Procedure_Result__c(Id = nsi.Procedure_Result__c, Status__c = 'Cancelled', Not_Performed_Reason__c = NotPerformedReason, Not_Performed_Other_Reason__c = NotPerformedOtherReason);
			}

			if (nsi.Physical_Monitor__c != null) {
				update new Physical_Monitor__c(Id = nsi.Physical_Monitor__c, RecordTypeId = Schema.SObjectType.Physical_Monitor__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId(), Status__c = 'Finalized', Finalized_By__c = UserInfo.getUserId(), Finalized_Date_Time__c = system.now(), Not_Performed_Reason__c = NotPerformedReason, Not_Performed_Other_Reason__c = NotPerformedOtherReason);
			}
			if (nsi.Form__c != null) {
				Database.delete(nsi.Form__c);
			}

			//Database.delete(nursingShiftItemId);
			update nsiToUpdate;

			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static SObject[] getSignInOutData() {
		return [SELECT Id, Date__c, Shift__c, Shift_Number__c, Status__c, Charge_Nurse__c, Shift_Open_Date_Time__c, Scheduled_Closed_Date_Time__c FROM Nursing_Shift__c WHERE Status__c IN ('Open', 'New') ORDER BY Date__c ASC, Shift_Number__c ASC];
	}

	@AuraEnabled
	public static SObject[] getCurrentNursingShiftItems() {
		return [SELECT Id, Form__c, Nursing_Shift_Assignment__c, Nursing_Shift_Assignment__r.Owner__c, Nursing_Shift_Assignment__r.Open_Shift_Items__c, Patient__c, Patient__r.Team__c, Patient__r.Current_Admitted_Program_Name__c, Patient__r.Current_Admission__r.In_PAS__c, Patient_Note__c, Physical_Monitor__c, Procedure_Order__c, Status__c, Subject__c, Description__c FROM Nursing_Shift_Item__c];
	}

	@AuraEnabled
	public static SObject[] getPatientAssignmentsByNursingShift(Id nursingShiftId) {
		return [
			SELECT Id, Nursing_Shift_Assignment__r.Id, Nursing_Shift_Assignment__r.Owner__r.Name, Nursing_Shift_Assignment__r.Open_Shift_Items__c, Patient__r.Id, Patient__r.Name, Patient__r.Team__c, Patient__r.Current_Admitted_Program_Name__c, Patient__r.Current_Admission__r.In_PAS__c, Patient__r.Current_Admission__r.Stage__c, Patient__r.Current_Admitted_Program_Status__c, Patient__r.Current_Admitted_Program_Product_Code__c, Open_Patient_Shift_Items__c, Shift_Assigned_To__r.Id, Shift_Assigned_To__r.Name
			FROM Nursing_Shift_Patient_Assignment__c
			WHERE Nursing_Shift__c = :nursingShiftId
			ORDER BY Patient__r.Name ASC
		];
	}

	@AuraEnabled
	public static string saveNursingFieldChange(string nursingShiftId, string fieldName, object value) {
		try {
			FieldDefinition[] fd = [SELECT DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Nursing_Shift__c' AND QualifiedApiName = :fieldName LIMIT 1];
			if (fd.isEmpty()) {
				throw new AuraException('Invalid field name [' + fieldName + ']');
			}
			Nursing_Shift__c ns = new Nursing_Shift__c(Id = nursingShiftId);
			if (value == null) {
				ns.put(fieldName, null);
			} else if (fd[0].DataType == 'Date') {
				ns.put(fieldName, Date.valueOf(string.valueof(value)));
			} else if (fd[0].DataType == 'DateTime') {
				ns.put(fieldName, DateTime.valueOf(string.valueof(value)));
			} else {
				ns.put(fieldName, value);
			}
			update ns;
		} catch (Exception ex) {
			return ex.getMessage();
		}
		return null;
	}

	@AuraEnabled
	public static Nursing_Shift_Assignment__c[] getNursingShiftAssigmentsByShiftId(Id nursingShiftId) {
		Id userId = UserInfo.getUserId();
		return [SELECT Id, Name, Owner__c, Owner__r.Name, Owner__r.FirstName, Owner__r.LastName, Owner__r.Professional_Name__c, Role__c, Sign_In_Date_Time__c, Sign_Out_Date_Time__c, Status__c FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :nursingShiftId AND Status__c != 'Removed'];
	}

	@AuraEnabled
	public static Nursing_Shift_Assignment__c[] geOpenNursingShiftAssigmentsByShiftId(Id nursingShiftId) {
		Id userId = UserInfo.getUserId();
		return [SELECT Id, Name, Owner__c, Owner__r.Name, Owner__r.FirstName, Owner__r.LastName, Owner__r.Professional_Name__c, Role__c, Sign_In_Date_Time__c, Sign_Out_Date_Time__c, Status__c FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :nursingShiftId AND Sign_Out_Date_Time__c = NULL AND Status__c = 'Open'];
	}

	@AuraEnabled
	public static String closeNursingShiftItem(Id itemId) {
		try {
			update new Nursing_Shift_Item__c(Id = itemId, Status__c = 'Closed');
		} catch (Exception ex) {
			return ex.getMessage();
		}
		return null;
	}

	@AuraEnabled
	public static Boolean checkCustomPermission(String customPermission) {
		try {
			return FeatureManagement.checkPermission(customPermission);
		} catch (Exception ex) {
		}
		return false;
	}
}
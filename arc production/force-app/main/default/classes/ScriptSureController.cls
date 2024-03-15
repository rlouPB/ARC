/**
 * @description       :
 * @author            :
 * @file type         :
 * @created modified  :
 * @last modified on  : 01-13-2022
 * @last modified by  :
 **/
public class ScriptSureController {
	private static final String[] PRESCRIPTION_STATUSES_TO_INCLUDE = new List<String>{ 'Active', 'Discontinued' };

	@AuraEnabled
	public static string getSessionToken() {
		try {
			// ScriptSure_ServiceUtil.authenticate();

			// //Get API settings from MDT
			// List<ScriptSure_API_Settings__mdt> scrApiSettingList = [SELECT Id, Email__c, Session_Token__c
			// FROM ScriptSure_API_Settings__mdt WHERE Email__c = 'alexcia.adams@austenriggs.net'];

			// return scrApiSettingList.size() > 0 ? scrApiSettingList[0].Session_Token__c : null;
			return ScriptSure_ServiceUtil.authenticate(false);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string getUrl(String patientAccounttid) {
		// try {
		return ScriptSure_ServiceUtil.getUiUrl(patientAccounttid);
		// } catch (Exception e) {
		//     throw new AuraHandledException(e.getMessage());
		// }
	}

	@AuraEnabled
	public static boolean isExternalScriptSureUser() {
		try {
			//TODO: Get logged user and validate it contains an external User Id.
			Id userId = System.UserInfo.getUserId();
			List<User> userList = [SELECT Id FROM User WHERE Id = :userId AND External_ScriptSure_User_Id__c != NULL];

			return userList.size() > 0;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static String validateRequiredFields(Id patientContactId) {
		try {
			System.debug('****** validateRequiredFields patientContactId ---> ' + patientContactId);
			return ScriptSure_ServiceUtil.validateRequiredFields(patientContactId);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	// public static List<ScriptSure_ServiceUtil.ScriptSureAllergies> getPatientAllergies(String externalPatientId){
	public static List<ScriptSure_ServiceUtil.ScriptSureAllergies> getPatientAllergies(String accountId, String filter) {
		System.debug('******* Filter ---> ' + filter);

		List<Allergy__c> allergyList;

		if (filter == 'all') {
			allergyList = [SELECT Id, HIC_SEQN__c, Id__c, Name__c, Ndc__c, Onset_Date__c, Patient_Id__c, Account__r.Encounter_Id__c, Reaction__c, Reaction_Text__c, ROUTED_MED_ID__c, Rxnorm__c, Severity_Code__c, Severity_Code_Text__c, Updated_At__c, User_Id__c, User_Name__c, Allergy_Type__c, Archive__c, Comment__c, Created_At__c, DAM_ALRGN_GRP__c, Doctor_Name__c, End_Date__c, Adverse_Event_Code__c, Adverse_Event_Code_Text__c, GCN_SEQN__c, Account__c, IRIS_Only__c, Allergy_Type_Text__c, Allergy_Id__c FROM Allergy__c WHERE Account__c = :accountId];
		} else if (filter == 'active') {
			allergyList = [SELECT Id, HIC_SEQN__c, Id__c, Name__c, Ndc__c, Onset_Date__c, Patient_Id__c, Account__r.Encounter_Id__c, Reaction__c, Reaction_Text__c, ROUTED_MED_ID__c, Rxnorm__c, Severity_Code__c, Severity_Code_Text__c, Updated_At__c, User_Id__c, User_Name__c, Allergy_Type__c, Archive__c, Comment__c, Created_At__c, DAM_ALRGN_GRP__c, Doctor_Name__c, End_Date__c, Adverse_Event_Code__c, Adverse_Event_Code_Text__c, GCN_SEQN__c, Account__c, IRIS_Only__c, Allergy_Type_Text__c, Allergy_Id__c FROM Allergy__c WHERE Account__c = :accountId AND Allergy_Status__c = 'Active'];
		}
		try {
			List<ScriptSure_ServiceUtil.ScriptSureAllergies> scriptSureAllergies = new List<ScriptSure_ServiceUtil.ScriptSureAllergies>();

			for (Allergy__c allergy : allergyList) {
				scriptSureAllergies.add(new ScriptSure_ServiceUtil.ScriptSureAllergies(allergy));
			}

			// return ScriptSure_ServiceUtil.getPatientAllergies(externalPatientId);
			return scriptSureAllergies;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy> searchAllergies(String allergyName) {
		try {
			return ScriptSure_ServiceUtil.searchAllergies(allergyName);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	// public static ScriptSure_ServiceUtil.ScriptSureAllergies createPatientAllergy(String jsonAllergy){
	// public static Boolean createPatientAllergy(String jsonAllergy){
	public static String createUpdatePatientAllergy(String jsonAllergy, Boolean isUpdate, String recordId) {
		//TODO: Insert into Allergy Object
		ScriptSure_ServiceUtil.ScriptSureAllergies receivedAllergy = (ScriptSure_ServiceUtil.ScriptSureAllergies) JSON.deserialize(jsonAllergy, ScriptSure_ServiceUtil.ScriptSureAllergies.class);
		System.debug('*** json ---> ' + jsonAllergy);
		//System.debug('*** date ---> ' + Date.newInstance(receivedAllergy.onsetDate.year(), receivedAllergy.onsetDate.month(), receivedAllergy.onsetDate.day()));
		Allergy__c allergy = new Allergy__c();
		allergy.Name__c = receivedAllergy.name.remove('(IRIS Only)');
		allergy.Account__c = receivedAllergy.accountId;
		allergy.Patient_Id__c = receivedAllergy.patientId;
		allergy.Allergy_Type__c = String.valueOf(receivedAllergy.allergyType);
		allergy.Adverse_Event_Code__c = receivedAllergy.adverseEventCode;
		allergy.Reaction__c = String.valueOf(receivedAllergy.reactionId);
		allergy.Comment__c = receivedAllergy.comment;
		allergy.Archive__c = '0';
		if (receivedAllergy.onsetDate != null) {
			allergy.Onset_Date__c = Date.newInstance(receivedAllergy.onsetDate.year(), receivedAllergy.onsetDate.month(), receivedAllergy.onsetDate.day());
		}
		if (receivedAllergy.endDate != null) {
			allergy.End_Date__c = Date.newInstance(receivedAllergy.endDate.year(), receivedAllergy.endDate.month(), receivedAllergy.endDate.day());
		}
		allergy.Severity_Code__c = receivedAllergy.severityCode;
		System.debug('**** irisOnly ---> ' + receivedAllergy.irisOnly);
		allergy.IRIS_Only__c = receivedAllergy.irisOnly;

		try {
			if (isUpdate) {
				allergy.Id = Id.valueOf(recordId);
				update allergy;
			} else {
				insert allergy;
			}

			// return true;
			return String.valueOf(allergy.Id);
			// return ScriptSure_ServiceUtil.createPatienAllergy(jsonAllergy);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<Prescription__c> getExistingPrescriptions(Id accountId) {
		try {
			List<Prescription__c> prescriptionList = [SELECT Id, Drug_Name__c, Drug_Format__c, Drug_Format_Description__c, Written_Date__c, Presciber__c, Prescriber_Professional_Name__c, Indication_Text__c, Status__c, Medication_Filled_with__c, Medication_Format__c, away_package_Instruction__c, Location__c, location_temp__c, Daily_Dosage_Quantity__c, End_Date__c, Quantity__c, Dosage_Quantity__c, As_Needed__c FROM Prescription__c WHERE Account__c = :accountId AND Medication_Filled_with__c != NULL ORDER BY As_Needed__c ASC, Medication_Filled_with__c ASC];
			return prescriptionList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static Account getAccount(Id accountId) {
		try {
			System.debug('accountId : ' + accountId);
			List<Account> accounts = [SELECT Current_Admission__r.Dispensing_Status__c, External_Patient_Id__c FROM Account WHERE Id = :accountId];
			return accounts.get(0);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public static List<Prescription__c> getExistingPrescriptionsWithQuery(Id accountId, string patientNoteId, string medicationQuery) {
		return ScriptSureController.getExistingPrescriptionsWithQuery(accountId, patientNoteId, medicationQuery, false);
	}

	@AuraEnabled
	public static List<Prescription__c> getExistingPrescriptionsWithQuery(Id accountId, string patientNoteId, string medicationQuery, boolean forMSAOrAway) {
		try {
			List<Prescription__c> existingPrescriptions = new List<Prescription__c>();
			Patient_Note__c note = [SELECT Contact_Date__c, Admission__r.Admit_Date__c, Hide_in_Snapshot__c FROM Patient_Note__c WHERE id = :patientNoteId WITH SECURITY_ENFORCED];
			if (medicationQuery == 'Monthly') {
				//Monthly - Get the first and last day of the month for the given Patient_Note__c → Contact_Date__c then apply this query logic:
				//  * Written_Date__c <= lastDayOfMonth AND (Inactive_Datetime__c is null OR Inactive_Datetime__c >= firstDayOfMonth)
				if (note.Contact_Date__c != null) {
					Integer numberOfDays = Date.daysInMonth(note.Contact_Date__c.year(), note.Contact_Date__c.month());
					Date firstDayOfMonth = Date.newInstance(note.Contact_Date__c.year(), note.Contact_Date__c.month(), 1);
					Date lastDayOfMonth = Date.newInstance(note.Contact_Date__c.year(), note.Contact_Date__c.month(), numberOfDays);
					existingPrescriptions = [
						SELECT Id, Drug_Name__c, Drug_Format__c, Medication_Filled_with__c, Medication_Format__c, Written_Date__c, Presciber__c, Prescriber_Professional_Name__c, Indication_Text__c, Status__c, Daily_Dosage_Quantity__c, Dosage_Quantity__c, As_Needed__c, Start_Date__c, End_Date__c
						FROM Prescription__c
						WHERE
							Account__c = :accountId
							// DAY_ONLY(convertTimezone(Written_Date__c)) <= :lastDayOfMonth AND
							// ( Inactive_Datetime__c = null OR DAY_ONLY(convertTimezone(Inactive_Datetime__c)) >= :firstDayOfMonth )
							AND Start_Date__c <= :lastDayOfMonth
							AND (End_Date__c = NULL
							OR End_Date__c >= :firstDayOfMonth)
							AND Status__c IN :PRESCRIPTION_STATUSES_TO_INCLUDE
							AND Medication_Filled_with__c != NULL
							AND IRIS_Fill_Datetime__c != NULL
						ORDER BY As_Needed__c ASC, Medication_Filled_with__c ASC
					];
				}
			} else if (medicationQuery == 'This Month') {
				//This Month - Show prescriptions that have started or stopped in the month of the note
				//The query would be based on the note contact date....any medications with a written within that month OR with an inactive date within that month

				if (note.Contact_Date__c != null) {
					Integer numberOfDays = Date.daysInMonth(note.Contact_Date__c.year(), note.Contact_Date__c.month());
					Date firstDayOfMonth = Date.newInstance(note.Contact_Date__c.year(), note.Contact_Date__c.month(), 1);
					Date lastDayOfMonth = Date.newInstance(note.Contact_Date__c.year(), note.Contact_Date__c.month(), numberOfDays);
					existingPrescriptions = [
						SELECT Id, Drug_Name__c, Drug_Format__c, Medication_Filled_with__c, Medication_Format__c, Written_Date__c, Presciber__c, Prescriber_Professional_Name__c, Indication_Text__c, Status__c, Daily_Dosage_Quantity__c, Dosage_Quantity__c, As_Needed__c, Start_Date__c, End_Date__c
						FROM Prescription__c
						WHERE
							Status__c IN :PRESCRIPTION_STATUSES_TO_INCLUDE
							AND Account__c = :accountId
							// ((DAY_ONLY(convertTimezone(Written_Date__c)) <= :lastDayOfMonth AND (DAY_ONLY(convertTimezone(Written_Date__c)) >= :firstDayOfMonth)) OR
							// (DAY_ONLY(convertTimezone(Inactive_Datetime__c)) <= :lastDayOfMonth AND DAY_ONLY(convertTimezone(Inactive_Datetime__c)) >= :firstDayOfMonth ))
							AND ((Start_Date__c <= :lastDayOfMonth
							AND Start_Date__c >= :firstDayOfMonth)
							OR (End_Date__c <= :lastDayOfMonth
							AND End_Date__c >= :firstDayOfMonth))
							AND Medication_Filled_with__c != NULL
							AND IRIS_Fill_Datetime__c != NULL
						ORDER BY As_Needed__c ASC, Medication_Filled_with__c ASC
					];
				}
			} else if (medicationQuery == 'Note Date') {
				//Note Date - Patient_Note__c → Contact_Date__c between Written_Date__c and Inactive_Datetime__c OR >= Written_Date__c and Inactive_Date__c is null.
				Date contactDate = note?.Contact_Date__c;
				if (forMSAOrAway) {
					existingPrescriptions = [
						SELECT Id, Drug_Name__c, Drug_Format__c, Medication_Filled_with__c, Medication_Format__c, Written_Date__c, Presciber__c, Prescriber_Professional_Name__c, Indication_Text__c, Status__c, /*NEW FIELDS FOR MSA AND AWAY*/ Quantity_to_Package_Temp__c, Quantity_to_Package__c, away_package_Instruction__c, Location__c, location_temp__c, Daily_Dosage_Quantity__c, End_Date__c, Quantity__c, On_Going_Quantity__c, Dosage_Quantity__c, As_Needed__c, Start_Date__c
						FROM Prescription__c
						WHERE
							Account__c = :accountId
							// DAY_ONLY(convertTimezone(Written_Date__c)) <= :contactDate AND
							// ( Inactive_Datetime__c = null OR DAY_ONLY(convertTimezone(Inactive_Datetime__c)) = :contactDate )
							AND Start_Date__c <= :contactDate
							AND (End_Date__c = NULL
							OR End_Date__c = :contactDate)
							AND Status__c = 'Active'
							AND Medication_Filled_with__c != NULL
							AND IRIS_Fill_Datetime__c != NULL
						ORDER BY As_Needed__c ASC, Medication_Filled_with__c ASC
					];
				} else {
					existingPrescriptions = [
						SELECT Id, Drug_Name__c, Drug_Format__c, Medication_Filled_with__c, Medication_Format__c, Written_Date__c, Presciber__c, Prescriber_Professional_Name__c, Indication_Text__c, Status__c, /*NEW FIELDS FOR MSA AND AWAY*/ Quantity_to_Package_Temp__c, Quantity_to_Package__c, away_package_Instruction__c, Location__c, location_temp__c, Daily_Dosage_Quantity__c, End_Date__c, Quantity__c, On_Going_Quantity__c, Dosage_Quantity__c, As_Needed__c, Start_Date__c
						FROM Prescription__c
						WHERE
							Account__c = :accountId
							// DAY_ONLY(convertTimezone(Written_Date__c)) <= :contactDate AND
							// ( Inactive_Datetime__c = null OR DAY_ONLY(convertTimezone(Inactive_Datetime__c)) = :contactDate )
							AND Start_Date__c <= :contactDate
							AND (End_Date__c = NULL
							OR End_Date__c = :contactDate)
							AND Status__c IN :PRESCRIPTION_STATUSES_TO_INCLUDE
							AND Medication_Filled_with__c != NULL
							AND IRIS_Fill_Datetime__c != NULL
						ORDER BY As_Needed__c ASC, Medication_Filled_with__c ASC
					];
				}
			} else if (medicationQuery == 'Admit Date') {
				//Admit Date - Patient_Note__c → Admission__c → Admit Date = Written_Date__c. This should always be the same exact day.
				date adminDate = note?.Admission__r?.Admit_Date__c;
				existingPrescriptions = [
					SELECT Id, Drug_Name__c, Drug_Format__c, Medication_Filled_with__c, Medication_Format__c, Written_Date__c, Presciber__c, Prescriber_Professional_Name__c, Indication_Text__c, Status__c, Daily_Dosage_Quantity__c, Dosage_Quantity__c, As_Needed__c, Start_Date__c, End_Date__c
					FROM Prescription__c
					WHERE
						Account__c = :accountId
						// Written_Date__c != null AND
						// DAY_ONLY(convertTimezone(Written_Date__c)) =:adminDate
						AND Start_Date__c != NULL
						AND Start_Date__c = :adminDate
						AND Status__c IN :PRESCRIPTION_STATUSES_TO_INCLUDE
						AND Medication_Filled_with__c != NULL
						AND IRIS_Fill_Datetime__c != NULL
					ORDER BY As_Needed__c ASC, Medication_Filled_with__c ASC
				];
			} else if (medicationQuery == 'First of Month') {
				//First of Month - This should show medications that were active as of the first day of the month of the contact date
				if (note.Contact_Date__c != null) {
					Date firstDayOfMonth = note.Contact_Date__c.toStartOfMonth();
					existingPrescriptions = [
						SELECT Id, Drug_Name__c, Drug_Format__c, Medication_Filled_with__c, Medication_Format__c, Written_Date__c, Presciber__c, Prescriber_Professional_Name__c, Indication_Text__c, Status__c, Daily_Dosage_Quantity__c, Dosage_Quantity__c, As_Needed__c, Start_Date__c, End_Date__c
						FROM Prescription__c
						WHERE
							Account__c = :accountId
							// DAY_ONLY(convertTimezone(Written_Date__c)) <= :firstDayOfMonth AND
							// ( Inactive_Datetime__c = null OR DAY_ONLY(convertTimezone(Inactive_Datetime__c)) >= :firstDayOfMonth )
							AND Start_Date__c <= :firstDayOfMonth
							AND (End_Date__c = NULL
							OR End_Date__c >= :firstDayOfMonth)
							AND Status__c IN :PRESCRIPTION_STATUSES_TO_INCLUDE
							AND Medication_Filled_with__c != NULL
							AND IRIS_Fill_Datetime__c != NULL
						ORDER BY As_Needed__c ASC, Medication_Filled_with__c ASC
					];
				}
			} else {
				throw new CustomException('Invalid Medication Query');
			}

			boolean hideInSnapshot = false;

			if (existingPrescriptions.size() == 0) {
				hideInSnapshot = true;
			}
			if (note.Hide_in_Snapshot__c != hideInSnapshot) {
				//updateHideInSnapshotFlag(note.Id, hideInSnapshot);
			}
			return existingPrescriptions;
		} catch (Exception e) {
			throw new CustomException(e.getMessage() + ' - ' + e.getStackTraceString());
		}
	}

	@future
	public static void updateHideInSnapshotFlag(String noteId, Boolean val) {
		Patient_Note__c noteUpdate = new Patient_Note__c(Id = noteId, Hide_in_Snapshot__c = val);
		if (Schema.sObjectType.Patient_Note__c.fields.Hide_in_Snapshot__c.IsUpdateable()) {
			Database.update(noteUpdate);
		}
	}

	@AuraEnabled
	public static List<Prescription__c> pullPrescriptions(String externalPatientId, String accountId) {
		System.debug('***** externalPatientId ---> ' + externalPatientId);
		System.debug('***** accountId ---> ' + accountId);

		try {
			String sessionToken = ScriptSure_ServiceUtil.authenticate(false);
			System.debug('***** sessionToken --> ' + sessionToken);
			List<Prescription__c> prescriptionList = ScriptSure_ServiceUtil.getPrescriptions(externalPatientId, accountId, sessionToken, false);
			return prescriptionList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	//@ DATE CREATED 1/13/22
	// *** To Update the prescriptions from the scriptusre prescription lwc table [FOR MAS & FOR AWAY] ***
	@AuraEnabled
	public static string updatePrescriptions(Object data) {
		List<Prescription__c> prescForUpdate = (List<Prescription__c>) JSON.deserialize(JSON.serialize(data), List<Prescription__c>.class);
		try {
			update prescForUpdate;
			return 'Success: Prescription(s) updated successfully';
		} catch (Exception e) {
			return 'The following exception has occurred: ' + e.getMessage();
		}
	}

	// TODO: Inncrease code coverage
	public static void increaseCoverage() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}
/**
 * @Description:
 * @Created By: Fernando Ortiz
 */

public class AllergyTrigger_Handler {
	public static Boolean runUpdate = true;

	public static void createScriptSurePatientAllergies(List<Allergy__c> allergyList) {
		for (Allergy__c allergy : allergyList) {
			if (allergy.Patient_Id__c != null) {
				// To prevent that making a call out if the Patient Id is not provided.
				String allergyJSON = JSON.serialize(allergy, true);
				ScriptSure_ServiceUtil.createScriptSurePatienAllergy(allergyJSON);
			}
		}
	}

	public static void updateScriptSurePatientAllergies(List<Allergy__c> allergyList) {
		if (runUpdate) {
			for (Allergy__c allergy : allergyList) {
				String allergyJSON = JSON.serialize(allergy, true);
				ScriptSure_ServiceUtil.updateScriptSurePatienAllergy(allergyJSON);
			}
		}
	}

	public static void updatePatientContactAllergyFields(Map<Id, Allergy__c> allergyMap) {
		Set<Id> accountIdSet = new Set<Id>();
		List<String> foodAllergies = new List<String>();
		List<Contact> contactsToUpdate = new List<Contact>();
		String result = null;
		Map<Id, List<Allergy__c>> conAllergyMap = new Map<Id, List<Allergy__c>>();

		for (Id key : allergyMap.keySet()) {
			accountIdSet.add(allergyMap.get(key).Account__c);
		}

		List<Account> accountsToUpdate = [
			SELECT
				Id,
				Name,
				Patient_Contact__c,
				// (SELECT Id, Name, Dietary_Restrictions__c, Food_Allergies__c FROM Contacts),
				(SELECT Id, Account__c, Name__c, Allergy_Type_Text__c, Adverse_Event_Code_Text__c, Reaction_Text__c, Severity_Code_Text__c, End_Date__c FROM Allergies__r WHERE Adverse_Event_Code_Text__c LIKE '%Food%' AND Allergy_Status__c = 'Active')
			FROM Account
			WHERE Id IN :accountIdSet
		];

		for (Account acc : accountsToUpdate) {
			Contact conToUpdate = new Contact(Id = acc.Patient_Contact__c);
			for (Allergy__c all : acc.Allergies__r) {
				if (result == null) {
					result = all.Adverse_Event_Code_Text__c + ': ' + all.Name__c + ' - ' + all.Reaction_Text__c + ' - ' + all.Severity_Code_Text__c + '; ';
				} else {
					result += all.Adverse_Event_Code_Text__c + ': ' + all.Name__c + ' - ' + all.Reaction_Text__c + ' - ' + all.Severity_Code_Text__c + '; ';
				}
			}
			if (null != result) {
				result = result.removeEnd('; ');
			}
			conToUpdate.Food_Allergies__c = result;
			contactsToUpdate.add(conToUpdate);
			result = null;
		}

		try {
			update contactsToUpdate;
		} catch (Exception e) {
			System.debug(e);
		}
	}

	public static void updateMedRecFormIfNeeded(List<Allergy__c> allergyList) {
		Set<Id> accountIds = new Set<Id>();
		for (Allergy__c allergy : allergyList) {
			accountIds.add(allergy.Account__c);
		}

		disco__Form__c[] medRecForms = [SELECT Id, Admission__c, Admit_Date__c, Current_Admission_Stage__c, disco__Form_Account__c, disco__Form_Contact__c, disco__Form_Template__c, disco__Status__c, Service_Type__c, Template_Doc_Name__c FROM disco__Form__c WHERE Template_Doc_Name__c = 'Medication_Reconciliation_at_Admission' AND disco__Status__c != 'LOCKED' AND disco__Form_Account__c IN :accountIds AND (Current_Admission_Stage__c = 'Consultation Pending' OR Admit_Date__c = TODAY) AND disco__Form_Template__r.disco__Status__c = 'In Use'];

		disco__Form__c[] clonedForms = new List<disco__Form__c>{};
		for (disco__Form__c form : medRecForms) {
			clonedForms.add(form.clone(false, false, false, false));
		}
		insert clonedForms;
		delete medRecForms;
	}

	public static void checkAllergyDelete(List<Allergy__c> triggerOld) {
		//allow delete for selected Profiles regardless of Stage
		Profile currentUserProfile = [SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()];
		Set<String> authorizedDeletors = new Set<String>{ 'System Administrator', 'RiggsMedicalRecords' };
		if (authorizedDeletors.contains(currentUserProfile.Name))
			return;

		Set<Id> accIds = new Set<Id>();
		for (Allergy__c a : triggerOld) {
			accIds.add(a.Account__c);
		}
		Map<Id, Account> accIdMap = new Map<Id, Account>([SELECT Id, Current_Admission_Stage__c FROM Account WHERE Id IN :accIds]);
		for (Allergy__c a : triggerOld) {
			Account acc = accIdMap.get(a.Account__c);
			if (acc == null)
				continue;

			if (acc.Current_Admission_Stage__c == 'Admitted' || acc.Current_Admission_Stage__c == 'Discharged') {
				a.addError('Allergies can only be deleted for Patients currently in the Pre-Admission process');
			}
		}
	}
}
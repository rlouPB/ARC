/**
 * Used by all Discharge Section
 */
public without sharing class DischargeSectionCtl {
	@AuraEnabled
	public static String saveDischargeSection(String dischargeSectionString) {
		String retval;
		Map<String, String> errorMap = new Map<String, String>();
		System.SavePoint sp = Database.setSavepoint();
		DischargeSection dischargeSection;
		try {
			dischargeSection = (DischargeSection) JSON.deserialize(dischargeSectionString, DischargeSection.class);
			if (dischargeSection.dischargeSectionObj.Status__c != null && dischargeSection.dischargeSectionObj.Status__c.equalsIgnoreCase('completed')) {
				dischargeSection.dischargeSectionObj.Completed_By__c = UserInfo.getUserId();
				User currentUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :userInfo.getUserId()];
				dischargeSection.completedByName = currentUser.Professional_Name__c;
				dischargeSection.dischargeSectionObj.Completed_By_Professional_Name__c = currentUser.Professional_Name__c;
				dischargeSection.dischargeSectionObj.Completed_Date_Time__c = system.now();
				// Not sure why the field not populating the formattedDateTime, this is why using a separate field
				dischargeSection.completedDateTime = system.now();
			} else {
				dischargeSection.dischargeSectionObj.Completed_By__c = null;
				dischargeSection.dischargeSectionObj.Completed_By_Professional_Name__c = null;
				dischargeSection.completedByName = null;
				dischargeSection.dischargeSectionObj.Completed_Date_Time__c = null;
				dischargeSection.completedDateTime = null;
			}
			List<Discharge_Referral__c> referrals = new List<Discharge_Referral__c>();
			if (dischargeSection.removeReferralList != null) {
				for (DischargeReferral removeReferral : dischargeSection.removeReferralList) {
					referrals.add(removeReferral.dischargeReferralObj);
				}
				delete referrals;
				dischargeSection.removeReferralList.clear();
			}
			if (dischargeSection.referralList != null) {
				referrals = new List<Discharge_Referral__c>();
				Set<Id> referralClinicianIdSet = new Set<Id>();
				Set<Id> referralInstitutionIdSet = new Set<Id>();
				Map<Id, Id> referralClinicianIdMap = new Map<Id, Id>();
				Map<Id, Id> referralInstitutionIdMap = new Map<Id, Id>();
				for (DischargeReferral newReferral : dischargeSection.referralList) {
					referrals.add(newReferral.dischargeReferralObj);
					if (String.isNotBlank(newReferral.dischargeReferralObj.Clinician__c)) {
						referralClinicianIdSet.add(newReferral.dischargeReferralObj.Clinician__c);
					}
					if (String.isNotBlank(newReferral.dischargeReferralObj.Institution__c)) {
						referralInstitutionIdSet.add(newReferral.dischargeReferralObj.Institution__c);
					}
				}
				upsert referrals;
				Map<Id, Contact> clinicianMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id = :referralClinicianIdSet]);
				Map<Id, Account> institutionMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id = :referralInstitutionIdSet]);
				for (DischargeReferral newReferral : dischargeSection.referralList) {
					if (String.isNotBlank(newReferral.dischargeReferralObj.Clinician__c)) {
						Contact clinician = clinicianMap.get(newReferral.dischargeReferralObj.Clinician__c);
						if (clinician != null) {
							newReferral.referralName = clinician.Name;
						}
					}
					if (String.isNotBlank(newReferral.dischargeReferralObj.Institution__c)) {
						Account institution = institutionMap.get(newReferral.dischargeReferralObj.Institution__c);
						if (institution != null) {
							newReferral.referralName = institution.Name;
						}
					}
				}
			}

			update dischargeSection.dischargeSectionObj;
			if (dischargeSection.dischargeSectionObj.Role__c != null && !dischargeSection.dischargeSectionObj.Role__c.equalsIgnoreCase('medical care instructions')) {
				User responsiblePerson = [SELECT Id, Name, Professional_Name__c FROM User WHERE Id = :dischargeSection.dischargeSectionObj.OwnerId LIMIT 1];
				String responsibleUserName = responsiblePerson.Name;
				if (String.isNotBlank(responsiblePerson.Professional_Name__c)) {
					responsibleUserName = responsiblePerson.Professional_Name__c;
				}
				dischargeSection.responsiblePerson = responsibleUserName;
			}
			retval = JSON.serialize(dischargeSection);
		} catch (exception e) {
			Database.rollback(sp);
			system.debug(e.getMessage());
			system.debug(e.getStackTraceString());
			errorMap.put(e.getMessage(), e.getStackTraceString());
		}
		if (!errorMap.isEmpty()) {
			retval = JSON.serialize(errorMap);
		} else {
			DischargeSection returnSection = DischargeDispositionCtl.getDischargeSectionWrappers(dischargeSection.dischargeSectionObj.Discharge_Disposition__c, dischargeSection.dischargeSectionObj.Role__c)[0];
			retval = JSON.serialize(returnSection);
		}
		return retval;
	}
	@AuraEnabled
	public static String reopenDischargeSection(String dischargeSectionString) {
		String retval = 'SUCCESS';
		Map<String, String> errorMap = new Map<String, String>();
		System.SavePoint sp = Database.setSavepoint();
		try {
			DischargeSection dischargeSection = (DischargeSection) JSON.deserialize(dischargeSectionString, DischargeSection.class);
			dischargeSection.dischargeSectionObj.Status__c = 'Draft';
			dischargeSection.dischargeSectionObj.Completed_By__c = null;
			dischargeSection.dischargeSectionObj.Completed_By_Professional_Name__c = null;
			dischargeSection.completedByName = null;
			dischargeSection.dischargeSectionObj.Completed_Date_Time__c = null;
			dischargeSection.completedDateTime = null;
			update dischargeSection.dischargeSectionObj;
			retval = JSON.serialize(dischargeSection);
		} catch (exception e) {
			Database.rollback(sp);
			ProcessLogging.quickProcessLog('DischargeSectionCtl.reopenDischargeSection', e.getStackTraceString(), 'dischargeSectionString ' + dischargeSectionString);
			errorMap.put(e.getMessage(), e.getStackTraceString());
		}
		if (!errorMap.isEmpty()) {
			retval = JSON.serialize(errorMap);
		}
		return retval;
	}
}
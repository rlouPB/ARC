public without sharing class PrescriptionTriggerHandler implements ITrigger {
	static Map<Id, Account> patientMapById = new Map<Id, Account>();
	private static List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();
	private static Map<Id, Account> accountsByIdMap;
	private static Map<Id, List<Assigned_Clinician__c>> assignedCliniciansByAccountIdMap = new Map<Id, List<Assigned_Clinician__c>>();

	/**
	 * bulkBefore
	 *
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		if (!Trigger.isDelete) {
			Set<Id> accountIds = new Set<Id>();
			List<Prescription__c> prescriptions = (List<Prescription__c>) Trigger.new;
			for (Prescription__c p : prescriptions) {
				accountIds.add(p.Account__c);
			}
			List<Account> patientInfo = [SELECT Id, Current_Admission__r.Dispensing_Status__c FROM Account WHERE ID IN :accountIds];
			for (Account a : patientInfo) {
				patientMapById.put(a.Id, a);
			}

			for (Prescription__c p: (List<Prescription__c>)Trigger.new){
				if(null != p.Account__c){
					accountIds.add(p.Account__c);
				}
			}
			accountsByIdMap = new Map<Id, Account>([SELECT Id, Patient_Contact__c FROM Account WHERE Id IN :accountIds]);
			
			List<Assigned_Clinician__c> assignedClinicians = [SELECT Id, Patient_Account__c, Role__c, User__c, User__r.Name, Start_Date__c, End_Date__c FROM Assigned_Clinician__c WHERE Patient_Account__c IN : accountIds];
			for(Assigned_Clinician__c ac : assignedClinicians){
				List<Assigned_Clinician__c> assignedCliniciansForAccount = assignedCliniciansByAccountIdMap.get(ac.Patient_Account__c);
				if(null == assignedCliniciansForAccount) {
					assignedCliniciansForAccount = new List<Assigned_Clinician__c>();
				}
				assignedCliniciansForAccount.add(ac);
				assignedCliniciansByAccountIdMap.put(ac.Patient_Account__c, assignedCliniciansForAccount);
			}
		}
	}

	/**
	 * bulkAfter
	 *
	 * This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
	}

	/**
	 * beforeInsert
	 *
	 * This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
		Prescription__c pres = (Prescription__c) so;

		if (String.isBlank(pres.Name) || pres.name.startsWith('a35')) {
			string valueToAdd = String.isBlank(pres.Medication_Filled_with__c) ? pres.Drug_Name__c : pres.Medication_Filled_with__c;
			pres.Name = valueToAdd;
		}

		if (null != pres.Drug_Name__c && null == pres.Medication_Filled_with__c) {
			pres.Medication_Filled_with__c = pres.Drug_Name__c;
		}

		if (null != pres.Drug_Format__c && null == pres.Medication_Format__c) {
			pres.Medication_Format__c = pres.Drug_Format__c;
		}

		if (null != pres.Parent__c && null != pres.Medication_Format__c) {
			pres.Drug_Format_Description__c = pres.Medication_Format__c;
		} else {
			pres.Drug_Format_Description__c = pres.Drug_Format__c;
		}

		if (null != pres.Times_Of_Day__c) {
			this.setTimesOfDaySort(pres);
		}

		if (null != pres.Account__c && null != patientMapById.get(pres.Account__c) && 'MSA'.equals(patientMapById.get(pres.Account__c).Current_Admission__r.Dispensing_Status__c)) {
			pres.Location__c = 'Package';
		}

		if(null != pres.Inactive_Datetime__c) {
			pres.End_Date__c = pres.Inactive_Datetime__c.date();
		}

		if(null != pres.Account__c && null != accountsByIdMap.get(pres.Account__c) && null != accountsByIdMap.get(pres.Account__c).Patient_Contact__c) {
			pres.Contact__c = accountsByIdMap.get(pres.Account__c).Patient_Contact__c;
		}
	}

	/**
	 * beforeUpdate
	 *
	 * This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
		Prescription__c pres = (Prescription__c) so;
		Prescription__c presOld = (Prescription__c) oldSo;

		if (String.isBlank(pres.Name) || pres.name.startsWith('a35') || pres.Medication_Filled_with__c != presOld.Medication_Filled_with__c) {
			string valueToAdd = String.isBlank(pres.Medication_Filled_with__c) ? pres.Drug_Name__c : pres.Medication_Filled_with__c;
			pres.Name = valueToAdd;
		}

		if (null != pres.Drug_Name__c && null == pres.Medication_Filled_with__c || presOld.Drug_Name__c != pres.Drug_Name__c) {
			pres.Medication_Filled_with__c = pres.Drug_Name__c;
		}

		if (null != pres.Drug_Format__c && null == pres.Medication_Format__c || presOld.Drug_Format__c != pres.Drug_Format__c) {
			pres.Medication_Format__c = pres.Drug_Format__c;
		}

		if (null != pres.Parent__c && null != pres.Medication_Format__c) {
			pres.Drug_Format_Description__c = pres.Medication_Format__c;
		} else {
			pres.Drug_Format_Description__c = pres.Drug_Format__c;
		}

		if (null != pres.Times_Of_Day__c) {
			this.setTimesOfDaySort(pres);
		}

		if(null != pres.Inactive_Datetime__c && (null == pres.End_Date__c || pres.Inactive_Datetime__c < pres.End_Date__c)) {
			pres.End_Date__c = pres.Inactive_Datetime__c.date();
		}

		List<Assigned_Clinician__c> assignedCliniciansForAccount = assignedCliniciansByAccountIdMap.get(pres.Account__c);
		if(null != assignedCliniciansForAccount) {
			for(Assigned_Clinician__c ac : assignedCliniciansForAccount) {
				if(ac.Role__c.equals('Psychiatrist') && ac.Start_Date__c <= System.today() && (ac.End_Date__c == null || ac.End_Date__c >= System.today())) {
					pres.Patient_Psychiatrist__c = ac.User__c;
				}
			}
		}

		if(null != pres.Patient_Psychiatrist__c && pres.Patient_Psychiatrist__c != pres.Presciber__c 
			&& 'Active' != presOld.Status__c && 'Active' == pres.Status__c) {
			pres.Alert_Psychiatrist__c = 'Yes';
		}
	}

	private void setTimesOfDaySort(Prescription__c p) {
		//Times of Day: 6 AM Early Morning;9 AM Morning;12 Noon;5:30 PM Evening;9:30 PM Late Evening;11:30 PM Night
		if (null != p.Times_Of_Day__c) {
			if (p.Times_Of_Day__c.startsWith('6 AM')) {
				p.Times_of_Day_Sort__c = 1;
			} else if (p.Times_Of_Day__c.startsWith('9 AM')) {
				p.Times_of_Day_Sort__c = 2;
			} else if (p.Times_Of_Day__c.startsWith('12 Noon')) {
				p.Times_of_Day_Sort__c = 3;
			} else if (p.Times_Of_Day__c.startsWith('5:30 PM')) {
				p.Times_of_Day_Sort__c = 4;
			} else if (p.Times_Of_Day__c.startsWith('9:30 PM')) {
				p.Times_of_Day_Sort__c = 5;
			} else if (p.Times_Of_Day__c.startsWith('11:30 PM')) {
				p.Times_of_Day_Sort__c = 6;
			}
		}
	}

	/**
	 * beforeDelete
	 *
	 * This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so) {
	}

	/**
	 * afterInsert
	 *
	 * This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public void afterInsert(SObject so) {
		Prescription__c prescription = (Prescription__c)so;
	}

	/**
	 * afterUpdate
	 *
	 * This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		Prescription__c oldPrescription = (Prescription__c) oldSo;
		Prescription__c newPrescription = (Prescription__c) so;
		Set<String> statusesToCascade = new Set<String>{ 'Discontinued', 'Canceled', 'Inactive', 'Archived' };
		if (oldPrescription.Status__c != newPrescription.Status__c && statusesToCascade.contains(newPrescription.Status__c)) {
			List<Prescription__c> children = [SELECT ID, Status__c, Parent__c FROM Prescription__c WHERE Parent__c = :newPrescription.Id];
			for (Prescription__c p : children) {
				p.Status__c = newPrescription.Status__c;
			}
			if (null != children && children.size() > 0) {
				update children;
			}
		}

		String triggerObject = String.valueOf(Trigger.new.getSObjectType());
		AlertsFilter.execute(oldPrescription, newPrescription, alertsToBePublished, triggerObject, 'Update');
	}

	/**
	 * afterDelete
	 *
	 * This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	/**
	 * andFinally
	 *
	 * This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
		System.debug('In andFinally - alertsToBePublished : ' + alertsToBePublished);
		if(alertsToBePublished.size() > 0) {
			EventBus.publish(alertsToBePublished);
		}
	}

	//    public static void updateMedRecFormIfNeeded(List<Prescription__c> prescriptionList) {

	// 	   Set<Id> accountIds = new Set<Id>();
	// 	   for(Prescription__c prescription : prescriptionList) {
	// 		   accountIds.add(prescription.Account__c);
	// 	   }

	// 	   disco__Form__c[] medRecForms = [SELECT Id, Admission__c, Admit_Date__c,
	// 		   Current_Admission_Stage__c, disco__Form_Account__c, disco__Form_Contact__c,
	// 		   disco__Form_Template__c, disco__Status__c, Service_Type__c, Template_Doc_Name__c
	// 		   FROM disco__Form__c WHERE Template_Doc_Name__c = 'Medication_Reconciliation_at_Admission'
	// 		   AND disco__Status__c != 'LOCKED'
	// 		   AND disco__Form_Account__c IN :accountIds
	// 		   AND (Current_Admission_Stage__c = 'Consultation Pending' OR Admit_Date__c = TODAY)
	// 		   AND disco__Form_Template__r.disco__Status__c = 'In Use'];

	// 	   disco__Form__c[] clonedForms = new disco__Form__c[]{};
	// 	   for(disco__Form__c form : medRecForms) {
	// 		   clonedForms.add(form.clone(false, false, false, false));
	// 	   }
	// 	   insert clonedForms;
	// 	   delete medRecForms;
	//    }
}
public with sharing class Case_AbstractTriggerHandler implements ITrigger {
    public Map<String, Account> caseAbstractAccountMap = new Map<String, Account>();
    static Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
    /**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore() {
        
    }

	/**
	* bulkAfter
	*
	* This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter() {
		// Check for outstanding items.
		if (!Trigger.isDelete) {
			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);
		} else {
			OutstandingItems.deleteRelatedTags(trigger.old);
		}
    }
	//This method is called directly from trigger because of the Trigger Framework prevents recursive calls
	public static void setCaseConferenceMeetingInBulkBefore() {
		List<String> caList = new List<String>();
		for (Case_Abstract__c ca : (List<Case_Abstract__c>) Trigger.new) {
			caList.add(ca.Id);
		}
		List<Case_Abstract__c> cas = [SELECT Id , Admission__c , Admission__r.Admit_Date__c , 
                                            Admission__r.Patient_Account__c 
                                            FROM Case_Abstract__c WHERE Id in :caList];
											List<Case_Abstract__c> updateCAList = new List<Case_Abstract__c>();
		system.debug('setCaseConferenceMeetingInBulkBefore ca list=' + cas);
		Map<String, String> ca2PatientMap = new Map<String, String>();
		List<String> accountIds = new List<String>();
		
		for(Case_Abstract__c ca : cas) {
			accountIds.add(ca.Admission__r.Patient_Account__c);
			ca2PatientMap.put(ca.Id, ca.Admission__r.Patient_Account__c);
		}
		system.debug('setCaseConferenceMeetingInBulkBefore account list=' + accountIds);
		Map<String, Meeting__c> caseConference = new Map<String, Meeting__c>();
		List<Meeting__c> meetings = [SELECT Id, Start_Date_Time__c,Patient_Account__c FROM Meeting__c WHERE Patient_Account__c in :accountIds AND 
										Start_Date_Time__c > Today AND Staff_Group_Meeting_Type__c = 'Case Conference'];
		system.debug('setCaseConferenceMeetingInBulkBefore meetings list=' + meetings);
		for(Meeting__c m : meetings) {
			caseConference.put(m.Patient_Account__c, m);
		}
		system.debug('setCaseConferenceMeetingInBulkBefore caseConference map=' + caseConference);
		for (Case_Abstract__c ca : (List<Case_Abstract__c>) Trigger.new) {
			system.debug('setCaseConferenceMeetingInBulkBefore patient account =' + ca2PatientMap.get(ca.Id));
			System.debug('setCaseConferenceMeetingInBulkBefore meeting Id =' + caseConference.get(ca2PatientMap.get(ca.Id))?.Id);
			ca.Meeting__c = caseConference.get(ca2PatientMap.get(ca.Id))?.Id;
		}
	}
	public static Boolean isFirstTime = true;
    public static void autoCreatePatientNotes() {
        //Admission__r.Patient_Account__r.
        system.debug('Case_AbstractTriggerHandler bulkAfter');
        if(Trigger.isInsert && Trigger.isAfter && isFirstTime) {
			isFirstTime = false;
            system.debug('Case_AbstractTriggerHandler InsertAfter');
            List<String> caList = new List<String>();
            List<String> admissionList = new List<String>();
            for (Case_Abstract__c ca : (List<Case_Abstract__c>) Trigger.new) {
                caList.add(ca.Id);
                admissionList.add(ca.Admission__c);
			}
            system.debug('Case_AbstractTriggerHandler caList =' + caList);
            system.debug('Case_AbstractTriggerHandler admissionList =' + admissionList);
            Map<String, Assigned_Clinician__c> assignedClinicianMap = new Map<String, Assigned_Clinician__c>();
            List<Assigned_Clinician__c> assignedClinicians = [SELECT Id , Name , Role__c , Admission__c , User__c 
                                                FROM Assigned_Clinician__c WHERE Admission__c in :admissionList  
                                                    AND Start_Date__c <= TODAY 
                                                    AND (End_Date__c = null OR End_Date__c > TODAY)  ];
            
            system.debug('Case_AbstractTriggerHandler assignedClinicians =' + assignedClinicians);
			Map<String, String> caOwnerMap = new Map<String, String>();
            for(Assigned_Clinician__c ac : assignedClinicians) {
				assignedClinicianMap.put(ac.Admission__c, ac);
				if(ac.Role__c == 'Psychotherapist') {
					caOwnerMap.put(ac.Admission__c, ac.User__c);
				}
            }
            
            List<Case_Abstract__c> cas = [SELECT Id , Admission__c , Admission__r.Admit_Date__c , 
                                            Admission__r.Patient_Account__c 
                                            FROM Case_Abstract__c WHERE Id in :caList];
            List<Patient_Note__c> pateintNotes = new List<Patient_Note__c>();
			List<Case_Abstract__c> updateCAList = new List<Case_Abstract__c>();
			
			List<String> accountIds = new List<String>();
			
			for(Case_Abstract__c ca : cas) {
				accountIds.add(ca.Admission__r.Patient_Account__c);
			}
			Map<String, Datetime> caseConference = new Map<String, Datetime>();
			List<Meeting__c> meetings = [SELECT Id, Start_Date_Time__c,Patient_Account__c FROM Meeting__c WHERE Patient_Account__c in :accountIds AND 
											Start_Date_Time__c > Today AND Staff_Group_Meeting_Type__c = 'Case Conference'];
			for(Meeting__c m : meetings) {
				caseConference.put(m.Patient_Account__c, m.Start_Date_Time__c);
			}

            for(Case_Abstract__c ca : cas) {
				String userId = caOwnerMap.get(ca.Admission__c);
				Datetime dT = caseConference.get(ca.Admission__r?.Patient_Account__c);
				if(dT==null) {
					dT = DateTime.now();
				}

				Date caseConferenceDate = Date.newinstance(dT?.year(), dT?.month(), dT?.day());
				system.debug('Case_AbstractTriggerHandler userId =' + userId);
                pateintNotes.add(createPatientNote(ca, 'Consensus of Case Conference Discussion', userId, caseConferenceDate.addDays(16)));
                pateintNotes.add(createPatientNote(ca, 'Feedback Given to Patient', userId, caseConferenceDate.addDays(16))); 
                pateintNotes.add(createPatientNote(ca, 'Diagnosis of Record', userId, caseConferenceDate.addDays(-4)));
				updateCAList.add(new Case_Abstract__c(Id = ca.Id, OwnerId = userId));
            }
            system.debug('Case_AbstractTriggerHandler pateintNotes =' + pateintNotes);
            if(pateintNotes.size() > 0) {
                insert pateintNotes;
            }
			if(updateCAList.size() > 0) {
				update updateCAList;
			}
            system.debug('Case_AbstractTriggerHandler pateintNotes =' + pateintNotes);
        }
    }
    public static Patient_Note__c createPatientNote(Case_Abstract__c caseAbstract, String noteType, String therapistId, Date contactDate) {
        Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
        Patient_Note__c newNote = new Patient_Note__c(Account__c = caseAbstract.Admission__r.Patient_Account__c,
                                                            Admission__c = caseAbstract.Admission__c,
                                                            Consultation_Assigned_Date__c = System.today(),
                                                            Consultation_Requested_By__c = 'Patient',
                                                            Type__c = noteType,
                                                            Therapist__c = therapistId,
															OwnerId = therapistId,
															Contact_Date__c = contactDate,
                                                            RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId());
        return newNote;
    }
	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so){}

	/**
	* beforeUpdate
	*
	* This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so){}

	/**
	* beforeDelete
	*
	* This method is called iteratively for each record to be deleted during a BEFORE
	* trigger.
	*/
	public void beforeDelete(SObject so){}

	/**
	* afterInsert
	*
	* This method is called iteratively for each record inserted during an AFTER
	* trigger. Always put field validation in the 'After' methods in case another trigger
	* has modified any values. The record is 'read only' by this point.
	*/
	public void afterInsert(SObject so){}

	/**
	* afterUpdate
	*
	* This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so){}

	/**
	* afterDelete
	*
	* This method is called iteratively for each record deleted during an AFTER
	* trigger.
	*/
	public void afterDelete(SObject so){}

	/**
	* andFinally
	*
	* This method is called once all records have been processed by the trigger. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void andFinally(){}
}
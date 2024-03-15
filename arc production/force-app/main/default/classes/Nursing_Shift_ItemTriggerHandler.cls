public without sharing class Nursing_Shift_ItemTriggerHandler implements ITrigger {

	Map<Id, Nursing_Shift__c> nursingShiftsByIdMap; 
	static Map<Id, Patient_Note__c> patientNoteByIdMap;
	static Map<Id, disco__Form__c> discoFormsByIdMap;
	List<Patient_Note__c> patientNotesToUpdate = new List<Patient_Note__c>();
	List<disco__Form__c> discoFormsToUpdate = new List<disco__Form__c>();
	static Map<Id, Account> accountsByIdMap;

	/**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore(){
		if(!Trigger.isDelete){
			Set<Id> nsIds = new Set<Id>();
			Set<Id> patientNoteIds = new Set<Id>();
			Set<Id> formIds = new Set<Id>();
			Set<Id> accountIds = new Set<Id>();
			for(Nursing_Shift_Item__c nsi : (List<Nursing_Shift_Item__c>)Trigger.new) {
				if(null != nsi.Nursing_Shift__c)
					nsIds.add(nsi.Nursing_Shift__c);

				if(null != nsi.Patient_Note__c)
					patientNoteIds.add(nsi.Patient_Note__c);

				if(null != nsi.Form__c)
					formIds.add(nsi.Form__c);

				if(null != nsi.Patient__c)
					accountIds.add(nsi.Patient__c);
			}
			nursingShiftsByIdMap = new Map<Id, Nursing_Shift__c>([SELECT Id, Name, Date__c, Shift_Number__c FROM Nursing_Shift__c WHERE Id IN :nsIds]);
			patientNoteByIdMap = new Map<Id, Patient_Note__c>([SELECT Id, Contact_Date__c, Nursing_Shift__c FROM Patient_Note__c WHERE ID IN :patientNoteIds]);
			discoFormsByIdMap = new Map<Id, disco__Form__c>([SELECT Id FROM disco__Form__c WHERE ID IN :formIds]);
			accountsByIdMap = new Map<Id, Account>([SELECT Id, Current_Admission__c FROM Account WHERE ID IN :accountIds]);
		}

		if ( Trigger.IsInsert ) {
			NursingShiftHelper.assignNursesToShiftItemsOnBeforeInsert(Trigger.New, Trigger.OldMap);
			SIP_DailyNursingShifts.processLeftOverShiftItemsFromTrigger(Trigger.new);
		}
	}

	/**
	* bulkAfter
	*
	* This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter(){
		if( Trigger.IsUpdate || Trigger.IsInsert ){

            if(!Test.isRunningTest()) {
				// We can only have one queueable job per transaction.
				if(Limits.getQueueableJobs() == 0){
			 		System.enqueueJob(new NSPACalculateTotalsQueueable(new list<id>(Trigger.NewMap.keyset()),'NSI'));
				}
			}
			 // NursingShiftHelper.assignNursesToShiftItems(Trigger.New, Trigger.OldMap);
		}
	}

	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so){
        Nursing_Shift_Item__c nsi = (Nursing_Shift_Item__c)so;
        if(null != nsi.Nurse__c) {
            nsi.OwnerId = nsi.Nurse__c;
        }

		if(null == nsi.Nursing_Shift__c && null != nsi.Shift_Date__c && null != nsi.Shift_Number__c) {
			Nursing_Shift__c ns = NursingShiftService.getNursingShift(nsi.Shift_Date__c, nsi.Shift_Number__c);
			if(null != ns) {
				nsi.Nursing_Shift__c = ns.Id;
				nursingShiftsByIdMap.put(ns.Id, ns);
			}
		}

		if(null != nsi.Nursing_Shift__c) {
			Nursing_Shift__c ns = nursingShiftsByIdMap.get(nsi.Nursing_Shift__c);
			if (ns != null){
				nsi.Shift_Date__c = ns.Date__c;
				nsi.Shift_Number__c = ns.Shift_Number__c;
			}
		}

		nsi.Admission__c = null != accountsByIdMap.get(nsi.Patient__c) ? accountsByIdMap.get(nsi.Patient__c).Current_Admission__c : null;
    }

	/**
	* beforeUpdate
	*
	* This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so){
        Nursing_Shift_Item__c nsi = (Nursing_Shift_Item__c)so;
        Nursing_Shift_Item__c nsiOld = (Nursing_Shift_Item__c)oldSo;
        if(null != nsi.Nurse__c) {
            nsi.OwnerId = nsi.Nurse__c;
        }

		if(null != nsi.Shift_Date__c && null != nsi.Shift_Number__c && ((nsi.Shift_Date__c != nsiOld.Shift_Date__c || nsi.Shift_Number__c != nsiOld.Shift_Number__c) || (null == nsi.Nursing_Shift__c))) {
			Nursing_Shift__c ns = NursingShiftService.getNursingShift(nsi.Shift_Date__c, nsi.Shift_Number__c);
			if(null != ns)
				nsi.Nursing_Shift__c = ns.Id;
		}
    }

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
	public void afterInsert(SObject so){
		Nursing_Shift_Item__c nsi = (Nursing_Shift_Item__c)so;

		if(null != nsi.Patient_Note__c && null != patientNoteByIdMap.get(nsi.Patient_Note__c)) {
			Patient_Note__c pn = patientNoteByIdMap.get(nsi.Patient_Note__c);

			if(null != nsi.Shift_Date__c && nsi.Shift_Date__c != pn.Contact_Date__c) {
				pn.Contact_Date__c = nsi.Shift_Date__c;
				pn.Nursing_Shift__c = nsi.Nursing_Shift__c;
				patientNotesToUpdate.add(pn);
			}
		}
	}

	/**
	* afterUpdate
	*
	* This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so){
		Nursing_Shift_Item__c nsi = (Nursing_Shift_Item__c)so;
        Nursing_Shift_Item__c nsiOld = (Nursing_Shift_Item__c)oldSo;

		if(null != nsi.Patient_Note__c && null != patientNoteByIdMap.get(nsi.Patient_Note__c)) {
			Patient_Note__c pn = patientNoteByIdMap.get(nsi.Patient_Note__c);

			if(null != nsi.Shift_Date__c && nsi.Shift_Date__c != pn.Contact_Date__c) {
				pn.Contact_Date__c = nsi.Shift_Date__c;
				pn.Nursing_Shift__c = nsi.Nursing_Shift__c;
				patientNotesToUpdate.add(pn);
			}

			if(null != nsi.Nursing_Shift__c && null == nsiOld.Nursing_Shift__c) {
				pn.Nursing_Shift__c = nsi.Nursing_Shift__c;
				patientNotesToUpdate.add(pn);
			}

			if(null != nsi.Patient_Note__c && null != nsi.Nurse__c) {
				pn.OwnerId = nsi.Nurse__c;
				patientNotesToUpdate.add(pn);
			}

			if(null != nsi.Form__c && null != nsi.Nurse__c) {
				disco__Form__c form = discoFormsByIdMap.get(nsi.Form__c);
				form.OwnerId = nsi.Nurse__c;
				discoFormsToUpdate.add(form);
			}
		}
	}

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
	public void andFinally(){

		if(!patientNotesToUpdate.isEmpty())
			update patientNotesToUpdate;

		if(!discoFormsToUpdate.isEmpty())
			update discoFormsToUpdate;

	}


}
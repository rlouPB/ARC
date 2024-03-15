public with sharing class Nursing_ShiftTriggerHandler implements ITrigger {
	static Map<Id, Nursing_Shift__c> closedNursingShiftsById = new Map<Id, Nursing_Shift__c>();
	/**
	 * bulkBefore
	 *
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		set<id> closingIds = new Set<id>();
		for (Nursing_Shift__c ns : (List<Nursing_Shift__c>) Trigger.new) {
			if (ns.Status__c == 'Closed' && ns.Status__c != ((Nursing_Shift__c) Trigger.oldMap.get(ns.Id)).Status__c) {
				closingIds.add(ns.Id);
			}
		}

		if (closingIds.size() > 0) {
			closedNursingShiftsById = new Map<Id, Nursing_Shift__c>([SELECT Id, (SELECT Id FROM Nursing_Shift_Items__r WHERE Status__c = 'Open'), (SELECT Id FROM Nursing_Shift_Assignments__r WHERE Status__c = 'Open') FROM Nursing_Shift__c WHERE Id IN :closingIds]);
		}
	}

	/**
	 * bulkAfter
	 *
	 * This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		List<Nursing_Shift__c> closedNursingShifts = closedNursingShiftsById.values();
		List<Nursing_Shift_Assignment__c> allOpenNSAssignments = new List<Nursing_Shift_Assignment__c>();
		for (Nursing_Shift__c ns : closedNursingShifts) {
			if (null != ns.Nursing_Shift_Assignments__r && ns.Nursing_Shift_Assignments__r.size() > 0)
				allOpenNSAssignments.addAll(ns.Nursing_Shift_Assignments__r);
		}

		for (Nursing_Shift_Assignment__c nsa : allOpenNSAssignments) {
			nsa.Status__c = 'Closed';
			nsa.Sign_Out_Date_Time__c = System.now();
		}

		if (!allOpenNSAssignments.isEmpty()) {
			update allOpenNSAssignments;
		}
	}

	/**
	 * beforeInsert
	 *
	 * This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
	}

	/**
	 * beforeUpdate
	 *
	 * This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
		Nursing_Shift__c ns = (Nursing_Shift__c) so;
		Nursing_Shift__c nsOld = (Nursing_Shift__c) oldSo;

		if (closedNursingShiftsById.containsKey(ns.Id) && null != closedNursingShiftsById.get(ns.Id).Nursing_Shift_Items__r && closedNursingShiftsById.get(ns.Id).Nursing_Shift_Items__r.size() > 0) {
			Trigger.NewMap.get(ns.Id).addError('You cannot close the shift if it has open items.');
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
	}

	/**
	 * afterUpdate
	 *
	 * This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		Nursing_Shift__c ns = (Nursing_Shift__c) so;
		Nursing_Shift__c nsOld = (Nursing_Shift__c) oldSo;
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
	}
}
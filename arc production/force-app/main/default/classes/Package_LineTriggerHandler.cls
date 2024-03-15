public with sharing class Package_LineTriggerHandler implements ITrigger {
	/* @description
	 */
	private Map<Id, Account> patientMap;
	private Map<Id, Package__c> packageMap;
	private Map<Id, Prescription__c> prescriptionMap;
	private Map<Id, Package_Line__c> packageLineMap;

	/*******************************************************************************************************
	 * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		if (Trigger.isDelete) {
			Set<Id> packageIdSet = new Set<Id>();
			Set<Id> packageLineIdSet = new Set<Id>();

			for (Package_Line__c line : (List<Package_Line__c>) Trigger.old) {
				packageIdSet.add(line.Package__c);
				packageLineIdSet.add(line.Id);
			}

			packageMap = new Map<Id, Package__c>([SELECT Id, Name, Control_Group__c, Medications__c, Patient__c FROM Package__c WHERE Id IN :packageIdSet]);

			packageLineMap = new Map<Id, Package_Line__c>([SELECT Id, Name, Package__c, Package__r.Control_Group__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription__r.Control_Group__c, Prescription_Quantity__c FROM Package_Line__c WHERE Package__c IN :packageIdSet ORDER BY Prescription__r.Control_Group__c DESC]);

			Set<Id> prescriptionIds = new Set<Id>();

			for (Package_Line__c line : (List<Package_Line__c>) Trigger.old) {
				prescriptionIds.add(line.Prescription__c);
			}

			prescriptionMap = new Map<Id, Prescription__c>([SELECT Id, Medication_Filled_with__c, Medication_Format__c FROM Prescription__c WHERE Id IN :prescriptionIds]);
		} else {
			Set<Id> prescriptionIds = new Set<Id>();

			for (Package_Line__c line : (List<Package_Line__c>) Trigger.new) {
				prescriptionIds.add(line.Prescription__c);
			}

			prescriptionMap = new Map<Id, Prescription__c>([SELECT Id, Medication_Filled_with__c, Medication_Format__c FROM Prescription__c WHERE Id IN :prescriptionIds]);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		if (Trigger.isInsert) {
			Boolean isInsert = true;
			Set<Id> packageIdSet = new Set<Id>();
			Set<Id> packageLineIdSet = new Set<Id>();

			for (Package_Line__c line : (List<Package_Line__c>) Trigger.new) {
				packageIdSet.add(line.Package__c);
				packageLineIdSet.add(line.Id);
			}

			packageMap = new Map<Id, Package__c>([SELECT Id, Name, Control_Group__c, Medications__c, Patient__c FROM Package__c WHERE Id IN :packageIdSet]);
			packageLineMap = new Map<Id, Package_Line__c>([SELECT Id, Name, Package__c, Package__r.Control_Group__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription__r.Control_Group__c, Prescription_Quantity__c FROM Package_Line__c WHERE Package__c IN :packageMap.keySet() ORDER BY Prescription__r.Control_Group__c DESC]);

			PackageLineHelper.handlePackageLineChange(packageMap, packageLineMap, isInsert);
		}

		if (Trigger.isDelete) {
			Set<Id> packageIdSet = new Set<Id>();
			Set<Id> packageLineIdSet = new Set<Id>();

			for (Package_Line__c line : (List<Package_Line__c>) Trigger.old) {
				packageIdSet.add(line.Package__c);
			}

			packageMap = new Map<Id, Package__c>([SELECT Id, Name, Control_Group__c, Medications__c, Patient__c FROM Package__c WHERE Id IN :packageIdSet]);

			packageLineMap = new Map<Id, Package_Line__c>([SELECT Id, Name, Package__c, Package__r.Control_Group__c, Package__r.Medications__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription__r.Control_Group__c, Prescription_Quantity__c FROM Package_Line__c WHERE Package__c IN :packageMap.keySet() ORDER BY Prescription__r.Control_Group__c DESC]);

			PackageLineHelper.handlePackageLineRemove(packageMap, packageLineMap);
		}

		if (Trigger.isUpdate) {
			Boolean isInsert = false;
			Set<Id> packageIdSet = new Set<Id>();
			Set<Id> packageLineIdSet = new Set<Id>();

			for (Package_Line__c line : (List<Package_Line__c>) Trigger.new) {
				packageIdSet.add(line.Package__c);
				packageLineIdSet.add(line.Id);
			}

			packageMap = new Map<Id, Package__c>([SELECT Id, Name, Control_Group__c, Medications__c, Patient__c FROM Package__c WHERE Id IN :packageIdSet]);

			packageLineMap = new Map<Id, Package_Line__c>([SELECT Id, Name, Package__c, Package__r.Control_Group__c, Package__r.Medications__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription__r.Control_Group__c, Prescription_Quantity__c FROM Package_Line__c WHERE Package__c IN :packageMap.keySet() ORDER BY Prescription__r.Control_Group__c DESC]);

			PackageLineHelper.handlePackageLineChange(packageMap, packageLineMap, isInsert);

			disco.Util.updateAnswersInLinkedSections(Trigger.new, 'Package_Line__c');
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
		Package_Line__c pl = (Package_Line__c) so;
		Prescription__c prescription = prescriptionMap.get(pl.Prescription__c);
		if (null != prescription) {
			pl.Medication_and_Format__c = prescription.Medication_Filled_with__c + ' ' + prescription.Medication_Format__c;
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
		Package_Line__c pl = (Package_Line__c) so;
		Prescription__c prescription = prescriptionMap.get(pl.Prescription__c);
		if (null != prescription) {
			pl.Medication_and_Format__c = prescription.Medication_Filled_with__c + ' ' + prescription.Medication_Format__c;
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public void afterInsert(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
	}
}
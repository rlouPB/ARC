/**
 * @author Synaptic Advisors
 * @date 2022
 *
 * @group Accounts
 * @group-content ../../ApexDocContent/Accounts.htm
 *
 * @description Utility class to handle Printed Medical Record functionality
 */
public with sharing class MedRecordUtils {
	public static void deleteMedicalRecords(String patientId, Set<String> deleteRecords, String pmrRequestId) {
		List<String> patientNoteToBeDeleted = new List<String>();
		List<String> formToBeDeleted = new List<String>();
		List<String> egoToBeDeleted = new List<String>();
		List<String> caseToBeDeleted = new List<String>();
		List<String> procedureOrderToBeDeleted = new List<String>();
		for (String s : deleteRecords) {
			String[] parts = s.split(';');
			String docType = parts[1];
			String objId = parts[2];
			String sObjName = parts[3];
			switch on sObjName {
				when 'disco__Form__c' {
					formToBeDeleted.add(objId);
				}
				when 'EGO__c' {
					egoToBeDeleted.add(objId);
				}
				when 'Patient_Note__c' {
					patientNoteToBeDeleted.add(objId);
				}
				when 'Case' {
					caseToBeDeleted.add(objId);
				}
			}
		}

		List<Printed_Medical_Included_Record__c> includedObjects = [SELECT Id, SDoc_Junction__r.Id FROM Printed_Medical_Included_Record__c WHERE Printed_Medical_Record_Request__c = :pmrRequestId AND (SDoc_Junction__r.Youreka_Form__c IN :formToBeDeleted OR SDoc_Junction__r.Patient_Note__c IN :patientNoteToBeDeleted OR SDoc_Junction__r.EGO__c IN :egoToBeDeleted OR SDoc_Junction__r.Treatment_Plan__c IN :caseToBeDeleted) WITH SECURITY_ENFORCED];
		Map<String, Printed_Medical_Included_Record__c> deleteIncludedObjs = new Map<String, Printed_Medical_Included_Record__c>();
		Map<String, SDoc_Junction__c> deleteSDocJunctions = new Map<String, SDoc_Junction__c>();
		for (Printed_Medical_Included_Record__c included : includedObjects) {
			deleteIncludedObjs.put(included.Id, included);
		}

		if (deleteIncludedObjs.size() > 0) {
			delete deleteIncludedObjs.values();
		}
	}

	public static void createNewMedicalRecords(Map<String, PrintedMedicalRecordBase> printedMedicalRecordHandlers, Set<String> insertRecords, String requestId) {
		List<SDoc_Junction__c> sDocJunctions = new List<SDoc_Junction__c>();
		List<Printed_Medical_Included_Record__c> includedObjs = new List<Printed_Medical_Included_Record__c>();

		for (String s : insertRecords) {
			String[] parts = s.split(';');
			String docType = parts[1];
			String objId = parts[2];
			String sObjName = parts[3];
			SDoc_Junction__c junction = new SDoc_Junction__c(Object_SF_Id__c = '' + requestId + objId);
			PrintedMedicalRecordBase base2 = printedMedicalRecordHandlers.get(sObjName);
			junction.put(base2.getSDocJunctionLookupField(), objId);
			sDocJunctions.add(junction);
			includedObjs.add(new Printed_Medical_Included_Record__c(Printed_Medical_Record_Request__c = requestId, Document_Type__c = docType, External_Id__c = '' + requestId + objId, SDoc_Junction__r = new SDoc_Junction__c(Object_SF_Id__c = '' + requestId + objId)));
		}
		if (Schema.sObjectType.SDoc_Junction__c.fields.Object_SF_Id__c.isCreateable()) {
			upsert sDocJunctions Object_SF_Id__c;
		}

		if (Schema.sObjectType.Printed_Medical_Included_Record__c.fields.Printed_Medical_Record_Request__c.isCreateable()) {
			upsert includedObjs external_Id__c;
		}
	}
}
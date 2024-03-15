public with sharing class ListLabObservationController {
	public class LabObservationResponse {
		@AuraEnabled
		public List<Lab_Observation__c> labObservations { get; set; }
		@AuraEnabled
		public Map<String, List<CompediumEntryWrapper>> allBundles { get; set; }
		@AuraEnabled
		public Boolean isActive { get; set; }
	}

	@AuraEnabled
	public static LabObservationResponse loadLabObservationData(String procedureOrderId) {
		LabObservationResponse response = new LabObservationResponse();
		response.labObservations = getLabObservations(procedureOrderId);
		response.allBundles = retrieveBundles();
		Procedure_Order__c po = [SELECT Id, Active__c FROM Procedure_Order__c WHERE Id = :procedureorderId WITH SECURITY_ENFORCED];
		response.isActive = po.Active__c;
		return response;
	}

	@AuraEnabled
	public static List<Lab_Observation__c> getLabObservations(String procedureOrderId) {
		List<Lab_Observation__c> results = [SELECT Id, Name, Compendium_Entry__r.Name, Compendium_Entry__r.Test_Name__c, Procedure_Order__c, Compendium_Entry__r.Category__c, Compendium_Entry__r.Id, Lab_Test_Type__c, Order_Date__c, Collection_Date__c, Order_Id__c, Compendium_Entry__r.Query__c, Compendium_Entry__r.Query_Type__c, Query_Answer__c FROM Lab_Observation__c WHERE Procedure_Order__c = :procedureOrderId WITH SECURITY_ENFORCED ORDER BY Order_Date__c DESC NULLS FIRST];

		Lab_Observation__c labObservationToAdd = new Lab_Observation__c();
		results.add(labObservationToAdd);
		return results;
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, List<CompediumEntryWrapper>> retrieveBundles() {
		Map<String, List<CompediumEntryWrapper>> entryMap = new Map<String, List<CompediumEntryWrapper>>();

		for (Compendium_Bundle_Assignment__c ba : [SELECT Id, Compendium_Entry__r.Id, Compendium_Entry__r.Name, Compendium_Entry__r.Category__c, Compendium_Entry__r.Test_Name__c, Compendium_Bundle__r.Bundle_Name__c FROM Compendium_Bundle_Assignment__c WITH SECURITY_ENFORCED ORDER BY Compendium_Entry__r.Test_Name__c]) {
			if (!entryMap.containsKey(ba.Compendium_Bundle__r.Bundle_Name__c)) {
				entryMap.put(ba.Compendium_Bundle__r.Bundle_Name__c, new List<CompediumEntryWrapper>());
			}
			List<CompediumEntryWrapper> entries = entryMap.get(ba.Compendium_Bundle__r.Bundle_Name__c);
			entries.add(new CompediumEntryWrapper(ba.Compendium_Entry__r.Id, ba.Compendium_Entry__r.Name, ba.Compendium_Entry__r.Test_Name__c, ba.Compendium_Entry__r.Category__c));
		}

		return entryMap;
	}

	@AuraEnabled
	public static List<Lab_Observation__c> saveLabObservationFromBundle(String poId, String selectedEntryIds) {
		List<Lab_Observation__c> observations = new List<Lab_Observation__c>();
		list<String> tests = (list<String>) JSON.deserialize(selectedEntryIds, list<String>.class);

		for (String sfId : tests) {
			observations.add(new Lab_Observation__c(Procedure_Order__c = poID, Compendium_Entry__c = sfId, External_Id__c = poID + ';' + sfId));
		}
		upsert observations external_Id__c;

		return getLabObservations(poId);
	}

	@AuraEnabled
	public static void saveLabObservations(String input, String procedureOrderId) {
		JSONLOParser objParser = new JSONLOParser();
		List<JSONLOParser> listMeta = objParser.Parse(input);

		List<Lab_Observation__c> labObservationsToUpsert = new List<Lab_Observation__c>();
		List<Lab_Observation__c> labObservationsToDelete = new List<Lab_Observation__c>();

		for (JSONLOParser obj : listMeta) {
			if (String.isNotBlank(obj.compendiumEntryId)) {
				String externalId = procedureOrderId + ';' + obj.compendiumEntryId;
				Lab_Observation__c lo = new Lab_Observation__c(External_Id__c = externalId, Procedure_Order__c = procedureOrderId, Compendium_Entry__c = obj.compendiumEntryId);

				if (String.isNotBlank(obj.Id)) {
					lo.Id = obj.Id;
				}

				if (String.isNotBlank(obj.queryAnswer)) {
					lo.Query_Answer__c = obj.queryAnswer;
				}

				if (obj.isDeleted != 'true') {
					labObservationsToUpsert.add(lo);
				}

				if (obj.isDeleted == 'true') {
					labObservationsToDelete.add(lo);
				}
			}
		}

		delete labObservationsToDelete;
		upsert labObservationsToUpsert;
	}

	@AuraEnabled
	public static Lab_Observation__c getLabObservationInstance(String poId, String selectedEntryId) {
		Lab_Observation__c test = new Lab_Observation__c(Procedure_Order__c = poID, Compendium_Entry__c = selectedEntryId);
		Procedure_Order__c order = [SELECT Id, (SELECT Id FROM Procedure_Results__r) FROM Procedure_Order__c WHERE Id = :poId];
		for (Procedure_Result__c r : order.Procedure_Results__r) {
			test.Procedure_Result__c = r.Id;
		}
		insert test;
		Lab_Observation__c result = [SELECT Id, Name, Compendium_Entry__r.Name, Compendium_Entry__r.Test_Name__c, Procedure_Order__c, Compendium_Entry__r.Category__c, Compendium_Entry__r.Id, Lab_Test_Type__c, Order_Date__c, Collection_Date__c, Order_Id__c, Compendium_Entry__r.Query__c, Compendium_Entry__r.Query_Type__c, Query_Answer__c FROM Lab_Observation__c WHERE Id = :test.Id];
		return result;
	}

	public static string addLabObservation(String poId, String selectedEntryId) {
		String retId = '';
		Lab_Observation__c test = new Lab_Observation__c(Procedure_Order__c = poID, Compendium_Entry__c = selectedEntryId);
		Procedure_Order__c order = [SELECT Id, (SELECT Id FROM Procedure_Results__r) FROM Procedure_Order__c WHERE Id = :poId];
		for (Procedure_Result__c r : order.Procedure_Results__r) {
			test.Procedure_Result__c = r.Id;
		}
		insert test;
		retId = test.Id;
		return retId;
	}

	@AuraEnabled
	public static String getAdmissionID(String accountID) {
		Account currentAccount = [SELECT Current_Admission__c FROM Account WHERE ID = :accountID WITH SECURITY_ENFORCED];
		return currentAccount.Current_Admission__c;
	}

	public class JSONLOParser {
		public String Id;
		public String compendiumEntryId;
		public String startDate;
		public String endDate;
		public String isDeleted;
		public String queryAnswer;

		public List<JSONLOParser> parse(String json) {
			return (List<JSONLOParser>) System.JSON.deserialize(json, List<JSONLOParser>.class);
		}
	}
}
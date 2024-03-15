public class ActionItem_Util {
	public static void createInterventionChangeActionItems(Id[] treatmentPlanIds) {
		try {
			// ProcessLogging.addProcessLog('ActionItem_Util', 'treatmentPlanIds', JSON.serialize(treatmentPlanIds));
			map<id, set<id>> treatmentIdUsersMap = new Map<id, set<id>>();
			set<id> patientIds = new Set<id>();
			map<id, id> patientIdByCurrentTPId = new Map<id, id>();
			for (Case tp : [SELECT AccountId, Id FROM Case WHERE id IN :treatmentPlanIds]) {
				if (tp.AccountId != null) {
					patientIds.add(tp.AccountId);
					patientIdByCurrentTPId.put(tp.Id, tp.AccountId);
				}
			}

			// ProcessLogging.addProcessLog('ActionItem_Util', 'patientIds', JSON.serialize(patientIds));
			for (Assigned_Clinician__c ac : [SELECT User__c, Patient_Account__c, Patient_Account__r.Current_Case__c FROM Assigned_Clinician__c WHERE Patient_Account__c IN :patientIds AND User__c != NULL AND Patient_Account__r.Current_Case__c != NULL AND (NOT Role__c LIKE '%Team Leader%') AND (NOT Role__c LIKE '%Office%') AND Start_Date__c <= :Date.today() AND (End_Date__c = NULL OR End_Date__c > :Date.today())]) {
				if (!treatmentIdUsersMap.containsKey(ac.Patient_Account__r.Current_Case__c)) {
					treatmentIdUsersMap.put(ac.Patient_Account__r.Current_Case__c, new Set<id>());
				}
				treatmentIdUsersMap.get(ac.Patient_Account__r.Current_Case__c).add(ac.User__c);
			}
			// ProcessLogging.addProcessLog('ActionItem_Util', 'treatmentIdUsersMap', JSON.serialize(treatmentIdUsersMap));

			if (treatmentIdUsersMap.size() > 0) {
				list<Action_Item__c> items = new List<Action_Item__c>();
				for (Id tplanId : treatmentIdUsersMap.keyset()) {
					for (Id uid : treatmentIdUsersMap.get(tplanId)) {
						items.add(new Action_Item__c(OwnerId = uid, Account__c = patientIdByCurrentTPId.get(tplanId), Treatment_Plan__c = tplanId, Status__c = 'Open', RecordTypeId = RecordTypeHelper.getIdByName('Action_Item__c', 'Intervention Change')));
					}
				}
				if (items.size() > 0) {
					insert items;
				}
				// ProcessLogging.addProcessLog('ActionItem_Util.items', 'items', JSON.serialize(items));
			}
		} catch (Exception e) {
			ProcessLogging.quickProcessLog('ActionItem_Util', e.getStackTraceString(), e.getMessage());
		}
	}
}
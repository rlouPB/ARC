public with sharing class NoteItemSOHController {
	@AuraEnabled
	public static String getSOHSnapshotSubset(String noteId, String patientId, String noteType, String sohField) {
		String html = null;
		List<SnapShot__c> snapshots = [SELECT Id, SOH_Html__c FROM Snapshot__c WHERE Patient_Note__r.Account__c = :patientId AND Patient_Note__r.type__c = :noteType AND Patient_Note__r.Status__c = 'Finalized' ORDER BY Finalized_Date_Time__c DESC LIMIT 1];
		if (snapshots.size() > 0) {
			html = snapshots[0].SOH_Html__c;
		}

		return html;
	}
}
public without sharing class UserHomeApexControllerHelper {

    public static Boolean shouldShowClinicalPatientFile(Id accountId)
	{
		Account account = [SELECT Id, Current_Admission__r.Chart_Closed__c, Current_Admission__r.Stage__c FROM Account WHERE Id = :accountId];
		Set<String> stagesToHideTabsmyString = new Set<String>{'Open Inquiry', 'Active Inquiry', 'Waitlist', 'Declined', 'Withdrawn', 'Inactive'};
		if(account.Current_Admission__r.Chart_Closed__c || stagesToHideTabsmyString.contains(account.Current_Admission__r.Stage__c)) {
			
			String[] allowedProfileNames = new List<String>{'System Administrator', 'RiggsAdmissions'};
			Map<Id, Profile> profilesByIdMap = new Map<Id, Profile>([SELECT Id, Name from Profile where Name IN :allowedProfileNames]);

			if(profilesByIdMap.containsKey(UserInfo.getProfileId())) {
				return true;
			}

			if(FeatureManagement.checkPermission('Medical_Records')) {
				return true;
			}

			Access_Pass__c[] accessPasses = [SELECT Id FROM Access_Pass__c WHERE Requesting_User__c = :UserInfo.getUserId() AND Patient__c = :accountId AND Access_Removed__c = false AND (Access_End_Date__c = null OR Access_End_Date__c >= TODAY)];
			System.debug('accessPasses : ' + accessPasses);
			System.debug('UserInfo.getUserId() : ' + UserInfo.getUserId());
			System.debug('accountId : ' + accountId);

			if(null != accessPasses && accessPasses.size() > 0) {
				return true;
			}

			return false;
		} 

		return true;
	}

	public static Account getAccountById(Id accountId) {
		Account account = [SELECT Id, Current_Admission__r.Chart_Closed__c, Current_Admission__r.Stage__c FROM Account WHERE Id = :accountId];
		return account;
	}

	public static Map<String, String> getPostRenderConfig(Id accountId) {
		Map<String, String> configMap = new Map<String, String>();
		Account account = getAccountById(accountId);
		configMap.put('admissionChartClosed', account.Current_Admission__r.Chart_Closed__c ? 'true' : 'false');
		configMap.put('admissionStage', account.Current_Admission__r.Stage__c);
		configMap.put('userIsMedRecords', FeatureManagement.checkPermission('Medical_Records') ? 'true' : 'false');
		configMap.put('shouldShowClinicalPatientFile', shouldShowClinicalPatientFile(accountId) ? 'true' : 'false');
		return configMap;
	}
}
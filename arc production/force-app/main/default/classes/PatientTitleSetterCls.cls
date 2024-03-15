public with sharing class PatientTitleSetterCls {
	@AuraEnabled(cacheable=true)
	public static string getPageTitle(string recordId) {
		try {
			if (recordId.startsWith('001')) {
				return [SELECT Document_Title__c FROM Account WHERE Id = :recordId LIMIT 1].Document_Title__c;
				// Account acc = [SELECT Patient_Contact__r.Abbreviated_Name__c FROM Account WHERE Id = :recordId LIMIT 1];
				// return acc.Patient_Contact__r.Abbreviated_Name__c + ' | Account';
			} else if (recordId.startsWith('003')) {
				return [SELECT Document_Title__c FROM Contact WHERE Id = :recordId LIMIT 1].Document_Title__c;
				// Contact c = [SELECT Abbreviated_Name__c FROM Contact WHERE Id = :recordId LIMIT 1];
				// return c.Abbreviated_Name__c + ' | Contact';
			}
		} catch (Exception ex) {
		}

		return null;
	}
}
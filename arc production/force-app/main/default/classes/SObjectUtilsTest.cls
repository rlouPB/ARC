@isTest
public class SObjectUtilsTest {
	@testSetup
	static void setup() {
	}

	@isTest
	static void test() {
		SObjectUtils.isValidSObject('Opportunity');
		SObjectUtils.isSObjectAccessible('Opportunity');
		SObjectUtils.getAccessibleDescribeFieldResult('Opportunity', 'Name');
		SObjectUtils.getAccessiblePicklistEntryList('Opportunity', 'npsp__Acknowledgment_Status__c');
		SObjectUtils.isValidField('Opportunity', 'npsp__Acknowledgment_Status__c');
		Set<String> fieldList = new Set<String>{ 'npsp__Acknowledgment_Status__c', 'npsp__Matching_Gift_Status__c', 'npsp__Tribute_Notification_Status__c' };
		SObjectUtils.getAccessibleFieldNameSet('Opportunity', fieldList);
		// SObjectUtils.getFieldValue('Account', 'Account__r.Patient_Contact__r.FirstName');
		// SObjectUtils.getCurrentAppName();
	}
}
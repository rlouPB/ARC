@isTest
public class MultiSelectPicklistCtlTest {
	@isTest
	static void testgetMultiSelectPicklistOptions() {
		MultiSelectPicklistCtl.getMultiSelectPicklistOptions('Prescription__c', 'Location__c');
	}
}
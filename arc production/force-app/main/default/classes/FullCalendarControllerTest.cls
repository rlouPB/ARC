@isTest
private class FullCalendarControllerTest {
	// TODO: Implement "real" assert statements; might require actual test data setup
	@isTest
	static void calendarTest1() {
		System.Test.startTest();
		List<Object> events = FullCalendarController.getEventsNearbyDynamic(Date.today(), Date.today().addDays(5), 'Meeting__c', 'Subject__c', 'Start_Date_Time__c', 'End_Date_Time__c', null, 'All_Day_Meeting__c', null);
		//System.assertEquals(true, m.containsKey('Account.Name'), 'Should have return Account.Name field.');
		//System.assertEquals(true, m.get('Account.Name'), 'Should have had access to the Account.Name field.');
		System.Test.stopTest();
	}
}
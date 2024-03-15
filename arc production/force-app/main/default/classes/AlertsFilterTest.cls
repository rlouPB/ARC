@IsTest
class AlertsFilterTest {
	@TestSetup
	static void makeData() {
	}

	static testMethod void testProcessAlerts() {
		List<Id> recordIds = new List<Id>();

		Credential__c c = new Credential__c();
		c.User__c = userinfo.getUserId();
		insert c;
		recordids.add(C.id);
		Test.startTest();
		AlertsFilter.processAlerts(recordIds);
		object a = AlertsFilter.alertScenariosMap;
		AlertsFilter.valuesMatch(0, '==', 0);

		AlertsFilter.valuesMatch(0, '>=', 0);
		AlertsFilter.valuesMatch(0, '>', 0);
		AlertsFilter.valuesMatch(0, '<=', 0);
		AlertsFilter.valuesMatch(0, '<', 0);
		AlertsFilter.valuesMatch(0, '<>', 0);
		AlertsFilter.valuesMatch(0, 'ISBLANK', 0);
		Test.stopTest();
	}
}
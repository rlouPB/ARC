@isTest
public class NursingShiftGenericItemsServiceTest {
	@testSetup
	static void setup() {
		Nursing_Shift__c shift = new Nursing_Shift__c(Shift_Number__c = '1st', Date__c = Date.today().addDays(1), Status__c = 'New', Type_of_Day__c = 'Weekday');
		insert shift;

		Nursing_Shift_Item__c nsi = new Nursing_Shift_Item__c(Due_Date__c = date.today(), Status__c = 'Open', Nursing_Shift__c = shift.Id);
		insert nsi;
	}

	@isTest
	static void test() {
		Nursing_Shift_Item__c nsi = [SELECT Id, Nursing_Shift__c FROM Nursing_Shift_Item__c ORDER BY CreatedDate DESC LIMIT 1];
		Test.startTest();
		NursingShiftGenericItemsService.getGenericItems(nsi.Nursing_Shift__c);
		Test.stopTest();
	}

	@isTest
	static void testCloseGenericItem() {
		Nursing_Shift_Item__c nsi = [SELECT Id, Nursing_Shift__c FROM Nursing_Shift_Item__c ORDER BY CreatedDate DESC LIMIT 1];
		Test.startTest();
		NursingShiftGenericItemsService.closeGenericItem(nsi.Id);
		Test.stopTest();
	}
}
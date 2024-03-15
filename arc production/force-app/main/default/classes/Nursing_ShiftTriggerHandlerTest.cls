@IsTest
public with sharing class Nursing_ShiftTriggerHandlerTest {
	@TestSetup
	public static void setup() {
		Nursing_Shift__c ns = new Nursing_Shift__c(Shift_Number__c = '1st', Date__c = Date.Today(), Status__c = 'Open', Shift_Open_Date_Time__c = System.now(), Type_of_Day__c = 'Weekday');
		insert ns;

		Nursing_Shift_Assignment__c nsa = new Nursing_Shift_Assignment__c(Owner__c = UserInfo.getUserId(), OwnerId = UserInfo.getUserId(), Nursing_Shift__c = ns.Id, Sign_In_Date_Time__c = System.now(), Status__c = 'Open');
		insert nsa;
	}

	@IsTest
	public static void testSignOutNurses() {
		test.startTest();
		List<Nursing_Shift__c> nursingShifts = [SELECT Id, (SELECT Id FROM Nursing_Shift_Items__r WHERE Status__c = 'Open'), (SELECT Id FROM Nursing_Shift_Assignments__r WHERE Status__c = 'Open') FROM Nursing_Shift__c];

		System.assert(nursingShifts[0].Nursing_Shift_Assignments__r.size() > 0);

		Nursing_Shift__c ns = nursingShifts[0];
		ns.Status__c = 'Closed';
		update ns;

		List<Nursing_Shift_Assignment__c> nsas = [SELECT Id, Status__c FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :ns.Id];
		System.assertEquals('Closed', nsas[0].Status__c);

		test.stopTest();
	}
}
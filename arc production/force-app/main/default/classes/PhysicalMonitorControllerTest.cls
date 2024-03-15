@isTest
public class PhysicalMonitorControllerTest {
	private static final String CUFF_SIZE = 'Large';
	private static final String ACCOUNT_NAME = 'Patient Test Account';

	@testSetup
	static void initiateData() {
		Account accounts = new Account(Name = ACCOUNT_NAME, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId());
		insert accounts;

		Admission__c admission = (Admission__c) TestFactory_Patient.createSObject(new Admission__c(Patient_Account__c = accounts.Id, Team__c = 'A', Height_in__c = 2, BP_Cuff_Size__c = CUFF_SIZE), true);

		Physical_Monitor__c physicalMonitor = new Physical_Monitor__c(Height_in__c = 80, BP_Cuff_Size__c = CUFF_SIZE, Account__c = accounts.Id);
		insert physicalMonitor;

		Nursing_Shift_Item__c shiftItem = new Nursing_Shift_Item__c(Status__c = 'Open', Physical_Monitor__c = physicalMonitor.Id);
		insert shiftItem;
	}

	@isTest
	private static void getPhysicalMonitorByAccountIdTest() {
		List<Account> accounts = [SELECT Id FROM Account];
		PhysicalMonitorController p = new PhysicalMonitorController();
		Test.startTest();
		List<Physical_Monitor__c> physicalMonitor = PhysicalMonitorController.getPhysicalMonitorByAccountId(accounts[0].Id);
		try {
			PhysicalMonitorController.getPhysicalMonitorByAccountId(null);
		} catch (exception ex) {
		}
		Test.stopTest();

		System.assert(!physicalMonitor.isEmpty());
	}

	@isTest
	private static void getPhysicalMonitorByNursingShiftItemIdTest() {
		List<Nursing_Shift_Item__c> shiftItem = [SELECT Id FROM Nursing_Shift_Item__c];
		List<Physical_Monitor__c> physicalMonitorList = [SELECT Id FROM Physical_Monitor__c];

		Test.startTest();
		Physical_Monitor__c physicalMonitor = PhysicalMonitorController.getPhysicalMonitorByNursingShiftItemId(shiftItem[0].Id);
		try {
			PhysicalMonitorController.getPhysicalMonitorByNursingShiftItemId(null);
		} catch (exception ex) {
		}

		Test.stopTest();

		System.assertEquals(physicalMonitorList[0].Id, physicalMonitor.Id);
	}

	@isTest
	private static void createUpdatePhysicalMonitorTest() {
		List<Admission__c> admiss = [SELECT Id FROM Admission__c];

		List<Account> accounts = [SELECT Id, Current_Admission__c FROM Account];
		accounts[0].Current_Admission__c = admiss[0].Id;
		update accounts;
		List<Physical_Monitor__c> physicalMonitorList = [SELECT Id, Account__c FROM Physical_Monitor__c];

		PhysicalMonitorController.PhysicalMonitorWrapper wrapper = new PhysicalMonitorController.PhysicalMonitorWrapper();
		wrapper.PhysicalMonitor = physicalMonitorList[0];
		wrapper.IsUpdate = true;

		Test.startTest();
		String physicalResponse = PhysicalMonitorController.createUpdatePhysicalMonitor(JSON.serialize(wrapper));
		try {
			PhysicalMonitorController.createUpdatePhysicalMonitor(null);
		} catch (exception ex) {
		}
		Test.stopTest();
	}
}
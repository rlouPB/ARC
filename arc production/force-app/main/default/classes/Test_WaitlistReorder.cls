@isTest
public class Test_WaitlistReorder {
	@testSetup
	static void setup() {
		PatientFileTestDataUtil.createPatientWithAdmission();

		Contact con = [SELECT Id FROM Contact WHERE Name = 'TestPatient_1' LIMIT 1];
		List<Admission__c> admList = [SELECT Id, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Patient_Contact__c = :con.Id];
		admList[0].Waitlist_Order__c = 1;
		admList[0].Service_Type__c = 'Residential';
		update admList[0];
		admList[1].Waitlist_Order__c = 2;
		admList[1].Service_Type__c = 'Residential';
		update admList[1];
		admList[2].Waitlist_Order__c = 3;
		admList[2].Service_Type__c = 'Residential';
		update admList[2];
		admList[3].Waitlist_Order__c = 4;
		admList[3].Service_Type__c = 'Residential';
		update admList[3];
	}

	public static testMethod void reorderWaitlistTest() {
		Test.startTest();

		Contact con = [SELECT Id FROM Contact WHERE Name = 'TestPatient_1' LIMIT 1];
		List<Admission__c> admList = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Patient_Contact__c = :con.Id];
		List<Admission__c> adm = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Waitlist_Order__c = 3 AND Patient_Contact__c = :con.Id LIMIT 1];
		Map<Id, Admission__c> admMap = new Map<Id, Admission__c>();
		Admission__c nextAdm = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Waitlist_Order__c = 1 AND Patient_Contact__c = :con.Id LIMIT 1];

		admMap.putAll(admList);
		adm[0].Waitlist_Order__c = 1;
		update adm;

		WaitlistReorder.addToWaitlist(adm, admMap);
		WaitlistReorder.reorderWaitlist(adm, admMap);

		Admission__c afterUpdateAdm = [SELECT Id, Name, Stage__c, Waitlist_Order__c FROM Admission__c WHERE Id = :adm[0].Id AND Patient_Contact__c = :con.Id];
		System.assertEquals(1, afterUpdateAdm.Waitlist_Order__c);

		Test.stopTest();
	}

	public static testMethod void removeWaitOrderTest() {
		Test.startTest();

		Contact con = [SELECT Id, AccountId FROM Contact WHERE Name = 'TestPatient_1' LIMIT 1];
		List<Admission__c> admList = [SELECT Id, Name, Stage__c, Waitlist_Order__c FROM Admission__c WHERE Patient_Contact__c = :con.Id];
		List<Admission__c> adm = [SELECT Id, Name, Stage__c, Waitlist_Order__c FROM Admission__c WHERE Waitlist_Order__c = 2 AND Patient_Contact__c = :con.Id];
		Map<Id, Admission__c> admMap = new Map<Id, Admission__c>();
		Admission__c nextAdm = [SELECT Id, Name, Stage__c, Waitlist_Order__c FROM Admission__c WHERE Waitlist_Order__c = 3 AND Patient_Contact__c = :con.Id LIMIT 1];

		admMap.putAll(admList);
		adm[0].Waitlist_Order__c = null;
		update adm;

		WaitlistReorder.addToWaitlist(adm, admMap);
		WaitlistReorder.reorderWaitlist(adm, admMap);

		Admission__c afterAdm = [SELECT Id, Name, Stage__c, Waitlist_Order__c FROM Admission__c WHERE Id = :nextAdm.Id AND Patient_Contact__c = :con.Id];
		System.assertEquals(2, afterAdm.Waitlist_Order__c);

		Test.stopTest();
	}

	public static testMethod void addToWaitlistTest() {
		Test.startTest();

		Contact con = [SELECT Id, AccountId FROM Contact WHERE Name = 'TestPatient_1' LIMIT 1];
		List<Admission__c> admList = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Patient_Contact__c = :con.Id];
		List<Admission__c> adm = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Waitlist_Order__c = 2 AND Patient_Contact__c = :con.Id];
		Admission__c nextAdm = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Waitlist_Order__c = 3 AND Patient_Contact__c = :con.Id LIMIT 1];
		Map<Id, Admission__c> admMap = new Map<Id, Admission__c>();

		admMap.putAll(admList);
		admMap.put(adm[0].Id, new Admission__c(Id = adm[0].Id, Stage__c = 'Active Inquiry', Service_Type__c = 'Residential'));

		adm[0].Waitlist_Order__c = null;
		adm[0].Stage__c = 'Waitlist';
		//update adm;

		WaitlistReorder.addToWaitlist(adm, admMap);
		system.assertEquals(5, adm[0].Waitlist_Order__c);

		Test.stopTest();
	}

	public static testMethod void removeFromWaitlistTest() {
		Test.startTest();

		Contact con = [SELECT Id, AccountId FROM Contact WHERE Name = 'TestPatient_1' LIMIT 1];
		List<Admission__c> admList = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Patient_Contact__c = :con.Id];
		List<Admission__c> adm = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Waitlist_Order__c = 2 AND Patient_Contact__c = :con.Id];
		Admission__c nextAdm = [SELECT Id, Name, Stage__c, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Waitlist_Order__c = 3 AND Patient_Contact__c = :con.Id LIMIT 1];
		Map<Id, Admission__c> admMap = new Map<Id, Admission__c>();

		admMap.putAll(admList);
		admMap.put(adm[0].Id, new Admission__c(Id = adm[0].Id, Stage__c = 'Waitlist', Waitlist_Order__c = 2, Service_Type__c = 'Residential'));

		adm[0].Stage__c = 'Active Inquiry';
		//update adm;

		WaitlistReorder.addToWaitlist(adm, admMap);
		system.assertEquals(null, adm[0].Waitlist_Order__c);

		Test.stopTest();
	}

	public static testMethod void reorderWaitlistExceptionTest() {
		try {
			Contact con = [SELECT Id, AccountId FROM Contact WHERE Name = 'TestPatient_1' LIMIT 1];
			List<Admission__c> admList = [SELECT Id, Name, Stage__c, Waitlist_Order__c FROM Admission__c WHERE Patient_Contact__c = :con.Id];
			Map<Id, Admission__c> admMap = new Map<Id, Admission__c>();

			admMap.putAll(admList);
			WaitlistReorder.reorderWaitlist(admList, admMap);
		} catch (Exception e) {
			System.assertEquals('Please update only one Waitlist inquiry at a time', e.getMessage());
		}
	}
}
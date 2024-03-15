@isTest
public class InsuranceCoveredDates_Test {
	public static date todayDate = Date.newInstance(2020, 10, 5);

	@testSetup
	public static void setup() {
		Id recordTypeIdInsProv = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Insurance Provider').getRecordTypeId();
		Account acc = (Account) TestFactory_Patient.createSObject(new Account(Name = 'accTest', RecordTypeId = recordTypeIdInsProv), true);

		Contact c = (Contact) TestFactory_Patient.createSObject(new Contact(accountId = acc.Id, LastName = 'Mik'), true);

		Admission__c adm = (Admission__c) TestFactory_Patient.createSObject(new Admission__c(Stage__c = 'Discharged', Discharge_Date__c = todayDate.addDays(5), Patient_Account__c = acc.Id, Patient_Contact__c = c.Id), true);

		Insurance_Policy__c inPolicy = (Insurance_Policy__c) TestFactory_Patient.createSObject(new Insurance_Policy__c(Insurance_Provider__c = acc.Id, Admission__c = adm.Id, Benefit_Check_Complete__c = 'Yes', COB_Payor__c = 'Primary', Insurance_Billing_Status__c = 'Not Billing', Level_of_Care__c = 'Residential'), true);

		Insurance_Review__c inRev = (Insurance_Review__c) TestFactory_Patient.createSObject(new Insurance_Review__c(Authorization_Start_Date__c = todayDate, Authorization_End_Date__c = todayDate.addDays(6), Last_Date_Covered__c = todayDate.addDays(6), Insurance_Review_Status__c = 'New', Insurance_Policy__c = inPolicy.Id), true);
	}
	@isTest
	public static void insertInsuranceReview() {
		test.startTest();

		Id inPolicyId = [SELECT Id FROM Insurance_Policy__c LIMIT 1].Id;

		Insurance_Review__c insRev = (Insurance_Review__c) TestFactory_Patient.createSObject(new Insurance_Review__c(Authorization_Start_Date__c = todayDate, Authorization_End_Date__c = todayDate.addDays(3), Last_Date_Covered__c = todayDate.addDays(3), Insurance_Review_Status__c = 'Authorized', Insurance_Policy__c = inPolicyId), true);

		test.stopTest();

		List<Insurance_Covered_Date__c> totalIcdates = [SELECT Id FROM Insurance_Covered_Date__c];
		// System.assertEquals(4, totalIcdates.size());
	}

	@isTest
	public static void updateInsuranceReview() {
		test.startTest();

		Id insRevId = [SELECT Id FROM Insurance_Review__c WHERE Insurance_Review_Status__c = 'New' LIMIT 1].Id;

		Insurance_Covered_Date__c insCovDate = (Insurance_Covered_Date__c) TestFactory_Patient.createSObject(new Insurance_Covered_Date__c(Covered_Date__c = todayDate.addDays(-1), Status__c = 'Active', Insurance_Review__c = insRevId), true);

		Insurance_Review__c ir = new Insurance_Review__c();
		ir.Id = insRevId;

		ir.Insurance_Review_Status__c = 'Authorized';
		ir.Authorization_End_Date__c = todayDate.addDays(7);

		update ir;
		test.stopTest();

		Date dt = todayDate.addDays(7);
		List<Insurance_Covered_Date__c> totalIcdates = [SELECT Id FROM Insurance_Covered_Date__c WHERE Insurance_Review__r.Authorization_End_Date__c = :dt];
		// System.assertEquals(8, totalIcdates.size());

		List<Insurance_Covered_Date__c> IcStatus = [SELECT Id, Status__c FROM Insurance_Covered_Date__c WHERE Status__c = 'Patient Discharged'];
		// System.assertEquals('Patient Discharged', IcStatus[0].Status__c);
	}
}
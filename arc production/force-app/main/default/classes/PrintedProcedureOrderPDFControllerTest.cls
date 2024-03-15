@isTest
public class PrintedProcedureOrderPDFControllerTest {
	@testSetup
	static void setup() {
		Account a = new Account(Name = 'test patietnm');
		insert a;

		Contact c = new Contact(FirstName = 'test', LastName = 'patient contact', AccountId = a.Id);
		insert c;

		Admission__c adm = new Admission__c(Patient_Account__c = c.AccountId, Patient_Contact__c = c.Id, Stage__c = 'Open Inquiry');
		insert adm;

		Procedure_Order__c procedureOrder = new Procedure_Order__c(Patient_Account__c = a.Id, Admission__c = adm.Id, RecordtypeId = Schema.SObjectType.Procedure_Order__c.getRecordTypeInfosByDeveloperName().get('Lab_Order').getRecordTypeId(), Date_of_Order__c = System.today(), Activation_Date__c = System.today().addDays(1), Repeating__c = false, Related_Records__c = 'Physical Monitor', Status__c = 'Draft', Active__c = false, Executed__c = false);

		insert procedureOrder;
	}

	@isTest
	static void test() {
		Test.startTest();
		PrintedProcedureOrderPDFController ctrl = new PrintedProcedureOrderPDFController();
		Test.stopTest();
	}
}
@isTest
public class Admitted_ProgramStatusTriggerHandlerTest {
	private static final String ADMITTED_PAS_STATUS = 'Program Assessment Status (PAS)';

	@TestSetup
	private static void initiateData() {
		Account patient = new Account(Name = 'patient1', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId());
		insert patient;

		Program__c p = new Program__c(Short_Name__c = 'test');
		insert p;

		Admitted_Program__c ap = new Admitted_Program__c(Program__c = p.Id, Start_Date__c = system.today());
		insert ap;

		Admission__c am = new Admission__c(Patient_Account__c = patient.Id, current_admitted_program__c = ap.id);
		insert am;

		Nursing_Shift__c ns = new Nursing_Shift__c(Shift_Number__c = '1st', Date__c = Date.Today(), Status__c = 'New', Shift_Open_Date_Time__c = System.now(), Type_of_Day__c = 'Weekday');
		insert ns;

		Nursing_Shift_Assignment__c nsa = new Nursing_Shift_Assignment__c(Owner__c = UserInfo.getUserId(), OwnerId = UserInfo.getUserId(), Nursing_Shift__c = ns.Id, Sign_In_Date_Time__c = System.now(), Status__c = 'Open');
		insert nsa;

		disco__Form_Template__c[] formTemplates = new List<disco__Form_Template__c>{ new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use') };
		insert formTemplates;
	}

	@isTest
	private static void createShiftsTest() {
		List<Admitted_Program__c> admittedProgram = [SELECT Id FROM Admitted_Program__c];

		Admitted_Program_Status__c programStatus = new Admitted_Program_Status__c(Admitted_Program__c = admittedProgram[0].Id, Start_Date_Time__c = system.now().addDays(-1), End_Date_Time__c = system.now().addDays(2), Status__c = ADMITTED_PAS_STATUS);
		insert programStatus;
	}

	@isTest
	private static void deleteShiftsTest() {
		List<Admitted_Program__c> admittedProgram = [SELECT Id FROM Admitted_Program__c];

		Admitted_Program_Status__c programStatus = new Admitted_Program_Status__c(Admitted_Program__c = admittedProgram[0].Id, Start_Date_Time__c = system.now().addDays(-1), End_Date_Time__c = system.now().addDays(2), Status__c = ADMITTED_PAS_STATUS);
		insert programStatus;

		List<Admitted_Program_Status__c> status = [SELECT Id, End_Date_Time__c FROM Admitted_Program_Status__c];
		status[0].End_Date_Time__c = status[0].End_Date_Time__c.addDays(-1);
		update status;
	}
}
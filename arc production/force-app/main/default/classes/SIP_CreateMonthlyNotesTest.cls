@IsTest
public with sharing class SIP_CreateMonthlyNotesTest {
	@TestSetup
	public static void setup() {
		ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();

		Contact c = (Contact) TestFactory_Patient.createSObject(new Contact(LastName = 'Test_Patient'), true);

		Contact accountWithContact = [SELECT Id, AccountId FROM Contact WHERE Id = :c.Id];

		Admission__c admission = (Admission__c) TestFactory_Patient.createSObject(new Admission__c(Patient_Account__c = accountWithContact.AccountId, Stage__c = 'Admitted', Patient_Contact__c = c.Id, Psychotherapist__c = userinfo.getuserid(), Team__c = 'A'), true);
		admission.Service_Type__c = 'Residential';
		update admission;

		disco__Form_Template__c discoFormTemplate = (disco__Form_Template__c) TestFactory_Patient.createSObject(new disco__Form_Template__c(Name = 'Admissions Screening Checklist 1', disco__Status__c = 'In Use'), true);

		List<Account> accounts = [SELECT Id, Name, Current_Admission__c, Current_Admission__r.Service_Type__c FROM Account WHERE Id = :accountWithContact.AccountId];
		accounts[0].Current_Admission__c = admission.Id;
		upsert accounts;

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{ new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id), new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id) };
		insert relatedContacts;

		List<disco__Form__c> discoForms = new List<disco__Form__c>{
			new disco__Form__c(disco__Form_Account__c = accounts[0].Id, Related_Contact__c = relatedContacts[0].Id, disco__Form_Template__c = discoFormTemplate.Id, disco__Archived__c = true, Admission__c = admission.Id, disco__Form_Contact__c = c.Id, disco__Mobile_ID__c = '123'),
			new disco__Form__c(disco__Form_Account__c = accounts[0].Id, Related_Contact__c = relatedContacts[1].Id, disco__Form_Template__c = discoFormTemplate.Id, disco__Archived__c = true, Admission__c = admission.Id, disco__Form_Contact__c = c.Id, disco__Mobile_ID__c = '1231')
		};
		insert discoForms;

		List<disco__Question__c> discoQuestions = new List<disco__Question__c>{ new disco__Question__c(disco__Form_Template__c = discoFormTemplate.Id, disco__Label__c = 'test', disco__Type__c = 'Picklist', Selected_Question_Order__c = 1, disco__Order__c = 1, Alternate_Question_Order__c = 1) };
		insert discoQuestions;

		List<disco__Answer__c> discoAnswers = new List<disco__Answer__c>{
			new disco__Answer__c(disco__Answer__c = 'test', disco__Form__c = discoForms[1].Id, disco__Question__c = discoQuestions[0].Id),
			new disco__Answer__c(disco__Answer__c = 'test', disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id),
			new disco__Answer__c(disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id),
			new disco__Answer__c(disco__Answer__c = 'test12', disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id),
			new disco__Answer__c(disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id)
		};
		insert discoAnswers;

		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];

		Program__c p = new Program__c(Name = 'VHPe', Short_Name__c = 'VHPe', Product_Code__c = 'VHPe');
		insert p;

		Admitted_Program__c ap = new Admitted_Program__c(Program__c = p.Id, start_date__c = system.today());
		insert ap;

		update new Admission__c(Id = admission.Id, Stage__c = 'Admitted', Psychotherapist__c = userinfo.getuserid(), Current_Admitted_Program__c = ap.Id);
	}

	public static testMethod void test() {
		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [SELECT Id, sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ScheduledItemProcessor_Parameters__c, MasterLabel FROM Scheduled_Item_Definition__mdt WHERE ScheduledItemProcessor_to_Use__c = 'CreateMonthlyNotes'];

		Scheduled_Item_Run__c custSetting = new Scheduled_Item_Run__c(Name = 'CreateMonthlyNotes', Scheduled_Item_Def__c = scheduledItemDefs[0].Id, Scheduled_Item_Def_Status__c = 'Active', Retry_Count__c = 0, Next_Run_Datetime__c = system.today().addDays(-1));
		insert custSetting;

		Test.startTest();
		new SIP_CreateMonthlyNotes();
		SIP_CreateMonthlyNotes.process(scheduledItemDefs);

		Test.stopTest();
	}

	public static testMethod void test2() {
		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [SELECT Id, sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ScheduledItemProcessor_Parameters__c, MasterLabel FROM Scheduled_Item_Definition__mdt WHERE ScheduledItemProcessor_to_Use__c = 'CreateMonthlyNotes'];
		// Scheduled_Item_Run__c custSetting = new Scheduled_Item_Run__c(
		// 	Name = 'CreateMonthlyNotes',
		// 	Scheduled_Item_Def__c = scheduledItemDefs[0].Id,
		// 	Scheduled_Item_Def_Status__c = 'Inactive',
		// 	Retry_Count__c = 0
		// );
		// insert custSetting;

		Test.startTest();
		SIP_CreateMonthlyNotes.process(scheduledItemDefs);
		SIP_CreateMonthlyNotes.process(null);

		Test.stopTest();
	}

	// public static testMethod void testLeftOverShifts() {
	// 	Nursing_Shift_Item__c nsi = new Nursing_Shift_Item__c(Shift_Date__c = system.today().addDays(1), Shift_Number__c = '1st');
	// 	insert nsi;

	// 	Test.startTest();
	// 	SIP_CreateMonthlyNotes.processLogic();
	// 	Test.stopTest();

	// 	nsi = [SELECT Nursing_Shift__c FROM Nursing_Shift_Item__c WHERE Id = :nsi.Id];

	// 	System.assertNotEquals(null, nsi.Nursing_Shift__c, 'Left over NSI should have been assigned a Nursing Shift');
	// }

	// public static testMethod void testProcessLeftOverShiftItemsFromTrigger() {
	// 	SIP_DailyNursingShifts.processLogic();

	// 	Test.startTest();
	// 	TriggerFactory.Recursions.clear();
	// 	Nursing_Shift_Item__c nsi = new Nursing_Shift_Item__c(Shift_Date__c = System.today().addDays(1), Shift_Number__c = '1st');
	// 	insert nsi;
	// 	Test.stopTest();

	// 	nsi = [SELECT Nursing_Shift__c FROM Nursing_Shift_Item__c WHERE Id = :nsi.Id];

	// 	System.assertNotEquals(null, nsi.Nursing_Shift__c, 'Left over NSI should have been assigned a Nursing Shift on trigger');
	// }
}
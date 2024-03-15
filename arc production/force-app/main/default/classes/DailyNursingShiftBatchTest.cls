@isTest
public with sharing class DailyNursingShiftBatchTest {

    @TestSetup
	public static void setup(){
		ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();
		Contact c = (Contact) TestFactory_Patient.createSObject(
		new Contact(LastName = 'Test_Patient'),
		true
		);
		Contact accountWithContact = [
		SELECT Id, AccountId
		FROM Contact
		WHERE Id = :c.Id
		];

		Admission__c admission = (Admission__c) TestFactory_Patient.createSObject(
		new Admission__c(
			Patient_Account__c = accountWithContact.AccountId,
			Stage__c='Admitted',
			Patient_Contact__c = c.Id,
			Psychotherapist__c = userinfo.getuserid(),
			Team__c = 'A'
		),
		true
		);
		admission.Service_Type__c = 'Residential';
		update admission;

		disco__Form_Template__c discoFormTemplate = (disco__Form_Template__c) TestFactory_Patient.createSObject(
		new disco__Form_Template__c(
			Name = 'Admissions Screening Checklist 1',
			disco__Status__c = 'In Use'
		),
		true
		);

        disco__Form_Template__c discoFormTemplateVerify = (disco__Form_Template__c) TestFactory_Patient.createSObject(
		new disco__Form_Template__c(
			Name = 'Verification_Rec_Psychiatrist_Transfer',
			disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
		),
		true
		);
        
        
		List<Account> accounts = [
		SELECT
			Id,
			Name,
			Current_Admission__c,
			Current_Admission__r.Service_Type__c
		FROM Account
		WHERE Id = :accountWithContact.AccountId
		];
		accounts[0].Current_Admission__c = admission.Id;
		upsert accounts;

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
		new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id),
		new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id)
		};
		insert relatedContacts;

		List<disco__Form__c> discoForms = new List<disco__Form__c>{
		new disco__Form__c(
			disco__Form_Account__c = accounts[0].Id,
			Related_Contact__c = relatedContacts[0].Id,
			disco__Form_Template__c = discoFormTemplate.Id,
			disco__Archived__c = true,
			Admission__c = admission.Id,
			disco__Form_Contact__c = c.Id,
			disco__Mobile_ID__c = '123'
		),
		new disco__Form__c(
			disco__Form_Account__c = accounts[0].Id,
			Related_Contact__c = relatedContacts[1].Id,
			disco__Form_Template__c = discoFormTemplate.Id,
			disco__Archived__c = true,
			Admission__c = admission.Id,
			disco__Form_Contact__c = c.Id,
			disco__Mobile_ID__c = '1231'
		)
		};
		insert discoForms;

		List<disco__Question__c> discoQuestions = new List<disco__Question__c>{
		new disco__Question__c(
			disco__Form_Template__c = discoFormTemplate.Id,
			disco__Label__c = 'test',
			disco__Type__c = 'Picklist',
			Selected_Question_Order__c = 1,
			disco__Order__c = 1,
			Alternate_Question_Order__c = 1
		)
		};
		insert discoQuestions;

		List<disco__Answer__c> discoAnswers = new List<disco__Answer__c>{
		new disco__Answer__c(
			disco__Answer__c = 'test',
			disco__Form__c = discoForms[1].Id,
			disco__Question__c = discoQuestions[0].Id
		),
		new disco__Answer__c(
			disco__Answer__c = 'test',
			disco__Form__c = discoForms[0].Id,
			disco__Question__c = discoQuestions[0].Id
		),
		new disco__Answer__c(
			disco__Form__c = discoForms[0].Id,
			disco__Question__c = discoQuestions[0].Id
		),
		new disco__Answer__c(
			disco__Answer__c = 'test12',
			disco__Form__c = discoForms[0].Id,
			disco__Question__c = discoQuestions[0].Id
		),
		new disco__Answer__c(
			disco__Form__c = discoForms[0].Id,
			disco__Question__c = discoQuestions[0].Id
		)
		};
		insert discoAnswers;

        Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        
		Program__c p = new Program__c(Name='VHPe',Short_Name__c='VHPe',Product_Code__c='VHP-e');
        insert p;
        Admitted_Program__c ap = new Admitted_Program__c(Program__c=p.Id ,start_date__c=system.today() );
        insert ap;

        Nursing_Shift__c shift = new Nursing_Shift__c(
            Shift_Number__c='1st',
            Date__c =Date.today().addDays(1),
            Status__c='New',
            Type_of_Day__c='Weekday'
        );
        insert shift;

        // Admission__c am = new Admission__c(id=patient.current_admission__c, current_admitted_program__c=ap.id);
        // update am;

		update new Admission__c(
			Id=admission.Id, Stage__c='Admitted', 
			Psychotherapist__c = userinfo.getuserid(),
			Current_Admitted_Program__c = ap.Id
		);
	}

    public static testmethod void test(){
        Test.startTest();
		DailyNursingShiftBatch batch = new DailyNursingShiftBatch() ;
        Id batchProcessId = Database.executeBatch(batch, 10);
        Test.stopTest();
    }

	public static testmethod void testLeftOverShifts(){
        disco__Form_Template__c discoFormTemplateVerifyAsses = (disco__Form_Template__c) TestFactory_Patient.createSObject(
		new disco__Form_Template__c(
			Name = 'Patient_Safety_Assessment_Tool',
			disco__Status__c = 'In Use',
            DocType_Name__c = 'Patient_Safety_Assessment_Tool'
		),
		true
		);
        
        disco__Form_Template__c discoFormTemplateMedication = (disco__Form_Template__c) TestFactory_Patient.createSObject(
		new disco__Form_Template__c(
			Name = 'Medication_Package_Contents',
			disco__Status__c = 'In Use',
            DocType_Name__c = 'Medication_Package_Contents'
		),
		true
		);
        
        disco__Form_Template__c discoFormTemplatePatient = (disco__Form_Template__c) TestFactory_Patient.createSObject(
		new disco__Form_Template__c(
			Name = 'Patient_Certification_of_Dispensed',
			disco__Status__c = 'In Use',
            DocType_Name__c = 'Patient_Certification_of_Dispensed'
		),
		true
		);
        
        Admitted_Program_Status__c admittedProgramStatus = new Admitted_Program_Status__c(
            End_Date_Time__c = system.today().addDays(4),
            Status__c = 'Program Assessment Status (PAS)',
            Start_Date_Time__c = system.today(),
            Admitted_Program__c = [SELECT Id FROM Admitted_Program__c LIMIT 1].Id
        );
        insert admittedProgramStatus;
        Test.startTest();
		DailyNursingShiftBatch batch = new DailyNursingShiftBatch() ;
        Id batchProcessId = Database.executeBatch(batch, 10);
		Test.stopTest();

		List<Nursing_Shift_Item__c> nsi = [SELECT Nursing_Shift__c FROM Nursing_Shift_Item__c];
        List<disco__Form__c> forms = [SELECT Id FROM disco__Form__c];

		System.assert(nsi.size() > 0);
        System.assert(!forms.isEmpty());
    }

    @isTest
    private static void IRPProgramTestingCase() {
        List<Program__c> program = [SELECT Id, Product_Code__c FROM Program__c];
        program[0].Product_Code__c = 'IRP-G';
        update program;
        
        Test.startTest();
		DailyNursingShiftBatch batch = new DailyNursingShiftBatch() ;
        Id batchProcessId = Database.executeBatch(batch, 10);
		Test.stopTest();

		List<Nursing_Shift_Item__c> nsi = [SELECT Nursing_Shift__c FROM Nursing_Shift_Item__c];
        List<disco__Form__c> forms = [SELECT Id FROM disco__Form__c];

		System.assert(nsi.size() > 0);
        System.assert(!forms.isEmpty());
    }

	public static testmethod void testProcessLeftOverShiftItemsFromTrigger(){
		DailyNursingShiftBatch batch = new DailyNursingShiftBatch() ;
        Id batchProcessId = Database.executeBatch(batch, 10);
		
		Test.startTest();
		TriggerFactory.Recursions.clear();
		Nursing_Shift_Item__c nsi = new Nursing_Shift_Item__c(Shift_Date__c=System.today().addDays(1),Shift_Number__c='1st');
		insert nsi;
		Test.stopTest();

		nsi = [SELECT Nursing_Shift__c FROM Nursing_Shift_Item__c WHERE Id=:nsi.Id];

		System.assertNotEquals(null, nsi.Nursing_Shift__c, 'Left over NSI should have been assigned a Nursing Shift on trigger');
    }
    
    @isTest
    private static void getNursingShiftTest() {
        Test.startTest();
		DailyNursingShiftBatch batch = new DailyNursingShiftBatch() ;
        Id batchProcessId = Database.executeBatch(batch, 10);
		Test.stopTest();
        
        List<Nursing_Shift__c> shift = [SELECT Id, Shift_Number__c, Date__c FROM Nursing_Shift__c];
        Nursing_Shift__c nurShift = DailyNursingShiftBatch.getNursingShiftFromList(shift, Date.today(), '1st');
        
        System.assert(nurShift != null);
    }

    @isTest
    private static void schedulerTest() {
        SchedulableContext sc = null;
        DailyNursingShiftScheduleV2 dnssv2 = new DailyNursingShiftScheduleV2();
        dnssv2.execute(sc);
    }
}
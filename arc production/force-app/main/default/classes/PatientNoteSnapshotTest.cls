@IsTest
public class PatientNoteSnapshotTest {
	@testSetup
	private static void testSetup() {
		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		disco__Form_Template__c[] formTemplates = new List<disco__Form_Template__c>{ new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use') };
		insert formTemplates;

		ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();
		AdmissionScreeningControllerTest.setup();
		Account patient = [SELECT Id, Current_Case__c, External_Patient_Id__c FROM Account LIMIT 1];
		Admission__c admission = [SELECT Id, Team__c FROM Admission__c WHERE Patient_Account__c = :patient.Id LIMIT 1];
		admission.Admit_Date__c = Date.Today().addDays(-7);
		Case currentCase = new Case(AccountId = patient.Id, Admission__c = admission.Id);
		insert currentCase;
		patient.Current_Case__c = currentCase.Id;
		update patient;
		admission.Team__c = 'A';
		update admission;

		test.startTest();

		Clinical_Code__c clinicalcode = new Clinical_Code__c(Name = '001', Description__C = 'test code');
		insert clinicalcode;

		Note_Definition__mdt nd = [SELECT Id, Med_Records_Document_Type__r.MasterLabel, Note_Label__c FROM Note_Definition__mdt WHERE Med_Records_Document_Type__r.MasterLabel = 'Psychopharmacology Monthly Note'];

		Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
		Patient_Note__c consultantNote = new Patient_Note__c(
			Account__c = patient.Id,
			Admission__c = admission.Id, //patient.Current_Admission__c,
			Consultation_Assigned_Date__c = System.today(),
			Consultation_Requested_By__c = 'Patient',
			// Type__c = 'SnapshotTests',
			//Status__c = 'Finalized',
			RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId(),
			Type__c = nd.Note_Label__c,
			Contact_Date__c = Date.Today().addDays(-5)
		);

		insert consultantNote;

		Prescription__c prep = new Prescription__c(Medication_Filled_with__c='test', IRIS_Fill_Datetime__c = Datetime.now(), Account__c = patient.Id, Drug_Name__c = 'test', Drug_Format__c = 'test', Written_Date__c = consultantNote.Admission__r.Admit_Date__c, Presciber__c = userinfo.getuserid(), Indication_Text__c = 'test', Status__c = 'Active', Inactive_Datetime__c = system.today(), External_Prescription_Id__c = 123456);
		insert prep;

		Prescription__c prep2 = new Prescription__c(Medication_Filled_with__c='test', IRIS_Fill_Datetime__c = Datetime.now(), Account__c = patient.Id, Drug_Name__c = 'test', Drug_Format__c = 'test', Written_Date__c = consultantNote.Admission__r.Admit_Date__c, Presciber__c = userinfo.getuserid(), Indication_Text__c = 'test', Status__c = 'Active', External_Prescription_Id__c = 123457);
		insert prep2;

		insert new List<Diagnosis__c>{
			new Diagnosis__c(
				Admission__c = admission.Id, //patient.Current_Admission__c,
				Patient_Note__c = consultantNote.Id,
				Source__c = 'Admissions',
				Clinical_Code__c = clinicalcode.Id,
				Type__c = 'Principal'
			),
			new Diagnosis__c(
				Admission__c = admission.Id, //patient.Current_Admission__c,
				Patient_Note__c = consultantNote.Id,
				Source__c = 'Admissions',
				Clinical_Code__c = clinicalcode.Id,
				Type__c = 'Comorbid'
			)
		};

		insert new Intervention__c(Case__c = patient.Current_Case__c, Description__c = 'Test Psychopharm', Discipline__c = 'Psychotherapy', Start_Date__c = System.today().addDays(-10), Patient_specific_Details__c = 'Test', Status__c = 'Current');
		
		Allergy__c allergy = new Allergy__c();
        allergy.Name__c = 'Accu-Chek Comfort Curve Test';
        allergy.Account__c = patient.Id;
        allergy.Allergy_Type__c = '13148';
        allergy.Adverse_Event_Code__c = '414285001';
        allergy.Reaction__c = '1';
        allergy.Comment__c = 'Test';
        allergy.Archive__c = '0';
        allergy.Onset_Date__c = Date.today();

        allergy.Severity_Code__c = '2';
        allergy.IRIS_Only__c = false;

        insert allergy;
		test.stoptest();
	}

	public static testMethod void testSnapshot() {
		Group__c[] groups = new List<Group__c>{};
		string[] admissionTeams = 'a,b,c,d'.split(',');
		for (Schema.PicklistEntry pe : Schema.SObjectType.Admission__c.fields.Team__c.getPicklistValues()) {
			admissionTeams.add(pe.getValue());
		}
		for (string a : admissionTeams) {
			groups.add(new Group__c(Name = 'Team ' + a, Active__c = true));
		}
		insert groups;
		Staff_Group_Member__c[] groupMembers = new List<Staff_Group_Member__c>{};
		for (Group__c g : groups) {
			groupMembers.add(new Staff_Group_Member__c(Group_Name__c = g.Id, Start_Date__c = system.today(), Role__c = 'Team Leader', Planned_End_Date__c = system.today().addDays(1), Staff_Member__c = userinfo.getuserid()));
		}
		insert groupMembers;

		Patient_Note__c consultantNote = [SELECT Id FROM Patient_Note__c LIMIT 1];

		test.startTest();
		update new Patient_Note__c(Id = consultantNote.Id, Status__c = 'Finalized');
		test.stopTest();

		system.assertNotEquals(0, [SELECT COUNT() FROM Snapshot__c]);

		Patient_Note__c note = [SELECT Snapshot__c FROM Patient_Note__c];

		system.assertNotEquals(null, note.Snapshot__c);
	}
	@isTest
	private static void testGetMatchedMonthlyPrescriptions() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsyPhMonthly_Current_Meds'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		List<Prescription__c> ps = pNote.getMatchedPrescriptions(noteItem, consultantNote);
		System.assert(ps != null, 'Prescription list should not be null');
		test.stopTest();
	}

	@isTest
	private static void testGetMatchedThisMonthPrescriptions() {
		//PsyPhMonthly_Medications
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsyPhMonthly_Medications_Beginning'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		List<Prescription__c> ps = pNote.getMatchedPrescriptions(noteItem, consultantNote);
		System.assert(ps != null, 'Prescription list should not be null');
		test.stopTest();
	}

	@isTest
	private static void testGetMatchedNoteDatePrescriptions() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsyPhEval_Prescriptions_Note_Date'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		List<Prescription__c> ps = pNote.getMatchedPrescriptions(noteItem, consultantNote);
		System.assert(ps != null, 'Prescription list should not be null');
		test.stopTest();
	}

	@isTest
	private static void testGetMatchedAdmitDatePrescriptions() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Admission__c, Admission__r.Admit_Date__c, Contact_Date__c, Away_First_Date__c, Away_Last_Date__c, Away_Number_of_Days__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Admission__c admission = new Admission__c(Id = consultantNote.Admission__c, Admit_Date__c = Date.today());
		update admission;
		consultantNote = [SELECT Id, Account__c, Admission__c, Admission__r.Admit_Date__c, Contact_Date__c, Away_First_Date__c, Away_Last_Date__c, Away_Number_of_Days__c FROM Patient_Note__c LIMIT 1];
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsyPhEval_Prescriptions_Admit_Date'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		List<Prescription__c> ps = pNote.getMatchedPrescriptions(noteItem, consultantNote);
		System.assert(ps != null, 'Prescription list should not be null');
		String html = pNote.getHtmlNoteItemPrescriptions(noteItem, consultantNote);
		test.stopTest();
	}

	@isTest
	private static void testGetMatchedMonthlyMedicationsBeginning() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Admission__c, Admission__r.Admit_Date__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Admission__c admission = new Admission__c(Id = consultantNote.Admission__c, Admit_Date__c = Date.today());
		update admission;
        consultantNote = [SELECT Id, Account__c, Admission__c, Admission__r.Admit_Date__c, Contact_Date__c, Away_First_Date__c, Away_Last_Date__c, Away_Number_of_Days__c FROM Patient_Note__c LIMIT 1];
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		Date firstDayOfMonth = consultantNote.Contact_Date__c.toStartOfMonth();
		prep.Written_Date__c = firstDayOfMonth.addDays(-2);
		prep.Start_Date__c = prep.Written_Date__c.date();
		prep.Inactive_Datetime__c = null;
		prep.Daily_Dosage_Quantity__c = 1;
		prep.As_Needed__c = false;
		update prep;
		DispensingService.dispensePrescriptions(new List<Id>{ prep.Id }, consultantNote.Account__c);
		DispensingService.finalizePrescriptions(new List<Id>{ prep.Id }, consultantNote.Account__c);
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsyPhMonthly_Medications_Beginning'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String html = pNote.getHtmlNoteItemPrescriptions(noteItem, consultantNote);
		test.stopTest();
	}

	@isTest
	private static void testforMSA() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Admission__c, Admission__r.Admit_Date__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Admission__c admission = new Admission__c(Id = consultantNote.Admission__c, Admit_Date__c = Date.today());
		update admission;
        consultantNote = [SELECT Id, Account__c, Admission__c, Admission__r.Admit_Date__c, Contact_Date__c, Away_First_Date__c, Away_Last_Date__c, Away_Number_of_Days__c FROM Patient_Note__c LIMIT 1];
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now().addDays(-2);
		prep.Start_Date__c = prep.Written_Date__c.date();
		prep.Inactive_Datetime__c = null;
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'MSA_Current_Orders'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String html = pNote.getHtmlNoteItemPrescriptions(noteItem, consultantNote);
		test.stopTest();
	}

	@isTest
	private static void testForAway() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c, Away_First_Date__c, Away_Last_Date__c, Away_Number_of_Days__c,Final_Discharge_Med_Order__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		consultantNote.Type__c = 'Away Medication Order';
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now().addDays(-2);
		prep.Start_Date__c = prep.Written_Date__c.date();
		prep.Inactive_Datetime__c = null;
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'AwayDisOrder_Current_Orders'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String html = pNote.getHtmlNoteItemPrescriptions(noteItem, consultantNote);
		test.stopTest();
	}

	@isTest
	private static void testGetMatchedFirstOfMonthPrescriptions() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c, Away_First_Date__c, Away_Last_Date__c, Away_Number_of_Days__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsyPhMonthly_Medications_Beginning'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		List<Prescription__c> ps = pNote.getMatchedPrescriptions(noteItem, consultantNote);
		System.assert(ps != null, 'Prescription list should not be null');
		ps = pNote.getMatchedMonthlyPrescriptions(consultantNote);
		test.stopTest();
	}

	@isTest
	private static void testGetHtmlPhysicalMonitors() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = Date.Today();
		prep.End_Date__c = prep.Start_Date__c.addDays(3);
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsyPhMonthly_Medications_Beginning'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String htmlTxt = pNote.getHtmlPhysicalMonitors(noteItem, consultantNote);
		System.assert(htmlTxt != null, 'Html should not be null');
		test.stopTest();
	}

	@isTest
	private static void testGetHtmlNoteInitialConsultationRecommendations() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsychIni_Recommendations'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteInitialConsultationRecommendations(noteItem, consultantNote);

		test.stopTest();
	}

	@isTest
	private static void testGetHtmlNoteAdmittedPrograms() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		consultantNote.SOH_History_Program__c = 'test';
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'SOH_Programs'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteAdmittedPrograms(noteItem, consultantNote);

		test.stopTest();
	}

	@isTest
	private static void testGetHtmlNoteSOHMedicalRecord() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		consultantNote.SOH_Med_Office_Discharge__c = 'test';
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'SOH_Summary_of_Medical_Care'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteSOH(noteItem, consultantNote);

		test.stopTest();
	}
	@isTest
	private static void testGetHtmlNoteSOHPsychopharmacological() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		consultantNote.SOH_Psychophram_Monthly_Note__c = 'test';
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'SOH_Summary_of_psychopharmacological'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteSOH(noteItem, consultantNote);

		test.stopTest();
	}

	@isTest
	private static void testGetHtmlNoteUserLookup() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Field_Name__c, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE DeveloperName = 'PsychTran_New_Therapist'];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteUserLookup(noteItem, consultantNote);

		test.stopTest();
	}

	@isTest
	private static void testGetHtmlNoteItemSectionHeader1() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE Type__c = 'Section Header 1' LIMIT 1];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteItemSectionHeader1(noteItem);

		test.stopTest();
	}

	@isTest
	private static void testGetHtmlNoteItemSectionHeader2() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE Type__c = 'Section Header 2' LIMIT 1];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteItemSectionHeader2(noteItem);

		test.stopTest();
	}
	@isTest
	private static void testGetHtmlNoteItemSectionHeader3() {
		Patient_Note__c consultantNote = [SELECT Id, Account__c, Contact_Date__c FROM Patient_Note__c LIMIT 1];
		consultantNote.Contact_Date__c = Date.today();
		update consultantNote;
		Prescription__c prep = [SELECT Id FROM Prescription__c LIMIT 1];
		prep.Written_Date__c = Datetime.now();
		prep.Start_Date__c = prep.Written_Date__c.date();
		update prep;
		Note_Item__mdt noteItem = [SELECT Id, Embedded_Component_Parameters__c FROM Note_Item__mdt WHERE Type__c = 'Section Header 3' LIMIT 1];
		test.startTest();
		PatientNoteSnapshot pNote = new PatientNoteSnapshot(new Set<Id>{ consultantNote.Id });
		String ps = pNote.getHtmlNoteItemSectionHeader3(noteItem);

		test.stopTest();
	}

}
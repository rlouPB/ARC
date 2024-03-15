@isTest
with sharing class PrintedMedicalRecordControllerTest {
	@TestSetup
	static void makeData() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		List<Contact> patientContactList = new List<Contact>{ new Contact(LastName = 'TestPatient_0', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')) };
		insert patientContactList;

		List<Contact> accWithContacts = [SELECT Id, LastName, AccountId FROM Contact WHERE Id IN :patientContactList ORDER BY LastName];

		List<Admission__c> admissionList = new List<Admission__c>{
			new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id, Stage__c = 'Discharged', Service_Type__c = 'Residential', Discharge_Date__c = Date.Today().addMonths(-12), Admit_Date__c = Date.Today().addMonths(-15), Psychotherapist__c = Userinfo.getUserId()), //good
			new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id, Stage__c = 'Discharged', Service_Type__c = 'Residential', Discharge_Date__c = Date.Today().addDays(-12), Admit_Date__c = Date.Today().addMonths(-1), Psychotherapist__c = Userinfo.getUserId())

			//,new Admission__c(Patient_Account__c = accWithContacts[3].AccountId, Patient_Contact__c = accWithContacts[3].Id, Stage__c='Waitlist') //not a Patient
		};
		insert admissionList;

		//create Users
		Profile riggsClinicalProfile = [SELECT Id FROM Profile WHERE Name = 'RiggsClinical' LIMIT 1];
		Profile riggsStaffProfile = [SELECT Id FROM Profile WHERE Name = 'RiggsStaff' LIMIT 1];
		Id staffRtId = recordTypeMap.get('ARC_Staff' + '-' + 'Contact');
		Map<String, User> staffUserNameMap;
		User adminNotMe = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE AND Id != :Userinfo.getUserId() LIMIT 1];
		System.runAs(adminNotMe) {
			List<User> usersToCreate = new List<User>();

			//good: all staff
			usersToCreate.add(new User(FirstName = 'AGMTestnonclinicalAllstaff', LastName = 'Test', ProfileId = riggsStaffProfile.Id, Username = 'nonclinicalAllstaff@austenriggs.net.Phase2Dev', Email = 'nonclinicalAllstaff@example.com', Alias = 'noncl', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York', IsActive = true));
			insert usersToCreate;
		}

		Account patient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];
		patient.Current_Admission__c = admissionList[1].Id;
		update patient;
		patient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];

		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		disco__Form_Template__c discoFormTemplateMedication = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Medication_Package_Contents');
		insert discoFormTemplateMedication;

		disco__Form_Template__c discoFormTemplateDispensed = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Patient_Certification_of_Dispensed');
		insert discoFormTemplateDispensed;

		disco__Form_Template__c discoFormTemplateTool = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Patient_Safety_Assessment_Tool');
		insert discoFormTemplateTool;

		Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
		List<Patient_Note__c> notes = new List<Patient_Note__c>{
			new Patient_Note__c(Account__c = patient.Id, Admission__c = patient.Current_Admission__c, Type__c = 'Psychotherapy Consultation Note', Contact_Date__c = Date.Today().addDays(-5), Finalized_Date_Time__c = Datetime.now().addDays(-2), RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId(), Status__c = 'Finalized'),
			new Patient_Note__c(Account__c = patient.Id, Admission__c = patient.Current_Admission__c, Type__c = 'Admissions Consultation Note', Contact_Date__c = Date.Today().addDays(-5), Finalized_Date_Time__c = Datetime.now().addDays(-2), RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId(), Status__c = 'Finalized'),
			new Patient_Note__c(Account__c = patient.Id, Admission__c = patient.Current_Admission__c, Type__c = 'Psychopharmacology Monthly Note', Contact_Date__c = Date.Today().addDays(-5), Finalized_Date_Time__c = Datetime.now().addDays(-2), RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId(), Status__c = 'Finalized'),
			new Patient_Note__c(Account__c = patient.Id, Admission__c = patient.Current_Admission__c, Type__c = 'Psychopharmacology Diagnosis', Contact_Date__c = Date.Today().addDays(-5), Finalized_Date_Time__c = Datetime.now().addDays(-2), RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId(), Status__c = 'Finalized')
		};

		insert notes;

		disco__Form_Template__c discoFormTemplate2 = new disco__Form_Template__c(Name = 'LOCUS', DocType_Name__c = 'LOCUS', disco__Status__c = 'In Use');
		insert discoFormTemplate2;

		List<disco__Form__c> discoForms = new List<disco__Form__c>{
			new disco__Form__c(
				disco__Form_Account__c = patient.Id,
				//Related_Contact__c = relatedContacts[0].Id,
				disco__Form_Template__c = discoFormTemplate.Id,
				disco__Archived__c = true,
				Admission__c = patient.Current_Admission__c,
				disco__Form_Contact__c = patientContactList[0].Id,
				Master_Date__c = Date.Today().addDays(-5),
				disco__Mobile_ID__c = '123'
			),
			new disco__Form__c(
				disco__Form_Account__c = patient.Id,
				//Related_Contact__c = relatedContacts[1].Id,
				disco__Form_Template__c = discoFormTemplate.Id,
				disco__Archived__c = true,
				Admission__c = patient.Current_Admission__c,
				Master_Date__c = Date.Today().addDays(-5),
				disco__Form_Contact__c = patientContactList[0].Id,
				disco__Mobile_ID__c = '1231'
			)
		};
		insert discoForms;
		List<disco__Section__c> discoSections = new List<disco__Section__c>{ new disco__Section__c(Name = 'Return', disco__Form_Template__c = discoFormTemplate.Id) };
		insert discoSections;

		List<disco__Question__c> discoQuestions = new List<disco__Question__c>{ new disco__Question__c(disco__Label__c = 'Medication & Format'), new disco__Question__c(disco__Label__c = 'Quantity Dispensed'), new disco__Question__c(disco__Type__c = 'Field Link', disco__Section__c = discoSections[0].Id) };
		insert discoQuestions;

		List<disco__Answer__c> discoAnswers = new List<disco__Answer__c>{ new disco__Answer__c(disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id), new disco__Answer__c(disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[1].Id), new disco__Answer__c(disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[2].Id) };
		insert discoAnswers;
	}
	@isTest
	private static void unitTest1() {
		List<Patient_Note__c> noteList = [SELECT Id, Type__c FROM Patient_Note__c WHERE Status__c = 'Finalized'];
		System.assertEquals(4, noteList.size(), 'The Patient_Note__c count should be 4.');
		List<disco__Form__c> formList = [SELECT Id, disco__Form_Template__r.DocType_Name__c FROM disco__Form__c WHERE Master_Date__c != NULL];
		System.assertEquals(2, formList.size(), 'The disco__Form__c count should be 2.');
		Account patient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];
		Printed_Medical_Record_Request__c request = new Printed_Medical_Record_Request__c(Patient_Account__c = patient.Id);
		insert request;
		List<SDoc_Junction__c> sDocJunctions = new List<SDoc_Junction__c>();
		List<Printed_Medical_Included_Record__c> includedObjs = new List<Printed_Medical_Included_Record__c>();

		for (Patient_Note__c note : noteList) {
			sDocJunctions.add(new SDoc_Junction__c(Object_SF_Id__c = '' + request.Id + note.Id, Patient_Note__c = note.Id));
			includedObjs.add(new Printed_Medical_Included_Record__c(Printed_Medical_Record_Request__c = request.Id, Document_Type__c = note.Type__c, External_Id__c = '' + request.Id + note.Id, SDoc_Junction__r = new SDoc_Junction__c(Object_SF_Id__c = '' + request.Id + note.Id)));
		}
		for (disco__Form__c form : formList) {
			sDocJunctions.add(new SDoc_Junction__c(Object_SF_Id__c = '' + request.Id + form.Id, Youreka_Form__c = form.Id));
			includedObjs.add(new Printed_Medical_Included_Record__c(Printed_Medical_Record_Request__c = request.Id, Document_Type__c = form.disco__Form_Template__r.DocType_Name__c, External_Id__c = '' + request.Id + form.Id, SDoc_Junction__r = new SDoc_Junction__c(Object_SF_Id__c = '' + request.Id + form.Id)));
		}
		upsert sDocJunctions Object_SF_Id__c;
		upsert includedObjs External_Id__c;

		PageReference pageRef = Page.PrintedPatientRecordPDF;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id', request.Id);
		PrintedMedicalRecordController controller = new PrintedMedicalRecordController();
		controller.init();
	}
}
@isTest
public class MedRecordHierarchy_Test {
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

		disco__Form_Template__c[] formTemplates = new List<disco__Form_Template__c>{ new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer', disco__Status__c = 'In Use', Name = 'Psychiatrist Transfer from Test') };
		insert formTemplates;

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

		disco__Form_Template__c discoFormTemplate = [SELECT Id FROM disco__Form_Template__c WHERE DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer' LIMIT 1];
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
	public static void getAllCategoriesTestMethod() {
		test.startTest();
		String allCategories = MedRecordHierarchy.getAllCategories();
		test.stopTest();

		system.assertNotEquals(null, allCategories);
	}
	@isTest
	private static void unitTest3() {
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
		String admissionIds = JSON.serialize(new List<String>{ patient.current_admission__c });
		TreeGridNode.TreeNodeResult result = MedRecordHierarchy.getAllTreeWithLeafNodes(patient.Id, request.Id, admissionIds);
		MedRecordHierarchy.retrieveRecordsInDateRange(patient.Id, Datetime.now().addDays(-7).format('yyyy-MM-dd'), Datetime.now().format('yyyy-MM-dd'), false, admissionIds);
		MedRecordHierarchy.retrieveRecordsToPrint('LOCUS', 'disco__Form__c', patient.Id, admissionIds);
		MedRecordHierarchy.retrieveRecordsToPrint('Admissions Consultation Note', 'Patient_Note__c', patient.Id, admissionIds);

		List<String> insertNotes = new List<String>{};
		MedRecordHierarchy.savePrintedMedicalRecord(patient.Id, JSON.serialize(insertNotes), request.Id, admissionIds);

		MedRecordHierarchy.savePrintedMedicalRecord(patient.Id, result.selectedRows, request.Id, admissionIds);
		System.assert(MedRecordHierarchy.getAdmissions(patient.Id) != null, 'The result of getAdmissions() should not be empty');
		List<Printed_Medical_Included_Record__c> toBeDeletedIncludedObjs = [SELECT Id FROM Printed_Medical_Included_Record__c];
		delete toBeDeletedIncludedObjs;
		System.assert([SELECT Id FROM Printed_Medical_Included_Record__c].size() == 0);
		//System.assert([SELECT Id FROM  SDoc_Junction__c].size() == 0);
		PrintedMedicalIncludedTriggerHandler ith = new PrintedMedicalIncludedTriggerHandler();
		ith.beforeInsert(null);
		ith.beforeUpdate(null, null);
		ith.beforeDelete(null);
		ith.afterInsert(null);
		ith.afterUpdate(null, null);
		ith.afterDelete(null);
		ith.andFinally();
	}

	@isTest
	private static void unitTest4() {
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
		String admissionIds = JSON.serialize(new List<String>{ patient.current_admission__c });

		Integer sortSequence = SDocsYourekaUtils.calculateSortingSequence(noteList[0].Type__c);
		sortSequence = SDocsYourekaUtils.calculateSortingSequenceWithDevName(noteList[0].Type__c);
		List<SDocsYourekaUtils.PrintedIncludedObject> pios = SDocsYourekaUtils.generateYourekaHTMLs(request.Id);
		pios.sort();
	}
}
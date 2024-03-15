@IsTest
public class SDocsYourekaUtilsTest {
	@TestSetup
	static void setup() {
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

	@IsTest
	static void testCalculateSortingSequenceWithDevName() {
		List<Patient_Note__c> noteList = [SELECT Id, Type__c FROM Patient_Note__c WHERE Status__c = 'Finalized'];
		Test.startTest();
		SDocsYourekaUtils.calculateSortingSequenceWithDevName(noteList[0].Type__c);
		Test.stopTest();
	}

	@IsTest
	static void testCalculateSortingSequence() {
		List<Patient_Note__c> noteList = [SELECT Id, Type__c FROM Patient_Note__c WHERE Status__c = 'Finalized'];
		Test.startTest();
		SDocsYourekaUtils.calculateSortingSequence(noteList[0].Type__c);
		Test.stopTest();
	}

	@IsTest
	static void testGenerateYourekaHTMLs() {
		Account patient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];
		Printed_Medical_Record_Request__c request = new Printed_Medical_Record_Request__c(Patient_Account__c = patient.Id);
		insert request;

		List<Patient_Note__c> noteList = [SELECT Id, Type__c FROM Patient_Note__c WHERE Status__c = 'Finalized'];
		Test.startTest();
		SDocsYourekaUtils.generateYourekaHTMLs(request.Id);
		Test.stopTest();
	}

	/*@IsTest static void testGenerateYourekaHTML(){
        List<disco__Answer__c> discoAnswers = [Select id, disco__Question__r.disco__Label__c, disco__Question__r.disco__Answer__c,disco__Question__r.disco__Type__c from disco__Answer__c order by createddate desc limit 3];
        Test.startTest();
        SDocsYourekaUtils.generateYourekaHTML(discoAnswers);
        Test.stopTest();
    }*/
}
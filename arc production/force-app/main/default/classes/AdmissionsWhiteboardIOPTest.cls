@isTest
private class AdmissionsWhiteboardIOPTest {
	@isTest
	private static void testPatientInWaitlist() {
		String[] requirements = new List<String>{ 'Clinical', 'Medications', 'Medical', 'Motivation', 'Abstinence', 'Finances', 'Legal' };

		createPatient(requirements, 'Waitlist', false, 'IOP');

		Test.startTest();

		AdmissionsWhiteboardIOPController.Whiteboard whb = AdmissionsWhiteboardIOPController.getWhiteboard(requirements);

		Test.stopTest();

		// System.assertEquals(true, !whb.WaitlistAccounts.isEmpty());
	}

	@isTest
	private static void testPatientInConsultationPending() {
		String[] requirements = new List<String>{ 'Clinical', 'Medications', 'Medical', 'Motivation', 'Abstinence', 'Finances', 'Legal' };

		createPatient(requirements, 'Consultation Pending', false, 'IOP');

		Test.startTest();

		AdmissionsWhiteboardIOPController.Whiteboard whb = AdmissionsWhiteboardIOPController.getWhiteboard(requirements);

		Test.stopTest();

		// System.assertEquals(true, !whb.WaitlistAccounts.isEmpty());
	}

	@isTest
	private static void testPatientIncompleteRequirements() {
		String[] requirements = new List<String>{ 'Clinical', 'Medications', 'Medical', 'Motivation', 'Abstinence', 'Finances', 'Legal' };

		createPatient(requirements, 'Active Inquiry', false, 'IOP');

		Test.startTest();

		AdmissionsWhiteboardIOPController.Whiteboard whb = AdmissionsWhiteboardIOPController.getWhiteboard(requirements);

		Test.stopTest();

		// System.assertEquals(true, !whb.AccountRequirementRows.isEmpty());
	}

	@isTest
	private static void testPatientCompletedRequirements() {
		String[] requirements = new List<String>{ 'Clinical', 'Medications', 'Medical', 'Motivation', 'Abstinence', 'Finances', 'Legal' };

		createPatient(requirements, 'Active Inquiry', true, 'IOP');

		Test.startTest();

		AdmissionsWhiteboardIOPController.Whiteboard whb = AdmissionsWhiteboardIOPController.getWhiteboard(requirements);

		Test.stopTest();

		// System.assertEquals(true, !whb.ActiveDoneAccounts.isEmpty());
	}

	private static void createPatient(List<String> requirements, String admissionStage, Boolean isComplete, String serviceType) {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		List<Account> patientAccountList = new List<Account>{ new Account(Name = 'patient1', RecordtypeId = recordTypeMap.get('Patient-Account')) };
		insert patientAccountList;

		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient-Contact'), AccountId = patientAccountList[0].Id) };
		insert contactList;

		Contact patientAccountContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = patientAccountContact.AccountId, Patient_Contact__c = patientAccountContact.Id, Stage__c = admissionStage, Service_Type__c = serviceType) };
		insert admissionList;

		List<Account> accountsWithAdmission = [SELECT Id, Name, Current_Admission__c FROM Account WHERE Id = :patientAccountContact.AccountId];
		accountsWithAdmission[0].Current_Admission__c = admissionList[0].Id;
		upsert accountsWithAdmission;

		List<Admissions_Requirement__c> admissionReqList = new List<Admissions_Requirement__c>();
		Integer size = isComplete ? requirements.size() : requirements.size() - 1;

		for (Integer i = 0; i < size; i++) {
			Admissions_Requirement__c admissionsRequirement = new Admissions_Requirement__c(Completed__c = true, Name = requirements[i], Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = accountsWithAdmission[0].Current_Admission__c, Order__c = i + 1);
			admissionReqList.add(admissionsRequirement);
		}
		insert admissionReqList;

		List<Admissions_Requirement__c> queriedAdmissionsRequirementList = [SELECT Id, Name, Admission__c, Completed__c FROM Admissions_Requirement__c WHERE Admission__c = :accountsWithAdmission[0].Current_Admission__c AND Name IN :requirements AND Completed__c = FALSE];

		if (!queriedAdmissionsRequirementList.isEmpty()) {
			for (Integer i = 0; i < size; i++) {
				queriedAdmissionsRequirementList[i].Completed__c = true;
			}
			update queriedAdmissionsRequirementList;
		}
	}
}
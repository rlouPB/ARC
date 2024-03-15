/**
 * This class will also teste DischargeSectionCtl
 */
@isTest(SeeAllData=false)
private class DischargeDispositionCtlTest {
	@TestSetup
	private static void testSetup() {
		// Setup Patient
		AdmissionScreeningControllerTest.setup();
		Account patient = [SELECT Id, Name, Current_Case__c FROM Account LIMIT 1];
		Case currentCase = new Case(AccountId = patient.Id);
		insert currentCase;
		patient.Current_Case__c = currentCase.Id;
		update patient;

		// Setup Case Team
		// User thisUser=[select id from user where id=:UserInfo.getUserId()];
		// CaseTeamRole socialWorkerRole;
		// try
		// {
		//     socialWorkerRole=[SELECT Id FROM CaseTeamRole WHERE Name='Clinical Social Worker'];
		// }
		// catch(QueryException qe)
		// {
		//     socialWorkerRole=new CaseTeamRole(AccessLevel='Edit',Name='Clinical Social Worker',PreferencesVisibleInCSP=false);
		//     insert socialWorkerRole;
		// }

		// CaseTeamMember socialWorker=new CaseTeamMember(,memberId=UserInfo.getUserId(),TeamRoleId=socialWorkerRole.Id);

		Assigned_Clinician__c socialWorker = new Assigned_Clinician__c(Treatment_Plan__c = currentCase.Id, User__c = UserInfo.getUserId(), Role__c = 'Clinical Social Worker');
		insert socialWorker;

		// Setup Referrals
		Schema.RecordTypeInfo institutionRecordTypeInfo = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Medical_Institution');
		Account institution = new Account(RecordTypeId = institutionRecordTypeInfo.getRecordTypeId(), Name = 'Test Medical Institution', Phone = '2134657980');
		insert institution;

		Schema.RecordTypeInfo individualRecordTypeInfo = Contact.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Professional');
		List<Contact> individualReferralList = new List<Contact>();
		Contact individualMobile = new Contact(RecordTypeId = individualRecordTypeInfo.getRecordTypeId(), FirstName = 'Test', LastName = 'Individual Referral', MobilePhone = '1234567890', npe01__PreferredPhone__c = 'Mobile');
		Contact individualHome = new Contact(RecordTypeId = individualRecordTypeInfo.getRecordTypeId(), FirstName = 'Test', LastName = 'Individual Referral', Phone = '1234567890', npe01__PreferredPhone__c = 'Home');
		Contact individualWork = new Contact(RecordTypeId = individualRecordTypeInfo.getRecordTypeId(), FirstName = 'Test', LastName = 'Individual Referral', npe01__WorkPhone__c = '1234567890', npe01__PreferredPhone__c = 'Work');
		individualReferralList.add(individualMobile);
		individualReferralList.add(individualHome);
		individualReferralList.add(individualWork);
		insert individualReferralList;
	}

	/**
	 * Also test getReferralPhone()
	 */
	@isTest
	private static void testCreateSaveCancelRoutine() {
		Account patient = [SELECT Id, Name, Current_Case__c FROM Account LIMIT 1];
		Account institutionReferral = [SELECT Id FROM Account WHERE Name LIKE '%Medical Institution%' LIMIT 1];
		List<Contact> individualReferralList = [SELECT Id FROM Contact WHERE FirstName = 'Test'];
		Test.startTest();
		DischargeDispositionCtl.getPatientById(patient.Id);
		DischargeDisposition testDischargeDisposition = DischargeDispositionCtl.createDischargeDisposition(patient.Id, false);
		DischargeDispositionCtl.getReferralPhone('institution', institutionReferral.Id);
		for (Contact individualReferral : individualReferralList) {
			DischargeDispositionCtl.getReferralPhone('individual', individualReferral.Id);
		}
		List<Discharge_Referral__c> referralList = new List<Discharge_Referral__c>();
		for (DischargeSection section : testDischargeDisposition.dischargeSectionList) {
			if (String.isNotBlank(section.dischargeSectionObj.Role__c) && section.dischargeSectionObj.Role__c.equalsIgnoreCase('social work')) {
				// Setup one referral for Social Worker
				Discharge_Referral__c individualReferralObj = new Discharge_Referral__c(Discharge_Disposition__c = testDischargeDisposition.dischargeDispositionObj.Id, Section__c = section.dischargeSectionObj.Id, Grouping__c = section.dischargeSectionObj.Role__c, Clinician__c = individualReferralList[0].Id, Referred_By__c = UserInfo.getUserId());
				Discharge_Referral__c institutionReferralObj = new Discharge_Referral__c(Discharge_Disposition__c = testDischargeDisposition.dischargeDispositionObj.Id, Section__c = section.dischargeSectionObj.Id, Grouping__c = section.dischargeSectionObj.Role__c, Institution__c = institutionReferral.Id, Referred_By__c = UserInfo.getUserId());
				referralList.add(individualReferralObj);
				referralList.add(institutionReferralObj);
			}
		}

		insert referralList;
		testDischargeDisposition = DischargeDispositionCtl.getDischargeDisposition(testDischargeDisposition.dischargeDispositionObj.Id);

		// Setting up Social Worker Section testing
		DischargeSection socialWorkerSection;
		for (DischargeSection section : testDischargeDisposition.dischargeSectionList) {
			if (String.isNotBlank(section.dischargeSectionObj.Role__c) && section.dischargeSectionObj.Role__c.equalsIgnoreCase('social work')) {
				// Assigned for testing DischargeSectionCtl
				socialWorkerSection = section;
			}
		}
		String socialWorkerSectionString = DischargeSectionCtl.saveDischargeSection(JSON.serialize(socialWorkerSection));
		socialWorkerSection = (DischargeSection) JSON.deserialize(socialWorkerSectionString, DischargeSection.class);
		if (socialWorkerSection.removeReferralList == null) {
			socialWorkerSection.removeReferralList = new List<DischargeReferral>();
		}

		// Adding the referral to the removal WITHOUT removing it from referral list will cover the Rollback exception lines
		socialWorkerSection.removeReferralList.add(socialWorkerSection.referralList[0]);
		socialWorkerSection.dischargeSectionObj.Status__c = 'Completed';
		DischargeSectionCtl.saveDischargeSection(JSON.serialize(socialWorkerSection));
		DischargeSectionCtl.reopenDischargeSection(JSON.serialize(socialWorkerSection));
		DischargeDispositionCtl.saveDischargeDisposition(testDischargeDisposition.dischargeDispositionObj);
		DischargeDispositionCtl.cancelDischargeDisposition(testDischargeDisposition.dischargeDispositionObj.Id);
		Test.stopTest();
	}

	@isTest
	private static void testFinalizeDischargeRoutine() {
		Account patient = [SELECT Id, Name, Current_Case__c FROM Account LIMIT 1];
		Account institutionReferral = [SELECT Id FROM Account WHERE Name LIKE 'Test%' LIMIT 1];
		List<Contact> individualReferralList = [SELECT Id FROM Contact WHERE FirstName = 'Test'];

		Test.startTest();
		DischargeDispositionCtl.getPatientById(patient.Id);
		DischargeDisposition testDischargeDisposition = DischargeDispositionCtl.createDischargeDisposition(patient.Id, false);
		testDischargeDisposition.dischargeDispositionObj.Anticipated_Discharge_Date__c = System.today().addDays(10);

		DischargeDispositionCtl.getReferralPhone('institution', institutionReferral.Id);
		for (Contact individualReferral : individualReferralList) {
			DischargeDispositionCtl.getReferralPhone('individual', individualReferral.Id);
		}
		update testDischargeDisposition.dischargeDispositionObj;

		testDischargeDisposition = DischargeDispositionCtl.getDischargeDisposition(testDischargeDisposition.dischargeDispositionObj.Id);
		testDischargeDisposition.dischargeDispositionObj.Status__c = 'Finalized';
		String saveResult = DischargeDispositionCtl.saveDischargeDisposition(testDischargeDisposition.dischargeDispositionObj);
		Test.stopTest();
		// System.assertEquals('SUCCESS', saveResult);
	}

	@isTest
	private static void testCreateEmergencyTransfer() {
		Account patient = [SELECT Id, Name, Current_Case__c FROM Account LIMIT 1];
		Test.startTest();
		DischargeDisposition testDischargeDisposition = DischargeDispositionCtl.createDischargeDisposition(patient.Id, true);
		DischargeDispositionCtl.DischargeDispositionRequest req = new DischargeDispositionCtl.DischargeDispositionRequest();
		req.patientId = patient.Id;
		req.dischargeDispositionOption = 'Emergency Transfer';
		List<DischargeDispositionCtl.DischargeDispositionRequest> request = new List<DischargeDispositionCtl.DischargeDispositionRequest>{ req };
		List<String> ddIds = DischargeDispositionCtl.createDischargeDisposition(request);
		System.assert(ddIds != null, 'Discharge Disposition can not be null');
		Test.stopTest();
	}

	@isTest
	private static void testCreateSharingRecordOnSectionToDDOwner() {
		Account patient = [SELECT Id, Name, Current_Case__c FROM Account LIMIT 1];
		Account institutionReferral = [SELECT Id FROM Account WHERE Name LIKE '%Medical Institution%' LIMIT 1];
		List<Contact> individualReferralList = [SELECT Id FROM Contact WHERE FirstName = 'Test'];
		DischargeDispositionCtl.getPatientById(patient.Id);
		DischargeDisposition testDischargeDisposition = DischargeDispositionCtl.createDischargeDisposition(patient.Id, false);
		DischargeDispositionCtl.getReferralPhone('institution', institutionReferral.Id);
		for (Contact individualReferral : individualReferralList) {
			DischargeDispositionCtl.getReferralPhone('individual', individualReferral.Id);
		}
		List<Discharge_Referral__c> referralList = new List<Discharge_Referral__c>();
		for (DischargeSection section : testDischargeDisposition.dischargeSectionList) {
			if (String.isNotBlank(section.dischargeSectionObj.Role__c) && section.dischargeSectionObj.Role__c.equalsIgnoreCase('social work')) {
				// Setup one referral for Social Worker
				Discharge_Referral__c individualReferralObj = new Discharge_Referral__c(Discharge_Disposition__c = testDischargeDisposition.dischargeDispositionObj.Id, Section__c = section.dischargeSectionObj.Id, Grouping__c = section.dischargeSectionObj.Role__c, Clinician__c = individualReferralList[0].Id, Referred_By__c = UserInfo.getUserId());
				Discharge_Referral__c institutionReferralObj = new Discharge_Referral__c(Discharge_Disposition__c = testDischargeDisposition.dischargeDispositionObj.Id, Section__c = section.dischargeSectionObj.Id, Grouping__c = section.dischargeSectionObj.Role__c, Institution__c = institutionReferral.Id, Referred_By__c = UserInfo.getUserId());
				referralList.add(individualReferralObj);
				referralList.add(institutionReferralObj);
			}
		}

		insert referralList;
		testDischargeDisposition = DischargeDispositionCtl.getDischargeDisposition(testDischargeDisposition.dischargeDispositionObj.Id);

		Test.startTest();
		//Test Print Draft DDR

		PageReference pageRef = Page.PrintDraftDDR;
		pageRef.getParameters().put('Id', testDischargeDisposition.dischargeDispositionObj.Id);
		pageRef.getParameters().put('purpose', 'Deliver to Patient');
		pageRef.getParameters().put('isDraft', 'true');

		Test.setCurrentPage(pageRef);
		PrintDraftDDRController csController = new PrintDraftDDRController();
		csController.init();
		csController.getHtmlText();

		// Setting up Social Worker Section testing
		DischargeSection socialWorkerSection;
		for (DischargeSection section : testDischargeDisposition.dischargeSectionList) {
			if (String.isNotBlank(section.dischargeSectionObj.Role__c) && section.dischargeSectionObj.Role__c.equalsIgnoreCase('social work')) {
				// Assigned for testing DischargeSectionCtl
				socialWorkerSection = section;
			}
		}
		String socialWorkerSectionString = DischargeSectionCtl.saveDischargeSection(JSON.serialize(socialWorkerSection));
		socialWorkerSection = (DischargeSection) JSON.deserialize(socialWorkerSectionString, DischargeSection.class);
		if (socialWorkerSection.removeReferralList == null) {
			socialWorkerSection.removeReferralList = new List<DischargeReferral>();
		}

		// Adding the referral to the removal WITHOUT removing it from referral list will cover the Rollback exception lines
		socialWorkerSection.removeReferralList.add(socialWorkerSection.referralList[0]);
		socialWorkerSection.dischargeSectionObj.Status__c = 'Completed';
		DischargeSectionCtl.saveDischargeSection(JSON.serialize(socialWorkerSection));
		DischargeSectionCtl.reopenDischargeSection(JSON.serialize(socialWorkerSection));
		DischargeDispositionCtl.saveDischargeDisposition(testDischargeDisposition.dischargeDispositionObj);
		DischargeDispositionCtl.cancelDischargeDisposition(testDischargeDisposition.dischargeDispositionObj.Id);
		Test.stopTest();

		Discharge_Disposition__c dischargeDisposition = [SELECT Owner.Id FROM Discharge_Disposition__c WHERE Id = :testDischargeDisposition.dischargeDispositionObj.Id];
		Discharge_Section__c dischargeSection = [SELECT Id FROM Discharge_Section__c WHERE Discharge_Disposition__c = :testDischargeDisposition.dischargeDispositionObj.Id LIMIT 1];
		Discharge_Section__Share dsShare = [SELECT AccessLevel, UserOrGroupId FROM Discharge_Section__Share WHERE ParentId = :dischargeSection.Id AND UserOrGroupId = :dischargeDisposition.OwnerId AND AccessLevel = 'All'];
		System.assert(null != dsShare);
		dischargeDisposition.Status__c = 'Cancel';
		TriggerFactory.Recursions.clear();
		update dischargeDisposition;
		TriggerFactory.Recursions.clear();
		delete dischargeDisposition;
	}
}
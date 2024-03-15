@isTest
public class AuthorizedSignersTest {
	public static void createAuthorizedSignerGroups() {
		List<Group> groups = new List<Group>();
		Group g1 = new Group(Name = 'Team A Authorized Signers', Type = 'Queue');
		groups.add(g1);

		Group g2 = new Group(Name = 'Team B Authorized Signers', Type = 'Queue');
		groups.add(g2);

		Group g3 = new Group(Name = 'Team C Authorized Signers', Type = 'Queue');
		groups.add(g3);
		insert groups;
	}

	@TestSetup
	static void createTestData() {
		//TODO: Create Users
		User objUser = new User(ProfileId = [SELECT Id FROM Profile LIMIT 1].Id, LastName = 'last', Email = 'puser000@amamama.com', Username = 'puser000@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
		insert objUser;

		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		//TODO: Create Group
		List<Group__c> groups = new List<Group__c>();

		Group__c g1 = new Group__c(
			//Audience__c = 'Staff',
			Name = 'Team A',
			Type__c = 'Team'
		);
		groups.add(g1);
		insert groups;

		//TODO: Create Staff Members
		Id gId = [SELECT Id FROM Group__c WHERE Name = 'Team A' LIMIT 1].Id;
		Id uId = [SELECT Id FROM User WHERE LastName = 'last' LIMIT 1].Id;

		Staff_Group_Member__c sgm = new Staff_Group_Member__c();
		sgm.name = 'Team A';
		sgm.Group_Name__c = gId;
		sgm.Staff_Member__c = uId;
		sgm.Authorized_Signer__c = true;
		sgm.Start_Date__c = Date.today();
		sgm.Planned_End_Date__c = Date.today() + 10;
		Staff_Group_Member__c objNew = AddGroupMemberController.saveStaffGroupMember(sgm, 'Role', sgm);

		//TODO: Create Admissions
		PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();

		//TODO: Create Treatment Plans
		List<Account> accList = [SELECT Id, Name, Current_Case__c, Current_Admission__c FROM Account LIMIT 1];
		List<Admission__c> admList = [SELECT Id FROM Admission__c LIMIT 1];

		if (accList.isEmpty()) {
			String message = 'No Accounts records created';
			throw new IllegalArgumentException(message);
		}

		Account patient = accList[0];
		Admission__c adm = admList[0];

		Case currentCase = new Case(AccountId = patient.Id, Admission__c = adm.Id);
		insert currentCase;

		patient.Current_Case__c = currentCase.Id;
		update patient;

		//TODO: Create Patient Notes
		//Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
		Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
		Patient_Note__c consultantNote = new Patient_Note__c(Account__c = patient.Id, Admission__c = patient.Current_Admission__c, Consultation_Assigned_Date__c = System.today(), Consultation_Requested_By__c = 'Patient', Type__c = 'Psychotherapy Consultation Note', RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId());
		insert consultantNote;
	}

	@isTest
	private static void getSignersByTreatmentPlanId() {
		List<Case> treatment = [SELECT Id FROM Case LIMIT 1];

		Test.startTest();
		Set<Id> idList = AuthorizedSigners.getSignersByTreatmentPlanId(treatment[0].Id);
		Test.stopTest();

		System.assert(idList.size() > 0, 'A list of Treatment Plan IDs was expected');
	}

	@isTest
	private static void getSignersByTreatmentPlanId_Negative() {
		Id fakeId = 'a138E000000N9dr';

		Test.startTest();
		Set<Id> idList = AuthorizedSigners.getSignersByTreatmentPlanId(fakeId);
		Test.stopTest();

		System.assert(idList == null, 'Null value was expected');
	}

	@isTest
	private static void getSignersByPatientNoteId() {
		List<Patient_Note__c> pnoteList = [SELECT Id FROM Patient_Note__c LIMIT 1];

		Test.startTest();
		Set<Id> idList = AuthorizedSigners.getSignersByPatientNoteId(pnoteList[0].Id);
		Test.stopTest();

		System.assert(idList.size() > 0);
	}

	@isTest
	private static void getSignersByPatientNoteId_Negative() {
		Id fakeId = 'a138E000000N9dr';

		Test.startTest();
		Set<Id> idList = AuthorizedSigners.getSignersByPatientNoteId(fakeId);
		Test.stopTest();

		System.assert(idList == null, 'Null value was expected');
	}

	@isTest
	private static void getSignersByPatientNoteId_null() {
		Id fakeId = null;

		Test.startTest();
		Set<Id> idList = AuthorizedSigners.getSignersByPatientNoteId(fakeId);
		Test.stopTest();

		System.assertEquals(null, idList, 'Null value was expected');
	}

	@isTest
	private static void getSignersByAdmissionId_null() {
		Id fakeId = null;

		Test.startTest();
		Set<Id> idList = AuthorizedSigners.getSignersByAdmissionId(fakeId);
		Test.stopTest();

		System.assertEquals(null, idList, 'Null value was expected');
	}

	@isTest
	private static void getQueueIdByAdmissionId() {
		List<Admission__c> admList = [SELECT Id FROM Admission__c LIMIT 1];
		Id admissionId = admList[0].Id;

		Test.startTest();

		Id qId = AuthorizedSigners.getAuthSignersQueueId(admissionId);

		Test.stopTest();

		Group theQueue = [SELECT Id, Name FROM Group WHERE Id = :qId];
		System.assertEquals('Team A Authorized Signers', theQueue.Name);
	}

	@isTest
	private static void testGetTeamMemberSigners() {
		Test.startTest();
		AuthorizedSigners.getTeamMemberSigners();
		Test.stopTest();
	}

	@isTest
	private static void testgetAuthorizedSigner() {
		Test.startTest();
		User u = [SELECT Id FROM User WHERE Email = 'puser000@amamama.com' LIMIT 1];
		AuthorizedSigners.getAuthorizedSigner(u.Id);
		Test.stopTest();
	}

	// @isTest
	// private static void getQueueIdByAdmissionId_badTeam()
	// {
	//     List<Admission__c> admList = [SELECT Id FROM Admission__c LIMIT 1];
	//     admList[0].Team__c = 'bad';
	//     update admList;
	//     Id admissionId = admList[0].Id;

	//     Test.startTest();

	//         Id qId = AuthorizedSigners.getAuthSignersQueueId(admissionId);

	//     Test.stopTest();

	//     System.assertEquals(null, qId);
	// }
}
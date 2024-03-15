@isTest
public class ClinicalTeamsTest {
	static Integer numberOfSGM = 5;
	static Integer numberOfUsers = 5;

	@TestSetup
	static void createTestData() {
		List<User> userList = new List<User>();
		Id profileId = [SELECT Id FROM Profile LIMIT 1].Id;

		for (Integer i = 0; i < numberOfUsers; i++) {
			//TODO: Create Users
			User objUser = new User(ProfileId = profileId, LastName = 'last-' + String.valueOf(i), Email = 'puser000' + String.valueOf(i) + '@amamama.com', Username = 'puser000' + String.valueOf(i) + '@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias-' + String.valueOf(i), TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');

			userList.add(objUser);
		}

		insert userList;

		//TODO: Create Queue Team
		List<Group__c> groups = new List<Group__c>();
		for (Integer i = 0; i < ClinicalTeams.teamsNames.size(); i++) {
			String name = ClinicalTeams.teamsNames[i];

			if (name.contains('Authorized'))
				continue;

			Group__c g1 = new Group__c(Name = name, Type__c = 'Team');
			groups.add(g1);
		}

		Group__c[] queueEnabledGroups = new List<Group__c>{ new Group__c(Name = 'Medical Records', Type__c = 'Staff', Queue_Enabled__c = true), new Group__c(Name = 'Patient Care', Type__c = 'Staff', Queue_Enabled__c = true), new Group__c(Name = 'Team', Type__c = 'Staff', Queue_Enabled__c = true) };

		groups.addAll(queueEnabledGroups);

		insert groups;

		//TODO: Create Staff Members
		List<Group__c> gpList = [SELECT Id, Name FROM Group__c];

		//Id gId = [SELECT Id FROM Group__c WHERE Name = 'Team A'].Id;
		//Id uId = [SELECT Id FROM User WHERE LastName = 'last'].Id;
		List<Staff_Group_Member__c> sgmList = new List<Staff_Group_Member__c>();
		for (Group__c gp : gpList) {
			Set<Id> alreadyUsedUserIds = new Set<Id>();
			for (Integer i = 0; i < numberOfSGM; i++) {
				Integer gpRandomNumber = Integer.valueof((Math.random() * gpList.size() - 1));
				Integer usRandomNumber = Integer.valueof((Math.random() * userList.size() - 1));
				Integer randomNumber = Integer.valueof((math.random() * 10));
				Boolean randomBoolean = Math.mod(randomNumber, 2) == 0 ? true : false;

				Staff_Group_Member__c sgm = new Staff_Group_Member__c();
				sgm.name = gp.Name;
				sgm.Group_Name__c = gp.Id;
				sgm.Staff_Member__c = userList[i].Id;
				sgm.Authorized_Signer__c = randomBoolean;
				sgm.Start_Date__c = Date.today().addDays(-10);
				sgm.Planned_End_Date__c = Date.today().addDays(10);
				// Staff_Group_Member__c objNew = AddGroupMemberController.saveStaffGroupMember(sgm, 'Role', sgm);
				// if (!alreadyUsedUserIds.contains(sgm.Staff_Member__c))
				// {
				//     alreadyUsedUserIds.add(sgm.Staff_Member__c);
				sgmList.add(sgm);
				// }
			}
		}

		for (Group__c gp : queueEnabledGroups) {
			Integer gpRandomNumber = Integer.valueof((Math.random() * gpList.size() - 1));
			Integer usRandomNumber = Integer.valueof((Math.random() * userList.size() - 1));
			Integer randomNumber = Integer.valueof((math.random() * 10));
			Boolean randomBoolean = Math.mod(randomNumber, 2) == 0 ? true : false;

			Staff_Group_Member__c sgm = new Staff_Group_Member__c();
			sgm.name = gp.Name;
			sgm.Group_Name__c = gp.Id;
			sgm.Staff_Member__c = userList[integer.valueof(Math.random() * (userList.size() - 1))].Id;
			sgm.Authorized_Signer__c = randomBoolean;
			sgm.Start_Date__c = Date.today().addDays(-10);
			sgm.Planned_End_Date__c = Date.today().addDays(10);
			sgmList.add(sgm);
		}

		insert sgmList;
	}

	@IsTest
	static void getTeamUserIdsByTeamName() {
		Test.startTest();
		Set<Id> usersIDs = ClinicalTeams.getTeamUserIdsByTeamName('Team A');
		Test.stopTest();
		//System.assert(usersIDs != null);
		//System.assert(usersIDs.size() > 0);
	}

	@IsTest
	static void syncGroupMembershipsToQueues() {
		List<GroupMember> teamAGms = [SELECT Id, UserOrGroupId, GroupId FROM GroupMember WHERE Group.Name = 'Team A'];
		//System.assertNotEquals(0, teamAGms.size());
		GroupMember badGm;
		User otherAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE AND Id != :Userinfo.getUserId() LIMIT 1];

		System.runAs(otherAdmin) {
			delete teamAGms;

			badGm = new GroupMember(GroupId = teamAGms[0].GroupId, UserOrGroupId = otherAdmin.Id);
			insert badGm;
		}
		teamAGms = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = 'Team A'];
		//System.assertEquals(1, teamAGms.size());

		//expected SGMs
		List<Staff_Group_Member__c> teamASgms = [SELECT Id, Staff_Member__c, Staff_Member__r.Name FROM Staff_Group_Member__c WHERE Group_Name_Text__c = 'Team A' AND Staff_Member__c != NULL AND Start_Date__c < :system.today().addDays(1) AND (Planned_End_Date__c = NULL OR Planned_End_Date__c > :system.today().addDays(-1))];
		//System.assertEquals(numberOfSGM, teamASgms.size());

		//not yet synched with Gms
		//System.assertNotEquals(teamAGms.size(), teamASgms.size(), 'teamAGms.size() ' + teamAGms.size() + ', teamASgms.size() ' + teamASgms.size());

		List<Group> queueList = [SELECT Id, Name, (SELECT Id, UserOrGroupId, GroupId FROM GroupMembers) FROM Group WHERE Name IN :ClinicalTeams.teamsNames AND Type = 'Queue'];
		//5 teams, 5 auth signer queues
		//System.assertEquals(10, queueList.size());

		// List<GroupMember> gmList = queueList[0].GroupMembers;

		// List<Staff_Group_Member__c> sgmList = [SELECT Id, Authorized_Signer__c FROM Staff_Group_Member__c];
		// sgmList[0].Authorized_Signer__c = true;
		//delete gmList;

		Test.startTest();
		ClinicalTeams.syncGroupMembershipsToQueues();

		Test.stopTest();

		//no exceptions in run
		List<Process_Log__c> plogs = [SELECT Id, Process__c, Stack_Trace__c, Detail__c FROM Process_Log__c];
		//System.assertEquals(0, plogs.size(), plogs);

		//removed invalid queue member
		List<GroupMember> newBadGms = [SELECT Id FROM GroupMember WHERE Id = :badGm.Id];
		//System.assertEquals(0, newBadGms.size());

		//same list for queue and sgms
		List<GroupMember> newTeamAGms = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = 'Team A'];
		//System.assertEquals( teamASgms.size(), newTeamAGms.size());
	}

	@isTest
	static void testTeamQueueIdByPatient() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')) };
		insert contactList;

		Contact testPatient = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = testPatient.AccountId, Patient_Contact__c = testPatient.Id, Stage__c = 'Consultation Pending', Team__c = 'A') };
		insert admissionList;

		Test.startTest();
		Id testTeamQueueId = ClinicalTeams.getTeamQueueIdByPatient(testPatient.AccountId, 'Team');
		Id testTeamAuthSignersQueueId = ClinicalTeams.getTeamQueueIdByPatient(testPatient.AccountId, 'Team Authorized Signers');

		Test.stopTest();

		Id teamQueueId = [SELECT Id FROM Group WHERE Name = 'Team A' AND Type = 'Queue'].Id;
		//System.assertEquals(teamQueueId, testTeamQueueId);
		Id teamAuthSignersQueueId = [SELECT Id FROM Group WHERE Name = 'Team A Authorized Signers' AND Type = 'Queue'].Id;
		//System.assertEquals(teamAuthSignersQueueId, testTeamAuthSignersQueueId);
	}

	// @isTest
	// static void testGetTeamQueueIdByPatientMapTwoParamaters() {
	//     Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

	//     List<Contact> contactList = new List<Contact> {
	//         new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact'))
	//     };
	//     insert contactList;

	//     Contact testPatient = [SELECT Id, AccountId  FROM Contact WHERE Id =: contactList[0].Id];

	//     List<Admission__c> admissionList = new List<Admission__c> {
	//             new Admission__c(Patient_Account__c = testPatient.AccountId, Patient_Contact__c = testPatient.Id, Stage__c='Consultation Pending', Team__c = 'A')
	//     };
	//     insert admissionList;

	//     Test.startTest();
	//         Map<Id, Id> mapResult = ClinicalTeams.getTeamQueueIdByPatientMap(new Set<Id>{testPatient.AccountId}, new Set<String>{'Team'});
	//     Test.stopTest();

	//     System.assert(mapResult != null);
	//     Id teamQueueId = mapResult.get(testPatient.AccountId);
	//     Group teamQueue = [SELECT Id, Name
	//                         FROM Group
	//                         WHERE Id = :teamQueueId];
	//     System.assertEquals('Team A', teamQueue.Name);
	// }

	@isTest
	static void testGetTeamQueueIdByPatientMapOneParameter() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')) };
		insert contactList;

		Contact testPatient = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = testPatient.AccountId, Patient_Contact__c = testPatient.Id, Stage__c = 'Consultation Pending', Team__c = 'A') };
		insert admissionList;

		Test.startTest();
		Map<Id, Map<String, Id>> mapResult = ClinicalTeams.getTeamQueueIdByPatientMap(new Set<Id>{ testPatient.AccountId });
		Test.stopTest();

		//System.assert(mapResult != null);
	}
}
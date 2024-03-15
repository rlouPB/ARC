@IsTest
public class discoFormTriggerHandlerTest {
	public static User[] createUsers() {
		List<User> userList = new List<User>();
		Id profileId = [SELECT Id FROM Profile LIMIT 1].Id;

		for (Integer i = 0; i < 3; i++) {
			//TODO: Create Users
			User objUser = new User(ProfileId = profileId, LastName = 'last-' + String.valueOf(i), Email = 'puser000' + String.valueOf(i) + '@amamama.com', Username = 'puser000' + String.valueOf(i) + '@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias-' + String.valueOf(i), TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');

			userList.add(objUser);
		}

		insert userList;
		return userList;
	}
	@Testsetup
	public static void setup() {
		User[] userList = createUsers();

		Contact c = (Contact) TestFactory_Patient.createSObject(new Contact(LastName = 'Test_Patient'), true);
		Contact accountWithContact = [SELECT Id, AccountId FROM Contact WHERE Id = :c.Id];

		Admission__c admission = (Admission__c) TestFactory_Patient.createSObject(new Admission__c(Patient_Account__c = accountWithContact.AccountId, Patient_Contact__c = c.Id, Team__c = 'A'), true);
		disco__Form_Template__c discoFormTemplate = (disco__Form_Template__c) TestFactory_Patient.createSObject(new disco__Form_Template__c(Name = 'Admissions Screening Checklist 1', disco__Status__c = 'In Use'), true);

		List<Account> accounts = [SELECT Id, Name, Current_Admission__c FROM Account WHERE Id = :accountWithContact.AccountId];
		accounts[0].Current_Admission__c = admission.Id;
		upsert accounts;

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{ new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id) };
		insert relatedContacts;

		Group__c[] queueEnabledGroups = new List<Group__c>{ new Group__c(Name = 'Medical Record', Type__c = 'Other', Queue_Enabled__c = true), new Group__c(Name = 'Patient Care', Type__c = 'Other', Queue_Enabled__c = true), new Group__c(Name = 'Team A', Type__c = 'Team') };

		insert queueEnabledGroups;

		Staff_Group_Member__c[] staffMembers = new List<Staff_Group_Member__c>{};

		for (Group__c gp : queueEnabledGroups) {
			Integer gpRandomNumber = Integer.valueof((Math.random() * queueEnabledGroups.size() - 1));
			Integer usRandomNumber = Integer.valueof((Math.random() * userList.size() - 1));
			Integer randomNumber = Integer.valueof((math.random() * 10));
			Boolean randomBoolean = Math.mod(randomNumber, 2) == 0 ? true : false;

			staffMembers.add(
				new Staff_Group_Member__c(
					name = gp.Name,
					Group_Name__c = gp.Id,
					Staff_Member__c = userList[integer.valueof(Math.random() * (userList.size() - 1))].Id,
					//Authorized_Signer__c = randomBoolean,
					Start_Date__c = Date.today().addDays(-10),
					Planned_End_Date__c = Date.today().addDays(10)
				)
			);
		}

		insert staffMembers;

		List<disco__Form__c> discoForms = new List<disco__Form__c>{ new disco__Form__c(disco__Form_Account__c = accounts[0].Id, Related_Contact__c = relatedContacts[0].Id, disco__Form_Template__c = discoFormTemplate.Id, disco__Archived__c = true, Admission__c = admission.Id, disco__Form_Contact__c = c.Id, disco__Mobile_ID__c = '123') };
		insert discoForms;
		List<disco__Question__c> discoQuestions = new List<disco__Question__c>{ new disco__Question__c(disco__Form_Template__c = discoFormTemplate.Id, disco__Label__c = 'test', disco__Type__c = 'Picklist', Selected_Question_Order__c = 1, disco__Order__c = 1, Alternate_Question_Order__c = 1, disco__Link_Field__c = 'Finalized_By__c', disco__Link_Object__c = 'disco__Form__c') };
		insert discoQuestions;

		List<disco__Answer__c> discoAnswers = new List<disco__Answer__c>{ new disco__Answer__c(disco__Answer__c = 'test', disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id), new disco__Answer__c(disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id), new disco__Answer__c(disco__Answer__c = 'test12', disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions[0].Id) };
		insert discoAnswers;
		List<disco__Answer__c> subAnswers = [SELECT Id, disco__Form__c, disco__Answer__c, disco__Question__r.disco__Link_Field__c, disco__Link_Object__c FROM disco__Answer__c WHERE disco__Link_Object__c = 'disco__Form__c' AND (disco__Question__r.disco__Link_Field__c = 'Finalized_By__c' OR disco__Question__r.disco__Link_Field__c = 'Finalized_Date_Time__c' OR disco__Question__r.disco__Link_Field__c = 'Finalized_By_Professional_Name__c') AND disco__Form__c = :discoForms[0].Id];
	}

	public static testMethod void testTeam() {
		Group TeamA = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Team A'];
		if ([SELECT COUNT() FROM GroupMember WHERE UserOrGroupId = :userinfo.getuserid() AND GroupId = :TeamA.Id] == 0) {
			insert new GroupMember(UserOrGroupId = userinfo.getuserid(), GroupId = TeamA.Id);
		}

		system.assertEquals(0, [SELECT COUNT() FROM Outstanding_Tag__c WHERE OwnerId = :TeamA.Id]);
		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(thisUser) {
			test.startTest();
			TriggerFactory.Recursions.clear();
			disco__Form__c form = [SELECT id FROM disco__Form__c LIMIT 1];
			form.Create_Open_Item_for_Team__c = true;
			form.disco__Locked__c = false;
			update form;
			test.stopTest();
		}

		TeamA = [SELECT id FROM Group WHERE Type = 'Queue' AND Name = 'Team A'];
		//system.assertEquals(1, [select count() from Outstanding_Tag__c where OwnerId=:TeamA.Id]);
	}
	public static testMethod void testPopulateFinalizedFields() {
		disco__Form__c form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		form.disco__Archived__c = false;
		form.disco__Locked__c = false;
		form.disco__Save_Complete__c = false;
		form.disco__Form_Edited__c = false;
		update form;
		form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		test.startTest();
		form.disco__Archived__c = false;
		form.disco__Locked__c = false;
		form.disco__Form_Edited__c = false;
		form.disco__Save_Complete__c = true;
		update form;
		form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		test.stopTest();
	}
	public static testMethod void testlockForm() {
		disco__Form__c form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		test.startTest();
		//discoFormTriggerHandler.updateAdmissionVisitorClinicalField(form);
		test.stopTest();
	}
	public static testMethod void testPopulateFinalizedFields2() {
		disco__Question__c question = [SELECT Id FROM disco__Question__c LIMIT 1];
		question.disco__Link_Field__c = 'Finalized_Date_Time__c';
		update question;
		disco__Form__c form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		form.disco__Archived__c = false;
		form.disco__Locked__c = false;
		form.disco__Save_Complete__c = false;
		form.disco__Form_Edited__c = false;
		update form;
		form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		test.startTest();
		form.disco__Archived__c = false;
		form.disco__Locked__c = false;
		form.disco__Form_Edited__c = false;
		form.disco__Save_Complete__c = true;
		update form;
		form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		test.stopTest();
	}
	public static testMethod void testPopulateFinalizedFields3() {
		disco__Question__c question = [SELECT Id FROM disco__Question__c LIMIT 1];
		question.disco__Link_Field__c = 'Finalized_By_Professional_Name__c';
		update question;
		disco__Form__c form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		form.disco__Archived__c = false;
		form.disco__Locked__c = false;
		form.disco__Save_Complete__c = false;
		form.disco__Form_Edited__c = false;
		update form;
		form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		test.startTest();
		form.disco__Archived__c = false;
		form.disco__Locked__c = false;
		form.disco__Form_Edited__c = false;
		form.disco__Save_Complete__c = true;
		update form;
		form = [SELECT id, disco__Status__c FROM disco__Form__c LIMIT 1];
		test.stopTest();
	}

	public static testMethod void testUpdate() {
		TriggerFactory.Recursions.clear();
		disco__Form__c form = [SELECT id, admission__c, Visitors_Clinical_Conferences__c FROM disco__Form__c LIMIT 1];
		test.startTest();
		form.Finalize_and_Lock_Application__c = true;
		form.disco__Original_Submitted_Date__c = Datetime.now();
		update form;
		discoFormTriggerHandler handler = new discoFormTriggerHandler();
		//handler.updateAdmissionVisitorClinicalField(form);
		test.stopTest();
	}
	public static testMethod void testDelete() {
		TriggerFactory.Recursions.clear();
		disco__Form__c form = [SELECT id FROM disco__Form__c LIMIT 1];
		test.startTest();
		delete form;
		test.stopTest();
	}

	public static testMethod void testMedicalRecords() {
		Group medicalRecordsQueue = [SELECT id FROM Group WHERE Type = 'Queue' AND Name = 'Medical Records'];
		system.assertEquals(0, [SELECT COUNT() FROM Outstanding_Tag__c WHERE OwnerId = :medicalRecordsQueue.Id]);

		test.startTest();
		TriggerFactory.Recursions.clear();
		disco__Form__c form = [SELECT id FROM disco__Form__c LIMIT 1];
		form.Create_Open_Item_for_Medical_Records__c = true;
		form.disco__Locked__c = false;
		update form;
		test.stopTest();

		medicalRecordsQueue = [SELECT id FROM Group WHERE Type = 'Queue' AND Name = 'Medical Records'];
		//system.assertEquals(1, [select count() from Outstanding_Tag__c]);
	}

	public static testMethod void testPatientCare() {
		Group medicalRecordsQueue = [SELECT id FROM Group WHERE Type = 'Queue' AND Name = 'Patient Care'];
		system.assertEquals(0, [SELECT COUNT() FROM Outstanding_Tag__c WHERE OwnerId = :medicalRecordsQueue.Id]);

		test.startTest();
		TriggerFactory.Recursions.clear();
		disco__Form__c form = [SELECT id FROM disco__Form__c LIMIT 1];
		form.Create_Open_Item_for_Patient_Care__c = true;
		form.disco__Locked__c = false;
		update form;
		test.stopTest();

		medicalRecordsQueue = [SELECT id FROM Group WHERE Type = 'Queue' AND Name = 'Patient Care'];
		//system.assertEquals(1, [select count() from Outstanding_Tag__c where OwnerId=:medicalRecordsQueue.Id]);
	}
}
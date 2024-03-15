@isTest
public class ListGroupMemberControllerTest {
	@testSetup
	static void setup() {
		List<User> usersList = new List<User>();

		User objUser = new User(ProfileId = [SELECT Id FROM Profile LIMIT 1].Id, LastName = 'last', Email = 'puser000@amamama.com', Username = 'puser000@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');

		usersList.add(objUser);

		User objUser1 = new User(ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id, LastName = 'last', Email = 'puser00@amamama.com', Username = 'puser00@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST1', Title = 'title1', Alias = 'alias2', TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');

		usersList.add(objUser1);

		insert usersList;

		Contact activePatientCon = new Contact();
		activePatientCon.LastName = 'Active Test Patient';
		insert activePatientCon;

		Contact patientCon = new Contact();
		patientCon.LastName = 'Test Patient';
		insert patientCon;

		Contact staffCon = new Contact();
		staffCon.LastName = 'Test Patient';
		insert staffCon;

		List<Group__c> groups = new List<Group__c>();
		Group__c g = new Group__c(Name = 'Patient Active Group', Type__c = 'Government', Active__c = true, Closed_Membership__c = false, Duration__c = 'Standing', OwnerId = objUser.Id, Primary_Function__c = 'Patient');
		groups.add(g);

		Group__c g1 = new Group__c(Name = 'Staff Active Group', Type__c = 'Other', Active__c = true, Closed_Membership__c = false, Duration__c = 'Standing', OwnerId = objUser1.Id, Primary_Function__c = 'Staff');

		groups.add(g1);

		Group__c g2 = new Group__c(Name = 'Patient Group', Type__c = 'Program', Active__c = false, Closed_Membership__c = false, Duration__c = 'Standing', OwnerId = userinfo.getUserId(), Primary_Function__c = 'Patient');
		groups.add(g2);

		Group__c g3 = new Group__c(Name = 'Staff Active Group', Type__c = 'Wellness', Active__c = true, Closed_Membership__c = false, Duration__c = 'Standing', Primary_Function__c = 'Staff');
		groups.add(g3);

		insert groups;
	}

	static testMethod void getActiveMembers() {
		List<Group__c> ActiveGroupMembers = [SELECT Id, Primary_Function__c FROM Group__c WHERE Active__c = TRUE];

		List<String> patientGroupMemId = new List<String>();
		List<String> staffGroupMemId = new List<String>();

		for (Group__c g : ActiveGroupMembers) {
			if (g.Primary_Function__c == 'Staff') {
				staffGroupMemId.add(g.Id);
			} else if (g.Primary_Function__c == 'Patient') {
				patientGroupMemId.add(g.Id);
			}
		}

		Test.startTest();

		ListGroupMemberController.getGroupMembers(staffGroupMemId[0]);
		ListGroupMemberController.getStaffGroupMembers(staffGroupMemId[0], 'Active');
		ListGroupMemberController.getPatientGroupMembers(patientGroupMemId[0], 'Active');
		Test.stopTest();
	}

	static testMethod void getAllMembers() {
		List<Group__c> groupMembers = [SELECT Id, Primary_Function__c FROM Group__c];

		List<String> patientGroupMemId = new List<String>();
		List<String> staffGroupMemId = new List<String>();

		for (Group__c g : groupMembers) {
			if (g.Primary_Function__c == 'Staff') {
				staffGroupMemId.add(g.Id);
			} else if (g.Primary_Function__c == 'Patient') {
				patientGroupMemId.add(g.Id);
			}
		}

		Test.startTest();

		ListGroupMemberController.getGroupMembers(staffGroupMemId[0]);
		ListGroupMemberController.getStaffGroupMembers(staffGroupMemId[0], 'all');
		ListGroupMemberController.getPatientGroupMembers(patientGroupMemId[0], 'all');
		Test.stopTest();
	}

	static testMethod void AccessToEditSysAdmin() {
		List<Group__c> groupMembers = [SELECT Id, Primary_Function__c FROM Group__c WHERE Type__c = 'Other'];

		Test.startTest();

		Boolean hasAccess = ListGroupMemberController.checkUserAccessToEdit(groupMembers[0].Id);

		Test.stopTest();

		system.assertEquals(true, hasAccess);
	}

	static testMethod void AccessToEditUser() {
		List<Group__c> groupMembers = [SELECT Id, Primary_Function__c FROM Group__c WHERE Type__c = 'Program'];

		Test.startTest();

		Boolean hasAccess = ListGroupMemberController.checkUserAccessToEdit(groupMembers[0].Id);

		Test.stopTest();

		system.assertEquals(true, hasAccess);
	}

	static testMethod void AccessToEditPermSet() {
		List<Group__c> groupMembers = [SELECT Id, Primary_Function__c FROM Group__c WHERE Type__c = 'Government'];

		Test.startTest();
		Boolean hasAccess = ListGroupMemberController.checkUserAccessToEdit(groupMembers[0].Id);
		//Boolean hasPermission = PermissionSets.hasPermissionSet(UserInfo.getUserId(),'Group Manager');
		Test.stopTest();

		system.assertEquals(true, hasAccess);
	}
}
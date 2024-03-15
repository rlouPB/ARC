@isTest
public class AddGroupMemberControllerTest {
	@testSetup
	static void setup() {
		User objUser = new User(ProfileId = [SELECT Id FROM Profile LIMIT 1].Id, LastName = 'last', Email = 'puser000@amamama.com', Username = 'puser000@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
		insert objUser;

		List<Group__c> groups = new List<Group__c>();
		Group__c g = new Group__c(
			//Audience__c = 'Patient',
			Name = 'Patient Group',
			Type__c = 'Program'
		);
		groups.add(g);

		Group__c g1 = new Group__c(
			//Audience__c = 'Staff',
			Name = 'Staff Group',
			Type__c = 'Other'
		);
		groups.add(g1);
		insert groups;

		Contact objContact = new Contact();
		objContact.LastName = 'Test';
		insert objContact;
	}
	static testMethod void testPatientGroupMember() {
		Id gId = [SELECT Id FROM Group__c WHERE Name = 'Patient Group'].Id;

		AddGroupMemberController.getRoles('Patient', gId);

		Test.startTest();

		Id cId = [SELECT Id FROM Contact WHERE LastName = 'Test'].Id;
		Patient_Group_Member__c pat = new Patient_Group_Member__c();
		pat.name = 'Test';
		pat.Group_Name__c = gId;
		pat.Patient__c = cId;
		pat.Start_Date__c = Date.today();
		pat.Planned_End_Date__c = Date.today() + 10;
		Patient_Group_Member__c objNew = AddGroupMemberController.saveGroupMember(pat, 'Role', pat);

		Id objQueryRecordId = [SELECT Id FROM Patient_Group_Member__c][0].Id;
		String memId = '' + objQueryRecordId;
		AddGroupMemberController.getPatientGroupMember(memId);

		Test.stopTest();

		System.assertEquals(objNew.Id, objQueryRecordId);
	}

	static testMethod void saveStaffGroupMember() {
		AddGroupMemberController.getRoles('Staff', null);

		Test.startTest();

		Id gId = [SELECT Id FROM Group__c WHERE Name = 'Staff Group'].Id;
		Id uId = [SELECT Id FROM User WHERE LastName = 'last' LIMIT 1].Id;

		Staff_Group_Member__c sgm = new Staff_Group_Member__c();
		sgm.name = 'Test';
		sgm.Group_Name__c = gId;
		sgm.Staff_Member__c = uId;
		sgm.Start_Date__c = Date.today();
		sgm.Planned_End_Date__c = Date.today() + 10;
		Staff_Group_Member__c objNew = AddGroupMemberController.saveStaffGroupMember(sgm, 'Role', sgm);

		Id objQueryRecordId = [SELECT Id FROM Staff_Group_Member__c][0].Id;
		String memId = '' + objQueryRecordId;
		AddGroupMemberController.getStaffGroupMember(memId);

		Test.stopTest();

		System.assertEquals(objNew.Id, objQueryRecordId);
	}
}
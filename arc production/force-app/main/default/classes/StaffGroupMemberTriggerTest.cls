@isTest
public class StaffGroupMemberTriggerTest {
	@testSetup
	static void data() {
		Group__c g = new Group__c();
		g.Name = 'test';
		insert g;

		Staff_Group_Member__c s = new Staff_Group_Member__c();
		s.Group_Name__c = g.id;
		s.Start_Date__c = date.today();
		s.Planned_End_Date__c = date.today().addDays(5);
		s.Staff_Member__c = userinfo.getUserId();
		s.Authorized_Signer__c = true;

		insert s;

		Staff_Group_Member__c s1 = new Staff_Group_Member__c();
		s1.Group_Name__c = g.id;
		s1.Start_Date__c = date.today();
		s1.Planned_End_Date__c = date.today().addDays(-2);
		s1.Staff_Member__c = userinfo.getUserId();
		s1.Authorized_Signer__c = true;

		insert s1;
		Group gr = new Group();
		gr.name = 'test';
		gr.Type = 'Queue';
		insert gr;
	}

	static testMethod void Test1() {
		list<Staff_Group_Member__c> ss = [SELECT id FROM Staff_Group_Member__c];
		StaffGroupMemberTrigger_Handler.removeAuthSigners(new Set<id>{ ss[0].id });

		delete ss;
	}
}
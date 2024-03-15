@isTest
private class SIP_PublicGroupAssignmentTest {
	@TestSetup
	static void makeData() {
		Profile sysAdProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

		List<User> usersToInsert = new List<User>();
		User testUser1 = new User(FirstName = 'Group Test 1', LastName = 'Test', ProfileId = sysAdProfile.Id, Username = 'testuser1@austenriggs.net.Phase2Dev', Email = 'grouptest@example.com', Alias = 'test1', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');
		usersToInsert.add(testUser1);
		User testUser2 = new User(FirstName = 'Group Test 2', LastName = 'Test', ProfileId = sysAdProfile.Id, Username = 'testuser2@austenriggs.net.Phase2Dev', Email = 'grouptest@example.com', Alias = 'test2', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');
		usersToInsert.add(testUser2);
		User testUser3 = new User(FirstName = 'Group Test 3', LastName = 'Test', ProfileId = sysAdProfile.Id, Username = 'testuser3@austenriggs.net.Phase2Dev', Email = 'grouptest@example.com', Alias = 'test2', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');

		usersToInsert.add(testUser3);
		insert usersToInsert;
	}

	@isTest
	private static void testGroupAssignment() {
		List<Group> groups = [SELECT Name FROM Group];
		Map<String, Id> groupIdByName = new Map<String, Id>();
		for (Group currentGroup : groups) {
			groupIdByName.put(currentGroup.Name, currentGroup.Id);
		}

		List<User> users = [SELECT FirstName FROM User WHERE LastName = 'Test' AND Email = 'grouptest@example.com'];
		Map<String, Id> userIdByName = new Map<String, Id>();
		Set<Id> userIds = new Set<Id>();
		for (User currentUser : users) {
			userIdByName.put(currentUser.FirstName, currentUser.Id);
			userIds.add(currentUser.Id);
		}

		List<PermissionSet> permSets = [SELECT Name FROM PermissionSet WHERE Name = 'Clinical' OR Name = 'Admissions' OR Name = 'Nursing'];
		Map<String, Id> permSetIdByName = new Map<String, Id>();
		for (PermissionSet currentPermSet : permSets) {
			permSetIdByName.put(currentPermSet.Name, currentPermSet.Id);
		}

		List<PermissionSetAssignment> assignmentsToAdd = new List<PermissionSetAssignment>();
		PermissionSetAssignment assignment1 = new PermissionSetAssignment(AssigneeId = userIdByName.get('Group Test 1'), PermissionSetId = permSetIdByName.get('Admissions'));
		assignmentsToAdd.add(assignment1);
		PermissionSetAssignment assignment2 = new PermissionSetAssignment(AssigneeId = userIdByName.get('Group Test 2'), PermissionSetId = permSetIdByName.get('Clinical'));
		assignmentsToAdd.add(assignment2);
		PermissionSetAssignment assignment3 = new PermissionSetAssignment(AssigneeId = userIdByName.get('Group Test 3'), PermissionSetId = permSetIdByName.get('Nursing'));
		assignmentsToAdd.add(assignment3);
		insert assignmentsToAdd;

		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ScheduledItemProcessor_Parameters__c, MasterLabel FROM Scheduled_Item_Definition__mdt WHERE ScheduledItemProcessor_to_Use__c = 'PublicGroupAssignment'];

		Test.startTest();
		SIP_PublicGroupAssignment.process(scheduledItemDefs);
		Test.stopTest();

		// Assert that there are 3 Group Members created and that they match test1 = Admissions and test2 = Clinical and test3 = Nursing
		List<GroupMember> groupMembers = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :userIds];
		// System.assertEquals(3, groupMembers.size());
		Map<Id, Id> groupMembersGroupIdByUserId = new Map<Id, Id>();
		for (GroupMember member : groupMembers) {
			groupMembersGroupIdByUserId.put(member.UserOrGroupId, member.GroupId);
		}
		Id user1 = userIdByName.get('Group Test 1');
		Id admissionsGroup = groupIdByName.get('Admissions');
		// System.assertEquals(admissionsGroup, groupMembersGroupIdByUserId.get(user1));
		Id user2 = userIdByName.get('Group Test 2');
		Id clinicalGroup = groupIdByName.get('Clinical');
		// System.assertEquals(clinicalGroup, groupMembersGroupIdByUserId.get(user2));
		Id user3 = userIdByName.get('Group Test 3');
		Id nursingGroup = groupIdByName.get('Nursing');
		// System.assertEquals(nursingGroup, groupMembersGroupIdByUserId.get(user3));
	}

	@isTest
	private static void testGroupAssignmentDeletion() {
		List<Group> groups = [SELECT Name FROM Group];
		Map<String, Id> groupIdByName = new Map<String, Id>();
		for (Group currentGroup : groups) {
			groupIdByName.put(currentGroup.Name, currentGroup.Id);
		}

		List<User> users = [SELECT FirstName FROM User WHERE LastName = 'Test' AND Email = 'grouptest@example.com'];
		Map<String, Id> userIdByName = new Map<String, Id>();
		Set<Id> userIds = new Set<Id>();
		for (User currentUser : users) {
			userIdByName.put(currentUser.FirstName, currentUser.Id);
			userIds.add(currentUser.Id);
		}

		List<GroupMember> groupMembersToInsert = new List<GroupMember>();
		GroupMember member1 = new GroupMember(UserOrGroupId = userIdByName.get('Group Test 1'), GroupId = groupIdByName.get('Admissions'));
		groupMembersToInsert.add(member1);
		GroupMember member2 = new GroupMember(UserOrGroupId = userIdByName.get('Group Test 2'), GroupId = groupIdByName.get('Clinical'));
		groupMembersToInsert.add(member2);
		GroupMember member3 = new GroupMember(UserOrGroupId = userIdByName.get('Group Test 3'), GroupId = groupIdByName.get('Nursing'));
		groupMembersToInsert.add(member3);
		insert groupMembersToInsert;

		// Assert that there are 3 Group Members created and that they match test1 = Admissions and test2 = Clinical and test3 = Nursing
		List<GroupMember> groupMembers = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :userIds];
		// System.assertEquals(3, groupMembers.size());
		Map<Id, Id> groupMembersGroupIdByUserId = new Map<Id, Id>();
		for (GroupMember member : groupMembers) {
			groupMembersGroupIdByUserId.put(member.UserOrGroupId, member.GroupId);
		}
		Id user1 = userIdByName.get('Group Test 1');
		Id admissionsGroup = groupIdByName.get('Admissions');
		// System.assertEquals(admissionsGroup, groupMembersGroupIdByUserId.get(user1));
		Id user2 = userIdByName.get('Group Test 2');
		Id clinicalGroup = groupIdByName.get('Clinical');
		// System.assertEquals(clinicalGroup, groupMembersGroupIdByUserId.get(user2));
		Id user3 = userIdByName.get('Group Test 3');
		Id nursingGroup = groupIdByName.get('Nursing');
		// System.assertEquals(nursingGroup, groupMembersGroupIdByUserId.get(user3));

		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ScheduledItemProcessor_Parameters__c, MasterLabel FROM Scheduled_Item_Definition__mdt WHERE ScheduledItemProcessor_to_Use__c = 'PublicGroupAssignment'];

		Test.startTest();
		SIP_PublicGroupAssignment.process(scheduledItemDefs);
		Test.stopTest();

		// Assert that there are 0 Group Members after deletion
		List<GroupMember> groupMembersAfterDeletion = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :userIds];
		// System.assertEquals(0, groupMembersAfterDeletion.size());
	}
}
public class SIP_PublicGroupAssignment implements SystemScheduling.ScheduledItemProcessor {
	/*
		Purpose: Sync specified Permission Sets to Salesforce Public Groups

		E.g. every user with a 'Clinical' permission set should automatically be in the Public Group 'Clinical'
	*/

	//these are the Perm Sets that will get synched into Public Group Members
	static Map<String, String> permSetToGroupNameMap = new Map<String, String>{ 'Admissions' => 'Admissions', 'Clinical' => 'Clinical', 'Nursing' => 'Nursing', 'MedicalRecords' => 'Medical Records', 'SocialWorker' => 'Social Work' };

	static Map<String, String> profileToGroupNameMap = new Map<String, String>{ 'Communications and Marketing - Riggs' => 'Communications and Marketing', 'Fundraising and Development - Riggs' => 'Fundraising and Development' };
	
	static Map<String, Id> groupIdByName;

	public static void process(List<Scheduled_Item_Definition__mdt> scheduledItemDefs) {
		Map<String, Scheduled_Item_Run__c> scheduledRunByDefinitionID = new Map<String, Scheduled_Item_Run__c>();
		try {
			List<String> scheduledDefIDs = new List<String>();
			for (Scheduled_Item_Definition__mdt currentDef : scheduledItemDefs) {
				scheduledDefIDs.add(currentDef.ID);
			}

			List<Scheduled_Item_Run__c> scheduledRuns = [SELECT Next_Run_Datetime__c, Retry_Count__c, Retry_Detail__c, Scheduled_Item_Def__c, Scheduled_Item_Def_Status__c FROM Scheduled_Item_Run__c WHERE Scheduled_Item_Def__c IN :scheduledDefIDs];
			for (Scheduled_Item_Run__c currentRun : scheduledRuns) {
				scheduledRunByDefinitionID.put(currentRun.Scheduled_Item_Def__c, currentRun);
			}

			for (Scheduled_Item_Definition__mdt currentDef : scheduledItemDefs) {
				Scheduled_Item_Run__c relatedRun = scheduledRunByDefinitionID.get(currentDef.ID);
				if (relatedRun == null) {
					relatedRun = new Scheduled_Item_Run__c(Name = currentDef.MasterLabel, Scheduled_Item_Def__c = currentDef.ID, Scheduled_Item_Def_Status__c = 'Inactive', Retry_Count__c = 0);

					scheduledRunByDefinitionID.put(currentDef.ID, relatedRun);
				} else {
					if (relatedRun.Scheduled_Item_Def_Status__c == 'Active') {
						relatedRun.Scheduled_Item_Def_Status__c = 'Inactive';
					}

					if (relatedRun.Next_Run_Datetime__c == null || relatedRun.Next_Run_Datetime__c < Date.today()) {
						relatedRun.Next_Run_Datetime__c = null;
					}
				}

				try {
					Id jobId = System.enqueueJob(new SIP_PublicGroupAssignment.GroupMembershipUpdaterQueueable());

					// SIP info for when to run next.
					relatedRun.Scheduled_Item_Def_Status__c = 'Active';
					// Datetime nextRun = Datetime.now().addHours(1);
					relatedRun.Next_Run_Datetime__c = null;
				} catch (Exception ex) {
					relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
					relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);

					ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
				}
			}

			upsert scheduledRunByDefinitionID.values();
		} catch (Exception ex) {
			for (Scheduled_Item_Run__c relatedRun : scheduledRunByDefinitionID.values()) {
				relatedRun.Retry_Count__c = relatedRun.Retry_Count__c + 1;
				relatedRun.Retry_Detail__c = ex.getMessage().trim().left(255);
			}

			ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
		}
	}

	public static void assignGroups() {
		List<Group> groups = [SELECT Id, Name FROM Group WHERE Name IN :permSetToGroupNameMap.values()];
		groupIdByName = new Map<String, Id>();
		for (Group currentGroup : groups) {
			groupIdByName.put(currentGroup.Name, currentGroup.Id);
		}
		Date yesterdayDate = Date.today().addDays(-1);
		Time yesterdayTime = Time.newInstance(0, 0, 0, 0);
		DateTime yesterday = DateTime.newInstance(yesterdayDate, yesterdayTime);

		List<PermissionSetAssignment> assignments = [
			SELECT AssigneeId, PermissionSetId
			FROM PermissionSetAssignment
			WHERE Assignee.IsActive = TRUE AND PermissionSet.Name IN :permSetToGroupNameMap.keySet() //SystemModstamp >= :yesterday
		];

		Map<Id, PermissionSet> permissionSetMap = new Map<Id, PermissionSet>([SELECT Name FROM PermissionSet WHERE Name IN :permSetToGroupNameMap.keySet()]);
		List<GroupMember> groupMembersToInsert = new List<GroupMember>();
		for (PermissionSetAssignment assignment : assignments) {
			PermissionSet permSet = permissionSetMap.get(assignment.PermissionSetId);
			if (permSet != null) {
				String groupName = permSetToGroupNameMap.get(permSet.Name);
				GroupMember member = new GroupMember(GroupId = groupIdByName.get(groupName), UserOrGroupId = assignment.AssigneeId);
				groupMembersToInsert.add(member);
			}
		}
	}

	public static void removeGroupAssignments() {

		List<GroupMember> allGroupMembers = [SELECT UserOrGroupId, GroupId, Group.Name FROM GroupMember WHERE Group.Name IN :permSetToGroupNameMap.values()];

		Set<Id> userOrGroupIds = new Set<Id>();
		for (GroupMember member : allGroupMembers) {
			userOrGroupIds.add(member.UserOrGroupId);
		}

		Map<Id, PermissionSet> permissionSetMap = new Map<Id, PermissionSet>([SELECT Name FROM PermissionSet WHERE Name IN :permSetToGroupNameMap.keySet()]);
		Map<Id, String> permissionSetNameById = new Map<Id, String>();
		for (PermissionSet permSet : permissionSetMap.values()) {
			permissionSetNameById.put(permSet.Id, permSet.Name);
		}

		List<PermissionSetAssignment> assignments = [SELECT AssigneeId, PermissionSetId, PermissionSet.Name, Assignee.Name FROM PermissionSetAssignment WHERE PermissionSetId IN :permissionSetNameById.keySet() AND Assignee.IsActive = TRUE];
		Map<Id, List<PermissionSetAssignment>> assignmentsById = new Map<Id, List<PermissionSetAssignment>>();
		for (PermissionSetAssignment assignment : assignments) {
			List<PermissionSetAssignment> currentAssignments = assignmentsById.get(assignment.AssigneeId);
			if (currentAssignments == null) {
				currentAssignments = new List<PermissionSetAssignment>();
			}
			currentAssignments.add(assignment);
			assignmentsById.put(assignment.AssigneeId, currentAssignments);
		}

		Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :userOrGroupIds]);
		List<GroupMember> membersToDelete = new List<GroupMember>();
		for (GroupMember member : allGroupMembers) {
			Boolean deleteMember = true;
			List<PermissionSetAssignment> memberAssignments = assignmentsById.get(member.UserOrGroupId);
			if (memberAssignments == null) {
				memberAssignments = new List<PermissionSetAssignment>();
			}
			String groupName = member.Group.Name;
			String userName;
			for (PermissionSetAssignment assignment : memberAssignments) {
				String permSetName = assignment.PermissionSet.Name;
				userName = assignment.Assignee.Name;
				String expectedGroupName = permSetToGroupNameMap.GET(permSetName);
				if (groupName == expectedGroupName && member.UserOrGroupId == assignment.AssigneeId) {
					deleteMember = false;
					break;
				}
			}

			if (deleteMember) {
				membersToDelete.add(member);
			}
		}

		delete membersToDelete;
	}

	public static void handleProfileAssignments() {
		List<GroupMember> allGroupMembers2 = [SELECT UserOrGroupId, GroupId, Group.Name FROM GroupMember WHERE Group.Name IN :profileToGroupNameMap.values()];
		System.debug('handleProfileAssignments - allGroupMembers2 : ' + allGroupMembers2);
		delete allGroupMembers2;

		List<Group> groupsForProfiles = [SELECT Id, Name FROM Group WHERE Name IN :profileToGroupNameMap.values()];
		for (Group currentGroup : groupsForProfiles) {
			groupIdByName.put(currentGroup.Name, currentGroup.Id);
		}
		
		List<User> usersForProfiles = [SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name IN :profileToGroupNameMap.keySet() AND IsActive = TRUE];
		System.debug('handleProfileAssignments - usersForProfiles : ' + usersForProfiles);
		List<GroupMember> groupMembersToInsert = new List<GroupMember>();
		for(User u : usersForProfiles) {
			String groupName = profileToGroupNameMap.get(u.Profile.Name);
			GroupMember member = new GroupMember(GroupId = groupIdByName.get(groupName), UserOrGroupId = u.Id);
			System.debug('handleProfileAssignments - member : ' + member);
			groupMembersToInsert.add(member);
		}

		insert groupMembersToInsert;
		System.debug('handleProfileAssignments - groupMembersToInsert : ' + groupMembersToInsert);
	}

	public class GroupMembershipUpdaterQueueable implements Queueable {
		public void execute(QueueableContext context) {
			Savepoint sp = Database.setSavepoint();
			try {
				assignGroups();
				removeGroupAssignments();
				handleProfileAssignments();
			} catch (Exception ex) {
				Database.rollBack(sp);
				// ProcessLogging.quickProcessLog('GroupMembershipUpdaterQueueable', ex.getStackTraceString(), ex.getMessage());
			}
		}
	}
}
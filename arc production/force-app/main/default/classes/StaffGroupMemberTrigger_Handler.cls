/**
 * @Description:
 * @Cerated By: fernando.ortiz@syanpticap.com
 */
public class StaffGroupMemberTrigger_Handler {
	@Future //This has to be a Future method since DML operation on setup object is not permitted after you have updated a non-setup object
	public static void addUsersToGroup(Set<Id> newStaffMembersIDs) {
		try {
			Map<Id, Staff_Group_Member__c> mapNewStaffMembers = new Map<Id, Staff_Group_Member__c>([SELECT Id, Group_Name_Text__c, Staff_Member__c, Authorized_Signer__c FROM Staff_Group_Member__c WHERE Id IN :newStaffMembersIDs AND Start_Date__c <= TODAY AND (Planned_End_Date__c >= TODAY OR Planned_End_Date__c = NULL) AND Staff_Member__r.IsActive = TRUE]);
			Map<String, Set<Id>> mapTeamUsers = new Map<String, Set<Id>>();

			//Get Group IDs
			Set<Id> groupIDs = new Set<Id>();
			Set<String> groupNames = new Set<String>();

			for (Staff_Group_Member__c sgm : mapNewStaffMembers.values()) {
				if (mapTeamUsers.containsKey(sgm.Group_Name_Text__c)) {
					Set<Id> userIDs = mapTeamUsers.get(sgm.Group_Name_Text__c);
					userIDs.add(sgm.Staff_Member__c);
					mapTeamUsers.put(sgm.Group_Name_Text__c, userIDs);
				} else {
					mapTeamUsers.put(sgm.Group_Name_Text__c, new Set<Id>{ sgm.Staff_Member__c });
				}

				//if this is a Aut Signer add it to the Auth Signers Team as well
				if (sgm.Authorized_Signer__c) {
					String keyName = sgm.Group_Name_Text__c + ' Authorized Signers';

					if (mapTeamUsers.containsKey(keyName)) {
						Set<Id> userIDs = mapTeamUsers.get(keyName);
						userIDs.add(sgm.Staff_Member__c);
						mapTeamUsers.put(keyName, userIDs);
					} else {
						mapTeamUsers.put(keyName, new Set<Id>{ sgm.Staff_Member__c });
					}
				}
			}

			//Get the Queues. Queues are stored as group objects with a type of Queue
			List<Group> queueList = [SELECT Id, Name FROM Group WHERE Name IN :mapTeamUsers.keySet() AND Type = 'Queue'];
			List<GroupMember> gpMembersToInsert = new List<GroupMember>();

			for (Group q : queueList) {
				for (Id userId : mapTeamUsers.get(q.Name)) {
					GroupMember member = new GroupMember();
					member.UserOrGroupId = userId;
					member.GroupId = q.Id;

					gpMembersToInsert.add(member);
				}
			}

			if (!gpMembersToInsert.isEmpty()) {
				insert gpMembersToInsert;
			}
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('StaffGroupMemberTrigger_Handler', ex.getStackTraceString(), ex.getMessage());
		}
	}

	@Future
	public static void removeDeletedMembersFromQueue(Set<Id> oldStaffMembersIDs, Boolean isDelete) {
		try {
			List<Staff_Group_Member__c> sgmList = new List<Staff_Group_Member__c>();
			// sgmList = [SELECT Id, Authorized_Signer__c, Staff_Member__c, Group_Name_Text__c FROM Staff_Group_Member__c WHERE Id IN: oldStaffMembersIDs AND IsDeleted = true ALL ROWS];

			if (isDelete) {
				sgmList = [SELECT Id, Authorized_Signer__c, Staff_Member__c, Group_Name_Text__c FROM Staff_Group_Member__c WHERE Id IN :oldStaffMembersIDs AND IsDeleted = TRUE ALL ROWS];
			} else {
				sgmList = [SELECT Id, Authorized_Signer__c, Staff_Member__c, Group_Name_Text__c FROM Staff_Group_Member__c WHERE Id IN :oldStaffMembersIDs AND Planned_End_Date__c != NULL AND Planned_End_Date__c < TODAY];
			}

			if (sgmList.isEmpty()) {
				return;
			}

			Set<Id> usersIDs = new Set<Id>();
			Set<String> teams = new Set<String>();
			Set<String> membersUniqueIDs = new Set<String>();

			for (Staff_Group_Member__c sgm : sgmList) {
				usersIDs.add(sgm.Staff_Member__c);
				teams.add(sgm.Group_Name_Text__c);
			}

			//Get the Queues. Queues are stored as group objects with a type of Queue
			Map<Id, Group> mapQueue = new Map<Id, Group>([SELECT Id, Name FROM Group WHERE Name IN :teams AND Type = 'Queue']);

			for (Staff_Group_Member__c sgm : sgmList) {
				for (Group g : mapQueue.values()) {
					if (sgm.Group_Name_Text__c == g.Name) {
						membersUniqueIDs.add(sgm.Staff_Member__c + '-' + g.Id);
					}
				}
			}

			List<GroupMember> membersToDelete = new List<GroupMember>();

			for (GroupMember gm : [SELECT Id, UserOrGroupId, GroupId FROM GroupMember WHERE UserOrGroupId IN :usersIDs AND GroupId IN :mapQueue.keySet()]) {
				if (membersUniqueIDs.contains(gm.UserOrGroupId + '-' + gm.GroupId)) {
					membersToDelete.add(gm);
				}
			}

			if (!membersToDelete.isEmpty()) {
				delete membersToDelete;

				//Remove related Auth Signers
				Map<Id, Staff_Group_Member__c> StaffMembers = new Map<Id, Staff_Group_Member__c>(sgmList);
				removeAuthSigners(StaffMembers);
			}
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('StaffGroupMemberTrigger_Handler', ex.getStackTraceString(), ex.getMessage());
		}
	}

	@Future
	public static void removeAuthSigners(Set<Id> newStaffMembersIDs) {
		Map<Id, Staff_Group_Member__c> mapNewStaffMembers = new Map<Id, Staff_Group_Member__c>([SELECT Id, Group_Name_Text__c, Staff_Member__c, Authorized_Signer__c FROM Staff_Group_Member__c WHERE Id IN :newStaffMembersIDs AND Authorized_Signer__c = FALSE]);

		removeAuthSigners(mapNewStaffMembers);
	}

	public static void removeAuthSigners(Map<Id, Staff_Group_Member__c> mapNewStaffMembers) {
		try {
			if (mapNewStaffMembers.isEmpty()) {
				return;
			}

			Set<Id> usersIDs = new Set<Id>();
			Set<String> teams = new Set<String>();
			Set<String> membersUniqueIDs = new Set<String>();

			for (Staff_Group_Member__c sgm : mapNewStaffMembers.values()) {
				usersIDs.add(sgm.Staff_Member__c);
				String team = sgm.Group_Name_Text__c + ' Authorized Signers';
				teams.add(team);
			}

			//Get the Queues. Queues are stored as group objects with a type of Queue
			Map<Id, Group> mapQueue = new Map<Id, Group>([SELECT Id, Name FROM Group WHERE Name IN :teams AND Type = 'Queue']);

			for (Staff_Group_Member__c sgm : mapNewStaffMembers.values()) {
				for (Group g : mapQueue.values()) {
					String team = sgm.Group_Name_Text__c + ' Authorized Signers';
					if (team == g.Name) {
						membersUniqueIDs.add(sgm.Staff_Member__c + '-' + g.Id);
					}
				}
			}

			List<GroupMember> membersToDelete = new List<GroupMember>();

			for (GroupMember gm : [SELECT Id, UserOrGroupId, GroupId FROM GroupMember WHERE UserOrGroupId IN :usersIDs AND GroupId IN :mapQueue.keySet()]) {
				if (membersUniqueIDs.contains(gm.UserOrGroupId + '-' + gm.GroupId)) {
					membersToDelete.add(gm);
				}
			}

			if (!membersToDelete.isEmpty()) {
				delete membersToDelete;
			}
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('StaffGroupMemberTrigger_Handler', ex.getStackTraceString(), ex.getMessage());
		}
	}

	@Future
	public static void syncGroupMembershipsToQueues() {
		ClinicalTeams.syncGroupMembershipsToQueues();
	}
}
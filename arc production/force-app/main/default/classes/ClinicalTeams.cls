public class ClinicalTeams {
	/**
	 * @Description: Apex utility class to handle details of Clinical Teams, including who is Authorized Signers, default Assigned Clinicians, managing Queues.
	 * @Created By: Fernando.ortiz@synapticap.com
	 */

	private Map<String, List<GroupMember>> teamNameToQueueMember = new Map<String, List<GroupMember>>();
	private Map<String, Set<Id>> teamNameToQueueMemberUserIds = new Map<String, Set<Id>>();
	private Map<String, List<Staff_Group_Member__c>> teamNameToStaffGroupMember = new Map<String, List<Staff_Group_Member__c>>();
	private Map<String, Set<Id>> teamNameToStaffGroupMemberUserIds = new Map<String, Set<Id>>();
	private Map<String, Group> teamNameToQueue = new Map<String, Group>();
	private set<string> queueEnabledGroupNames = new Set<string>();

	//queueEnabled
	private Map<String, Group> queueEnabledNameToQueue = new Map<String, Group>();
	private Map<String, List<GroupMember>> queueEnabledToQueueMembers = new Map<String, List<GroupMember>>();
	private Map<String, Set<Id>> queueEnabledToQueueMemberUserIds = new Map<String, Set<Id>>();
	private Map<String, List<Staff_Group_Member__c>> queueEnabledToStaffGroupMember = new Map<String, List<Staff_Group_Member__c>>();
	private Map<String, Set<Id>> queueEnabledToStaffGroupMemberUserIds = new Map<String, Set<Id>>();

	public static final String[] teamsNames = new List<String>{ 'Team A', 'Team B', 'Team C', 'Team D', 'Team E', 'Team A Authorized Signers', 'Team B Authorized Signers', 'Team C Authorized Signers', 'Team D Authorized Signers', 'Team E Authorized Signers' };

	private ClinicalTeams() {
		populateTeamNameMaps();
		queryQueueMembers();
		queryStaffGroupMembers();
	}

	private void populateTeamNameMaps() {
		for (String teamName : teamsNames) {
			teamNameToQueueMember.put(teamName, new List<GroupMember>());
			teamNameToQueueMemberUserIds.put(teamName, new Set<Id>());
			teamNameToStaffGroupMember.put(teamName, new List<Staff_Group_Member__c>());
			teamNameToStaffGroupMemberUserIds.put(teamName, new Set<Id>());
		}
	}

	private void queryQueueMembers() {
		try {
			//Get the Queues and members
			List<Group> queueList = [SELECT Id, Name, (SELECT Id, UserOrGroupId, GroupId FROM GroupMembers) FROM Group WHERE Name IN :teamsNames AND Type = 'Queue'];

			for (Group g : queueList) {
				if (teamsNames.contains(g.Name)) {
					teamNameToQueue.put(g.Name, g);
					teamNameToQueueMember.put(g.Name, g.GroupMembers);

					//collect teamNameToQueueMemberUserIds
					for (GroupMember gm : g.GroupMembers) {
						Set<Id> userIDs = teamNameToQueueMemberUserIds.get(g.Name);
						userIDs.add(gm.UserOrGroupId);
						teamNameToQueueMemberUserIds.put(g.Name, userIDs);
					}
				}
			}
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('ClinicalTeams.queryQueueMembers()', ex.getStackTraceString(), ex.getMessage());
		}
	}

	private void queryStaffGroupMembers() {
		try {
			List<Staff_Group_Member__c> sgmList = [SELECT Id, Group_Name__c, Group_Name_Text__c, Staff_Member__c, Authorized_Signer__c, Start_Date__c, Planned_End_Date__c, Group_Name__r.Queue_Enabled__c FROM Staff_Group_Member__c WHERE Group_Name__r.Type__c = 'Team' AND Staff_Member__c != NULL AND Start_Date__c < :system.today().addDays(1) AND (Planned_End_Date__c = NULL OR Planned_End_Date__c > :system.today().addDays(-1))];

			//collect teamNameToStaffGroupMember
			for (Staff_Group_Member__c sgm : sgmList) {
				if (sgm.Group_Name_Text__c.startsWith('Team')) {
					List<Staff_Group_Member__c> sgmRelatedList = teamNameToStaffGroupMember.get(sgm.Group_Name_Text__c);
					sgmRelatedList.add(sgm);
					teamNameToStaffGroupMember.put(sgm.Group_Name_Text__c, sgmRelatedList);
					teamNameToStaffGroupMemberUserIds.get(sgm.Group_Name_Text__c).add(sgm.Staff_Member__c);

					if (sgm.Authorized_Signer__c == true) {
						String authSignerName = sgm.Group_Name_Text__c + ' Authorized Signers';
						sgmRelatedList = teamNameToStaffGroupMember.get(authSignerName);
						sgmRelatedList.add(sgm);
						teamNameToStaffGroupMember.put(authSignerName, sgmRelatedList);
						teamNameToStaffGroupMemberUserIds.get(authSignerName).add(sgm.Staff_Member__c);
					}
				}
			}
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('ClinicalTeams.queryStaffGroupMembers()', ex.getStackTraceString(), ex.getMessage());
		}
	}

	private map<string, GroupMember[]> syncQueueEnabledQueues() {
		GroupMember[] queueMembersToRemove = new List<GroupMember>{};
		GroupMember[] queueMembersToInsert = new List<GroupMember>{};

		this.queueEnabledToQueueMembers = new Map<string, GroupMember[]>();
		this.queueEnabledToQueueMemberUserIds = new Map<string, set<id>>();
		this.queueEnabledToStaffGroupMember = new Map<string, Staff_Group_Member__c[]>();
		this.queueEnabledToStaffGroupMemberUserIds = new Map<string, set<id>>();

		Date TODAY = system.today();

		for (Group__c g : [SELECT Id, Name, (SELECT Id, Staff_Member__c FROM Staff_Group_Members__r WHERE Staff_Member__c != NULL AND Start_Date__c <= :TODAY AND (Planned_End_Date__c = NULL OR Planned_End_Date__c > :TODAY)) FROM Group__c WHERE Queue_Enabled__c = TRUE]) {
			this.queueEnabledGroupNames.add(g.Name);
			// if( !this.queueEnabledToStaffGroupMember.containsKey(g.Name) ){
			queueEnabledToStaffGroupMember.put(g.Name, g.Staff_Group_Members__r);
			// }
			// if ( !this.queueEnabledToStaffGroupMemberUserIds.containsKey(g.Name) ){
			this.queueEnabledToStaffGroupMemberUserIds.put(g.Name, new Set<Id>());
			for (Staff_Group_Member__c member : g.Staff_Group_Members__r) {
				this.queueEnabledToStaffGroupMemberUserIds.get(g.Name).add(member.Staff_Member__c);
			}
			// }
		}
		for (String queueName : this.queueEnabledGroupNames) {
			this.queueEnabledToQueueMembers.put(queueName, new List<GroupMember>());
			this.queueEnabledToQueueMemberUserIds.put(queueName, new Set<Id>());
		}
		List<Group> queueList = [SELECT Id, Name, (SELECT Id, UserOrGroupId, GroupId FROM GroupMembers) FROM Group WHERE Name IN :queueEnabledGroupNames AND Type = 'Queue'];
		for (Group g : queueList) {
			queueEnabledNameToQueue.put(g.Name, g);
			queueEnabledToQueueMembers.put(g.Name, g.GroupMembers);
			queueEnabledToQueueMemberUserIds.put(g.Name, new Set<id>());

			//collect queueEnabled members
			for (GroupMember gm : g.GroupMembers) {
				queueEnabledToQueueMemberUserIds.get(g.Name).add(gm.UserOrGroupId);
			}
		}
		//create GroupMembers if they're not there already
		for (String groupName : this.queueEnabledGroupNames) {
			for (Staff_Group_Member__c sgm : this.queueEnabledToStaffGroupMember.get(groupName)) {
				if (!this.queueEnabledToQueueMemberUserIds.get(groupName).contains(sgm.Staff_Member__c)) {
					Group GroupByName = queueEnabledNameToQueue.get(groupName);
					queueMembersToInsert.add(new GroupMember(UserOrGroupId = sgm.Staff_Member__c, GroupId = GroupByName.Id));
				}
			}
		}
		//remove GroupMembers if they're in the queue without SGM
		for (String queueName : this.queueEnabledGroupNames) {
			for (Id userId : this.queueEnabledToQueueMemberUserIds.get(queueName)) {
				if (!this.queueEnabledToStaffGroupMemberUserIds.get(queueName).contains(userId)) {
					//user in queue, but no Staff Group Member: remove Queue Member
					for (GroupMember gm : this.queueEnabledToQueueMembers.get(queueName)) {
						if (userId == gm.UserOrGroupId) {
							queueMembersToRemove.add(gm);
						}
					}
				}
			}
		}
		return new Map<string, GroupMember[]>{ 'toDelete' => queueMembersToRemove, 'toInsert' => queueMembersToInsert };
	}

	//lazy load construct teams class object as necessary
	private static ClinicalTeams teams {
		get {
			if (teams == null) {
				teams = new ClinicalTeams();
			}
			return teams;
		}
		set;
	}

	//cache team letters for patients
	private static Map<Id, String> patientId2TeamletterMap = new Map<Id, String>();
	private static Map<String, Id> queueName2QueueIdMap {
		get {
			if (queueName2QueueIdMap == null) {
				queryQueuesByName(); //lazy
			}
			return queueName2QueueIdMap;
		}
		set;
	}

	private static void queryQueuesByName() {
		queueName2QueueIdMap = new Map<String, Id>();
		for (Group g : [SELECT Id, Name FROM Group WHERE Name IN :ClinicalTeams.teamsNames AND Type = 'Queue']) {
			queueName2QueueIdMap.put(g.Name, g.Id);
		}
	}

	//queueTypes: 'Team' or 'Team Authorized Signers'
	public static Id getTeamQueueIdByPatient(Id patientId, String queueType) {
		//check map for patientId team letter if cached from a previous call
		String teamLetter = patientId2TeamletterMap.get(patientId);

		if (teamLetter == null) {
			//query patient current admission for Team value
			List<Account> pts = [SELECT Current_Admission__c, Current_Admission__r.Team__c FROM Account WHERE Id = :patientId];
			if (!pts.isEmpty() && pts[0].Current_Admission__c != null) {
				teamLetter = pts[0].Current_Admission__r.Team__c;
			}
		}
		patientId2TeamletterMap.put(patientId, teamLetter); //cache

		String queueName = 'Team ' + teamLetter + (queueType.contains('Authorized Signers') ? ' Authorized Signers' : '');
		return queueName2QueueIdMap.get(queueName);
	}
	public static Set<Id> getTeamUserIdsByTeamName(String teamName) {
		return teams.teamNameToStaffGroupMemberUserIds.get(teamName);
	}

	public static void syncGroupMembershipsToQueues() {
		teams = new ClinicalTeams();
		//Implement Rollback
		Savepoint sp = Database.setSavepoint();
		try {
			List<GroupMember> queueMembersToInsert = new List<GroupMember>();
			List<GroupMember> queueMembersToRemove = new List<GroupMember>();

			for (String teamName : teamsNames) {
				//auth signers are populated at the same time as the team
				if (teamName.contains('Authorized Signer'))
					continue;

				for (Staff_Group_Member__c sgm : teams.teamNameToStaffGroupMember.get(teamName)) {
					if (!teams.teamNameToQueueMemberUserIds.get(teamName).contains(sgm.Staff_Member__c)) {
						GroupMember member = new GroupMember();
						member.UserOrGroupId = sgm.Staff_Member__c;
						member.GroupId = teams.teamNameToQueue.get(teamName).Id;
						queueMembersToInsert.add(member);

						if (sgm.Authorized_Signer__c) {
							GroupMember authMember = new GroupMember();
							authMember.UserOrGroupId = sgm.Staff_Member__c;
							authMember.GroupId = teams.teamNameToQueue.get(teamName + ' Authorized Signers').Id;
							queueMembersToInsert.add(authMember);
						}
					}
				}
			}

			for (String teamQueue : teamsNames) {
				for (Id userId : teams.teamNameToQueueMemberUserIds.get(teamQueue)) {
					if (!teams.teamNameToStaffGroupMemberUserIds.get(teamQueue).contains(userId)) {
						//user in queue, but no Staff Group Member: remove Queue Member
						for (GroupMember gm : teams.teamNameToQueueMember.get(teamQueue)) {
							if (userId == gm.UserOrGroupId) {
								queueMembersToRemove.add(gm);
							}
						}
					}
				}
			}

			Map<String, List<GroupMember>> queueEnabledMembersMap = teams.syncQueueEnabledQueues();

			queueMembersToRemove.addAll(queueEnabledMembersMap.get('toDelete'));
			queueMembersToInsert.addAll(queueEnabledMembersMap.get('toInsert'));

			delete queueMembersToRemove;
			insert queueMembersToInsert;
		} catch (Exception ex) {
			Database.rollback(sp);
			ProcessLogging.quickProcessLog('ClinicalTeams.syncGroupMembershipsToQueues', ex.getStackTraceString(), ex.getMessage());
		}
	}

	public static Map<Id, Map<String, Id>> getTeamQueueIdByPatientMap(Set<Id> setPatientIDs) {
		if (setPatientIDs == null) {
			return null;
		}

		//Collect queue Names
		Map<String, List<Id>> mapQueueNamePatient = new Map<String, List<Id>>();

		for (Account acc : [SELECT Id, Team__c, Current_Admission__r.Team__c FROM Account WHERE Id IN :setPatientIDs]) {
			// User Set<Id> setPatientIDs

			String queueName = 'Team ' + acc.Current_Admission__r.Team__c;
			String authQueueName = queueName + ' Authorized Signers';

			//Collect Non Authorize teams
			if (!mapQueueNamePatient.containsKey(queueName)) {
				mapQueueNamePatient.put(queueName, new List<Id>());
			}
			List<Id> idSet = mapQueueNamePatient.get(queueName);
			idSet.add(acc.Id);
			mapQueueNamePatient.put(queueName, idSet);

			//Collect Authorize teams
			if (!mapQueueNamePatient.containsKey(authQueueName)) {
				mapQueueNamePatient.put(authQueueName, new List<Id>());
			}

			idSet = mapQueueNamePatient.get(authQueueName);
			idSet.add(acc.Id);
			mapQueueNamePatient.put(authQueueName, idSet);
		}

		Map<Id, Map<String, Id>> mapPatientQueue = new Map<Id, Map<String, Id>>();

		for (Group queue : [SELECT Id, Name, Type FROM Group WHERE Name IN :mapQueueNamePatient.keySet() AND Type = 'Queue']) {
			for (Id patientId : mapQueueNamePatient.get(queue.Name)) {
				if (!mapPatientQueue.containsKey(patientId)) {
					mapPatientQueue.put(patientId, new Map<String, Id>());
				}
				Map<String, Id> mapQueueTypeQueueId = mapPatientQueue.get(patientId);

				if (!queue.Name.contains('Authorized')) {
					mapQueueTypeQueueId.put('Team', queue.Id);
				}

				if (queue.Name.contains('Authorized')) {
					mapQueueTypeQueueId.put('Team Authorized Signers', queue.Id);
				}
			}
		}
		return mapPatientQueue;
	}
}
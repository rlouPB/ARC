/**
 * @Description: Utility Class to manage authorized signer logic
 * @Created By: Fernando Ortiz
 */

public class AuthorizedSigners {
	private static map<Id, User> authorizedSignerMap = new Map<Id, User>();
	public static User getAuthorizedSigner(Id userId) {
		if (!authorizedSignerMap.containsKey(userId)) {
			User u = [SELECT Id, Requires_Social_Work_Co_Signature__c, Requires_Co_Signature__c FROM User WHERE Id = :userId];
			authorizedSignerMap.put(u.Id, u);
		}
		return authorizedSignerMap.get(userId);
	}
	public static Set<Id> getSignersByTreatmentPlanId(Id treatmentPlanId) {
		//Query Treatment Plan
		List<Case> treatList = [SELECT Id, Admission__c FROM Case WHERE Id = :treatmentPlanId];

		if (treatList.isEmpty()) {
			return null;
		}

		return getSignersByAdmissionId(treatList[0].Admission__c);
	}

	public static Set<Id> getSignersByPatientNoteId(Id patientNoteId) {
		//Query Patient Note
		List<Patient_Note__c> pNoteList = [SELECT Admission__c FROM Patient_Note__c WHERE Id = :patientNoteId];

		if (pNoteList.isEmpty()) {
			return null;
		}

		return getSignersByAdmissionId(pNoteList[0].Admission__c);
	}

	public static Set<Id> getSignersByAdmissionId(Id admissionId) {
		Set<Id> signersIDs;
		//Query Admission record
		List<Admission__c> admList = [SELECT Id, Team__c FROM Admission__c WHERE Id = :admissionId];

		if (admList.isEmpty()) {
			return null;
		}

		Admission__c adm = admList[0];

		String team = 'Team ' + adm.Team__c;

		//Query Staff_Group_Member__c that is active and Authorized Signer and Group Membership has Type 'Team' and Group Membership has name 'Team ' + Team__c.
		//E.g. if Patient has Team__c = 'B' then we're looking for Group__c called "Team B"
		Map<Id, User> mapUsers = new Map<Id, User>([SELECT Id FROM User WHERE Id IN (SELECT Staff_Member__c FROM Staff_Group_Member__c WHERE Group_Name__r.Type__c = 'Team' AND Group_Name__r.Name = :team AND Authorized_Signer__c = TRUE AND (Planned_End_Date__c >= TODAY OR Planned_End_Date__c = NULL))]);

		signersIDs = mapUsers.keySet();

		return signersIDs;
	}

	public static Id getAuthSignersQueueId(Id admissionId) {
		//Query Admission record for Team__c field
		Admission__c adm = [SELECT Id, Team__c FROM Admission__c WHERE Id = :admissionId LIMIT 1];

		//Construct Queue name: "Team " + adm.Team__c + " Authorized Signers"
		String queueName = 'Team ' + adm.Team__c + ' Authorized Signers';

		// //Query Groups
		// List<Group> groupList = [SELECT Id, Name FROM Group WHERE Name =: queueName AND Type = 'Queue'];

		// if (groupList.isEmpty()) {
		//     return null;
		// }

		// //return Id if Group found
		// return groupList[0].Id;
		return getAuthSignersQueueIdByQueueName(queueName);
	}

	public static Id getAuthSignersQueueIdByQueueName(String queueName) {
		//Query Groups
		List<Group> groupList = [SELECT Id, Name FROM Group WHERE Name = :queueName AND Type = 'Queue'];

		if (groupList.isEmpty()) {
			return null;
		}

		//return Id if Group found
		return groupList[0].Id;
	}

	public static Set<Id> getTeamMemberSigners() {
		Set<Id> userList = new Set<Id>();
		List<GroupMember> members = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN (SELECT Id FROM Group WHERE Name LIKE 'Team%Authorized Signers' AND Type = 'Queue')];

		for (GroupMember m : members) {
			userList.add(m.UserOrGroupId);
		}
		return userList;
	}

	public static Set<Id> getSocialWorkTeamMemberSigners() {
		Set<Id> userList = new Set<Id>();
		List<GroupMember> members = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN (SELECT Id FROM Group WHERE Name = 'Social Work Authorized Signers' AND Type = 'Queue')];

		for (GroupMember m : members) {
			userList.add(m.UserOrGroupId);
		}
		return userList;
	}
}
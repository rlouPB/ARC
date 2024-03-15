public class PermissionSets {
	public static Map<Id, Set<String>> userId2PermSetAssignmentIdsMap = new Map<Id, Set<String>>();

	public static Boolean hasPermissionSet(Id UserId, String perSetName) {
		/*List<PermissionSetAssignment> psa = [SELECT Id
                                             FROM PermissionSetAssignment
                                             WHERE AssigneeId =: UserId
                                             AND PermissionSet.Label =: perSetName
                                             	AND Assignee.IsActive = true];
        if(psa.size() > 0){
            return true;
        }
        else{
            return false;
        }*/

		queryUserPermSets(UserId);

		if (userId2permSetAssignmentIdsMap.get(UserId).contains(perSetName)) {
			return true;
		} else {
			return false;
		}
	}

	public static Set<Id> getUserIdsWithPermSet(String perSetName) {
		List<PermissionSetAssignment> psa = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Label = :perSetName AND Assignee.IsActive = TRUE];
		Set<Id> userIds = new Set<Id>();
		for (PermissionSetAssignment p : psa) {
			userIds.add(p.Id);
		}

		return userIds;
	}

	public static void queryUserPermSets(Id userId) {
		List<PermissionSetAssignment> psa = [SELECT AssigneeId, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :UserId AND Assignee.IsActive = TRUE];

		for (PermissionSetAssignment p : psa) {
			Set<String> permSetNames = new Set<String>();
			if (userId2PermSetAssignmentIdsMap.containsKey(p.AssigneeId)) {
				permSetNames = userId2PermSetAssignmentIdsMap.get(p.AssigneeId);
				permSetNames.add(p.PermissionSet.Label);
			} else {
				permSetNames.add(p.PermissionSet.Label);
				userId2PermSetAssignmentIdsMap.put(p.AssigneeId, permSetNames);
			}
		}
	}
}
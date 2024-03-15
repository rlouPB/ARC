@isTest
public class PermissionSetsTest {
	// public static String permSetLable = 'Group Manager';

	static testMethod void hasPermissionSetsTest() {
		PermissionSet ps = new PermissionSet(Name = 'Test', Label = 'Test');
		insert ps;

		PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
		insert psa;

		// List<PermissionSetAssignment> psa = [
		//     SELECT Id, AssigneeId, PermissionSet.Label, Assignee.IsActive
		//     FROM PermissionSetAssignment
		//     WHERE PermissionSet.Label = 'Test'
		//     AND Assignee.IsActive = true
		// ];

		Boolean result = PermissionSets.hasPermissionSet(psa.AssigneeId, 'Test');
		PermissionSets.getUserIdsWithPermSet('Test');
		system.assertEquals(true, result);
	}

	static testMethod void hasPermissionSetsNegativeTest() {
		// List<PermissionSetAssignment> psa = [SELECT Id, AssigneeId, PermissionSet.Label, Assignee.IsActive
		//                                      FROM PermissionSetAssignment
		//                                      WHERE PermissionSet.Label != :permSetLable
		//                                      	AND Assignee.IsActive = true];

		Boolean result = PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'Test');
		system.assertNotEquals(true, result);
	}
}
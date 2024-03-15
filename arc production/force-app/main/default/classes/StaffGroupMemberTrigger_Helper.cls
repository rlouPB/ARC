/**
 * @Description:
 * @Cerated By: fernando.ortiz@syanpticap.com
 */
public class StaffGroupMemberTrigger_Helper {
	public static void afterInsert(Map<Id, Staff_Group_Member__c> mapNewStaffMembers) {
		//avoid throwing exception when running from batch
		if (!System.isBatch() && !System.isFuture()) {
			StaffGroupMemberTrigger_Handler.addUsersToGroup(mapNewStaffMembers.keySet());
			StaffGroupMemberTrigger_Handler.syncGroupMembershipsToQueues();
		}
		// else {
		// ProcessLogging.quickProcessLog('StaffGroupMemberTrigger_Helper.afterInsert', '',
		//         'Skipped 2 lines because currently running in ' + ((System.isBatch()) ? 'Batch' : 'Future') + ' mode. recordIds: \n\n' + JSON.serialize(Trigger.newMap.keySet()));
		// }
	}

	public static void afterUpdate(Map<Id, Staff_Group_Member__c> mapOldStaffMembers, Map<Id, Staff_Group_Member__c> mapNewStaffMembers) {
		//avoid throwing exception when running from batch
		if (!System.isBatch() && !System.isFuture()) {
			StaffGroupMemberTrigger_Handler.addUsersToGroup(mapNewStaffMembers.keySet());
			//StaffGroupMemberTrigger_Handler.removeAuthSigners(mapOldStaffMembers.keySet());
			StaffGroupMemberTrigger_Handler.removeDeletedMembersFromQueue(mapOldStaffMembers.keySet(), false);
			StaffGroupMemberTrigger_Handler.syncGroupMembershipsToQueues();
			Set<Id> staffIds = new Set<Id>();
			for (String key : mapNewStaffMembers.keyset()) {
				if (!mapNewStaffMembers.get(key).authorized_signer__c) {
					staffIds.add(mapNewStaffMembers.get(key).Id);
				}
			}
			if (staffIds.size() != 0) {
				StaffGroupMemberTrigger_Handler.removeAuthSigners(staffIds);
			}
		}
		//  else {
		// ProcessLogging.quickProcessLog('StaffGroupMemberTrigger_Helper.afterUpdate', '',
		//         'Skipped 3 lines because currently running in ' + ((System.isBatch()) ? 'Batch' : 'Future') + ' mode. recordIds: \n\n' + JSON.serialize(Trigger.newMap.keySet()));
		// }
	}

	public static void afterDelete(Map<Id, Staff_Group_Member__c> mapOldStaffMembers) {
		//StaffGroupMemberTrigger_Handler.removeDeletedMembersFromQueue(mapOldStaffMembers.keySet(), true);
		//avoid throwing exception when running from batch
		if (!System.isBatch() && !System.isFuture()) {
			StaffGroupMemberTrigger_Handler.removeDeletedMembersFromQueue(mapOldStaffMembers.keySet(), true);
		}
		// else {
		// ProcessLogging.quickProcessLog('StaffGroupMemberTrigger_Helper.afterDelete', '',
		//         'Skipped 1 lines because currently running in ' + ((System.isBatch()) ? 'Batch' : 'Future') + ' mode. recordIds: \n\n' + JSON.serialize(Trigger.oldMap.keySet()));
		// }
	}
}
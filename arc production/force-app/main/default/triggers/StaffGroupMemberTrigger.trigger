/**
 * @Description: Handle all DML transaction for the Staff Group Member Object
 * @Cerated By: fernando.ortiz@syanpticap.com
 */
trigger StaffGroupMemberTrigger on Staff_Group_Member__c (before insert, before update, after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            StaffGroupMemberTrigger_Helper.afterInsert(Trigger.newMap);
        }
        if (Trigger.isUpdate) {
            StaffGroupMemberTrigger_Helper.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isDelete) {
            StaffGroupMemberTrigger_Helper.afterDelete(Trigger.oldMap);
        }
    }
}
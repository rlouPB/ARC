/**
 * @Description:
 * @Created By: Fernando Ortiz
 */

trigger AllergyTrigger on Allergy__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) 
{
    if (Trigger.isBefore)
    {
        if (Trigger.isDelete)
        {
            AllergyTrigger_Helper.beforeDelete(Trigger.old);
        }
    }

    if (Trigger.isAfter) {
        
        if (Trigger.isInsert) {
            AllergyTrigger_Helper.afterInsert(Trigger.newMap);
        }

        if (Trigger.isUpdate) {
            AllergyTrigger_Helper.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}
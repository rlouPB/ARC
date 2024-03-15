public class ActionItemCompleteQuickactionCtl {
    @AuraEnabled
    public static string completeActionItem(string actionItemId){
        try{
            Action_Item__c item = new Action_Item__c(
                Id = actionItemId,
                Status__c = 'Completed',
                Completed_Date__c = system.now()
            );
            update item;
            
            delete [select id from Outstanding_Tag__c where Object__c = 'Action_Item__c' and Record_ID__c =:item.Id];
        }catch(Exception ex){
            return ex.getMessage();
        }
        return null;
    }
}
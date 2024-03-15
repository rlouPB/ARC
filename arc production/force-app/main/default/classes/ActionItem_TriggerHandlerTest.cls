@IsTest
public class ActionItem_TriggerHandlerTest {
    @TestSetup
    static void makeData(){
        Action_Item__c n = new Action_Item__c();   
        insert n;
    }
    public static testmethod void testUpdate() {
        Action_Item__c n = [Select id from Action_Item__c limit 1];
        update n;     
    }
    public static testmethod void testDelete() {
        delete [Select id from Action_Item__c limit 1];
    }
}
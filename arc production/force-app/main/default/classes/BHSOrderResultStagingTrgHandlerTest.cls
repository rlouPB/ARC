@isTEst
public class BHSOrderResultStagingTrgHandlerTest {
    class OrderResult {
        public String MessageId;
        public String MessageBody;
    }
    static testmethod void test1(){
        BHS_Order_Result_Staging__c stage = new BHS_Order_Result_Staging__c();
        stage.status__c = 'In Progress';
        OrderREsult orr = new orderREsult();
        orr.MessageId = '123455';
        orr.messageBody='saeadasdsad';
        stage.Payload__c = JSON.serialize(new list<OrderREsult>{orr});
        insert stage;
        update stage;
        BHS_Order_Result_StagingTriggerHandler handler = new BHS_Order_Result_StagingTriggerHandler();
        handler.afterUpdate(stage,stage);
        handler.beforeUpdate(stage,stage);
        handler.afterDelete(Stage);
        handler.beforeDelete(Stage);
        
        delete stage;
    }
}
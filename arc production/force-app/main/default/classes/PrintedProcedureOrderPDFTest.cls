@isTest
class PrintedProcedureOrderPDFTest 
{
    static testmethod void testController()
    {
        //Create Patient and Procedure Order
        Account acc =new account();
        acc.name = 'test';
        insert acc;
        
        id recid = Schema.SObjectType.Procedure_Order__c.getRecordTypeInfosByName().get('Lab Order').getRecordTypeId();
        
        Procedure_Order__c po= new Procedure_Order__c();
        po.Patient_Account__c = acc.id;
        po.RecordTypeId = recid;
        po.Finalized_By_User__c = UserInfo.getUserId();
        po.Phone_Order_MD__c = po.id;
        insert po;
        
        String testPoId = '';
        Test.startTest();
            Test.setCurrentPage(new Pagereference('/PrintedProcedureOrderPDFController?poId=' + po.id));
            //Test.setCurrentPage(new Pagereference('/PrintedProcedureOrderPDFController'));
            PrintedProcedureOrderPDFController ctl = new PrintedProcedureOrderPDFController();
            PageReference pr = ctl.init();
        Test.stopTest();
    }
}
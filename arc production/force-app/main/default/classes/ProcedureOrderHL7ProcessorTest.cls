@isTest private with sharing class ProcedureOrderHL7ProcessorTest {
    @TestSetup
    static void makeData()
    {
        ProcedureOrdersTest.createAdmittedPatient();
        Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
        Account patientAccount = [SELECT Id, Current_Admission__c
                                FROM Account
                                WHERE Recordtype.Name = 'Patient'
                                    AND Current_Admission_Stage__c = 'Admitted'
                                LIMIT 1];
        Id recordTypeId =Schema.SObjectType.Procedure_Order__c.getRecordTypeInfosByDeveloperName().get('Lab_Order').getRecordTypeId();

        Procedure_Order__c labPO = new Procedure_Order__c(
            Patient_Account__c = patientAccount.Id,
            Admission__c = patientAccount.Current_Admission__c,
            RecordtypeId = recordTypeId,
            Date_of_Order__c = System.today(),
            Activation_Date__c = System.today().addDays(1),
            Repeating__c = false,
            Status__c = 'Draft',
            Active__c = false,
            Executed__c = false);
        insert labPO;

        Compendium_Entry__c ce = new Compendium_Entry__c(Name = 'CBC', Test_Name__c='Complete Blood Count', Category__c='LAB', Start_Date__c = DateTime.now());
        insert ce;

        Lab_Observation__c lo = new Lab_Observation__c(Procedure_Order__c = labPO.Id, Compendium_Entry__c=ce.Id);
        insert lo;
    }
    @isTest private static void testLogin() {
        BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockLogin',
                                                    null);
        Test.setMock(HttpCalloutMock.class, loginResp);
        Test.startTest();
        String tokenPayload = ProcedureOrderHL7Processor.getAccessToken();
        Test.stopTest();
        StaticResource sr= [select id,body from StaticResource Where Name = 'BHS_MockLogin'];
        System.assertEquals(sr.body.toString(), tokenPayload);

        // Map<String, Object> strAccessToken = (Map<String, Object>) JSON.deserializeUntyped(tokenPayload);
        // String accessToken = (String) strAccessToken.get('jwt');
        // SingleRequestMock fakeContactsResp = new SingleRequestMock(200,
        //                                             'Complete',
        //                                             '[{"LastName": "Test Last Name"}]',
        //                                             null);

        // Map<String, HttpCalloutMock> endpoint2TestResp =
        //                             new Map<String,HttpCalloutMock>();
        // endpoint2TestResp.put('http://api.example.com/accounts',fakeAccountResp);
        // endpoint2TestResp.put('http://api.example.com/contacts',fakeContactsResp);

        // HttpCalloutMock multiCalloutMock =
        //                             new MultiRequestMock(endpoint2TestResp);

        // Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        // ProcessAccountsContacts.processAccountsContacts();
        // System.assertEquals(/*check for expected results here...*/);
        //BHS_CalloutMockRetrieval emptyQueue = new BHS_CalloutMockRetrieval();
    }

    @isTest private static void testOrederSendDisabled() {
        BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockLogin',
                                                    null);
        BHS_SingleRequestMock orderResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockOrder',
                                                    null);
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                    new Map<String,HttpCalloutMock>();
        ProcedureOrderHL7Processor.LIFEPOINT_SETTING = 'Send_Disabled';
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(ProcedureOrderHL7Processor.LIFEPOINT_SETTING);
        
        endpoint2TestResp.put(lp.Login_Endpoint__c,loginResp);
        endpoint2TestResp.put(lp.Order_Endpoint__c,orderResp);

        HttpCalloutMock multiCalloutMock =
                                    new BHS_MultiRequestMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Procedure_Order__c po = [SELECT Id from Procedure_Order__c limit 1];
        Procedure_Result__c procResult = new Procedure_Result__c(
                Status__c = 'Pending',
                Procedure_Order__c = po.Id ,
                Date__c = Date.Today()
            );
        insert procResult;
        Test.startTest();
        BHS_ORM_Staging__c staging = ProcedureOrderHL7Processor.sendOrder(po.Id, procResult.Id);
        System.assertEquals(null, staging.Error_Message__c);
        System.assertEquals('Send HL7 Message to LifePoint is disabled!', staging.ACK_Message__c);
        Test.stopTest();
    }

    @isTest private static void testOrederSendEnabled() {
        BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockLogin',
                                                    null);
        BHS_SingleRequestMock orderResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockOrder',
                                                    null);
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                    new Map<String,HttpCalloutMock>();
        ProcedureOrderHL7Processor.LIFEPOINT_SETTING = 'Send_Enabled';
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(ProcedureOrderHL7Processor.LIFEPOINT_SETTING);
        
        endpoint2TestResp.put(lp.Login_Endpoint__c,loginResp);
        endpoint2TestResp.put(lp.Order_Endpoint__c,orderResp);

        HttpCalloutMock multiCalloutMock =
                                    new BHS_MultiRequestMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Procedure_Order__c po = [SELECT Id from Procedure_Order__c limit 1];
        Procedure_Result__c procResult = new Procedure_Result__c(
                Status__c = 'Pending',
                Procedure_Order__c = po.Id ,
                Date__c = Date.Today()
            );
        insert procResult;
       
        Test.startTest();
        BHS_ORM_Staging__c staging = ProcedureOrderHL7Processor.sendOrder(po.Id, procResult.Id);
        
        System.assertEquals(null, staging.Error_Message__c);
        System.assertNotEquals(null, staging.ACK_Message__c);
        
        Test.stopTest();
    }

    @isTest private static void testOreder401Error() {
        BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockLogin',
                                                    null);
        BHS_SingleRequestMock orderResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockOrder401Error',
                                                    null);
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                    new Map<String,HttpCalloutMock>();
        ProcedureOrderHL7Processor.LIFEPOINT_SETTING = 'Send_Enabled';
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(ProcedureOrderHL7Processor.LIFEPOINT_SETTING);
        
        endpoint2TestResp.put(lp.Login_Endpoint__c,loginResp);
        endpoint2TestResp.put(lp.Order_Endpoint__c,orderResp);

        HttpCalloutMock multiCalloutMock =
                                    new BHS_MultiRequestMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Procedure_Order__c po = [SELECT Id from Procedure_Order__c limit 1];
        Procedure_Result__c procResult = new Procedure_Result__c(
                Status__c = 'Pending',
                Procedure_Order__c = po.Id ,
                Date__c = Date.Today()
            );
        insert procResult;
       
        Test.startTest();
        BHS_ORM_Staging__c staging = ProcedureOrderHL7Processor.sendOrder(po.Id, procResult.Id);
        
        System.assertNotEquals(null, staging.Error_Message__c);
        System.assertEquals(null, staging.ACK_Message__c);
        System.assertEquals('Error', staging.Status__c);
        System.assertEquals(null, [SELECT Id, Sent_Date_Time__c  FROM Procedure_Result__c where id = :procResult.Id].Sent_Date_Time__c);


        
        Test.stopTest();
    }
    @isTest private static void testResultRetrieval() {
        BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200,
                                                    'Complete',
                                                    'BHS_MockLogin',
                                                    null);
        BHS_QueuedRequestMock resultResp = new BHS_QueuedRequestMock(200,
                                                    'Complete', [Select Id from Lab_Observation__c limit 1].Id,
                                                    null);
        BHS_QueuedRequestMock.setStaticResourceQueue(new List<String>{'BHS_MockPotassium'});
        System.debug('retrieveOrderResult testResultRetrieval');
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                    new Map<String,HttpCalloutMock>();
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(ProcedureOrderHL7Processor.LIFEPOINT_SETTING);
        
        endpoint2TestResp.put(lp.Login_Endpoint__c,loginResp);
        endpoint2TestResp.put(lp.Result_Endpoint__c,resultResp);

        HttpCalloutMock multiCalloutMock =
                                    new BHS_MultiRequestMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Test.startTest();
        Procedure_Order__c po = [SELECT Id from Procedure_Order__c limit 1];
        ProcedureOrderHL7Processor.retrieveOrderResult();
        List<BHS_Order_Result_Staging__c> staging = [SELECT Id from BHS_Order_Result_Staging__c];
        System.assertEquals(1, staging.size(), 'There should have one record in staging table');
        Test.stopTest();
        System.assertEquals(1, [SELECT id FROM Lab_Observation_Result__c].size());
        System.assertEquals(1, [SELECT id FROM Lab_Result_Item__c].size());

        List<Lab_Observation_Result__c> results = [SELECT Id, (SELECT ID from Lab_Result_Items__r) FROM Lab_Observation_Result__c];
        System.assertEquals(1, results[0].Lab_Result_Items__r.size());

        List<Lab_Observation__c> obvs = [SELECT Id , (SELECT Id FROM Lab_Observation_Results__r) FROM Lab_Observation__c];
        System.assertEquals(1, obvs.size());
        //System.assertEquals(1, obvs[0].Lab_Observation_Results__r.size());
        Lab_Observation__c lab = obvs[0];
        lab.Stat_Flag__c = true;
        TriggerFactory.Recursions.clear();
        update lab;
        TriggerFactory.Recursions.clear();
        delete lab;
    }

}
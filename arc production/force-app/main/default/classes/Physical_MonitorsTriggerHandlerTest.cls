@isTest
public class Physical_MonitorsTriggerHandlerTest {


    @TestSetup
    static void makeData(){
        PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();
    }
    
     @IsTest
    static void testPhysicalMonitorFieldAutomation1(){
        Account patient = [SELECT Id, Current_Admission__c from Account LIMIT 1];
        System.debug('patient : ' + patient);
        Physical_Monitor__c pm2 = new Physical_Monitor__c(
            Account__c = patient.Id,
            Status__c = 'Finalized',
            Height_in__c = 80,
            BP_Cuff_Size__c = 'Large'
            
        );
        insert pm2;
    }
    
    @IsTest
    static void testPhysicalMonitorFieldAutomation(){

        Account patient = [SELECT Id, Current_Admission__c from Account LIMIT 1];
        System.debug('patient : ' + patient);
        Physical_Monitor__c pm1 = new Physical_Monitor__c(
            Account__c = patient.Id
        );

        Admission__c admission = [SELECT Id, Height_in__c, BP_Cuff_Size__c from Admission__c WHERE Id = :patient.Current_Admission__c];
        System.debug('admission #1 : ' + admission);

        Test.startTest();
        insert pm1;
        pm1 = [SELECT Id, Height_in__c, BP_Cuff_Size__c from Physical_Monitor__c WHERE Id = :pm1.Id];
        System.assertEquals(admission.Height_in__c, pm1.Height_in__c);
        System.assertEquals(admission.BP_Cuff_Size__c, pm1.BP_Cuff_Size__c);

        pm1.Height_in__c = 80;
        pm1.BP_Cuff_Size__c = 'Large';
        pm1.Status__c = 'Finalized';
        TriggerFactory.Recursions.clear(); 
        update pm1;
        
        pm1.Status__c = 'Finalized';
        //update pm1;

        admission = [SELECT Id, Height_in__c, BP_Cuff_Size__c from Admission__c WHERE Id = :patient.Current_Admission__c];
        System.debug('admission #2 : ' + admission);
        
        
        /*System.assertEquals(pm1.Height_in__c, admission.Height_in__c);
        System.assertEquals(pm1.BP_Cuff_Size__c, admission.BP_Cuff_Size__c);*/
        Test.stopTest();        
    }

}
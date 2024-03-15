@isTest
public with sharing class DynamicListViewControllerTest {
    @TestSetup
    static void makeData(){
        Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
        List<Contact> patientContactList = new List<Contact> { 
            new Contact(LastName = 'TestPatient_0', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact'))
        };
        insert patientContactList;   
        Account patient=[SELECT Id, Name FROM Account limit 1];
        
        Printed_Medical_Record_Request__c request1 = new Printed_Medical_Record_Request__c(Patient_Account__c=patient.Id, Status__c = 'Open');
        Printed_Medical_Record_Request__c request2 = new Printed_Medical_Record_Request__c(Patient_Account__c=patient.Id, Status__c = 'Open');
        Printed_Medical_Record_Request__c request3 = new Printed_Medical_Record_Request__c(Patient_Account__c=patient.Id, Status__c = 'Completed');
        Printed_Medical_Record_Request__c request4 = new Printed_Medical_Record_Request__c(Patient_Account__c=patient.Id, Status__c = 'Completed');
        Printed_Medical_Record_Request__c request5 = new Printed_Medical_Record_Request__c(Patient_Account__c=patient.Id, Status__c = 'Completed', End_Date__c=Date.Today().addDays(-2));
        List<Printed_Medical_Record_Request__c> requests = new List<Printed_Medical_Record_Request__c>{request1, request2, request3, request4, request5}; 
        insert request5;
    }
    @IsTest
    static void testLightningDataTableController() 
    {
        Account patient=[SELECT Id, Name FROM Account limit 1];
        Test.startTest();
            DynamicListViewController.getSobjectRecords('Printed_Medical_Record_Request__c', 'Medical_Record_List_View', 
                                                        'Patient_Account__c', 'Status__c = \'Open\' AND (End_Date__c >= TODAY OR END_Date__c = NULL)',
                                                        patient.Id, true, 'Createddate desc', true, true);
        Test.stopTest();
    }

    @IsTest
    static void testLightningDataTableController2() 
    {
        Account patient=[SELECT Id, Name FROM Account limit 1];
	 	Test.startTest();
            DynamicListViewController.getSobjectRecords('Printed_Medical_Record_Request__c', 'Medical_Record_List_View', 
                'Patient_Account__c', 'Status__c = \'Open\' AND (Createddate > NOW())',
                patient.Id, false, 'Createddate desc', false, true);
            DynamicListViewController.getSobjectRecords('Printed_Medical_Record_Request__c', 'Medical_Record_List_View', 
                'Patient_Account__c', 'Status__c = \'Open\' AND (Createddate > NOW())',
                null, false, 'Createddate desc', true, true);
            try{
                DynamicListViewController.getSobjectRecords('Printed_Medical_Record_Request__c', 'Medical_Record_List_View', 
                    'Patient_Account__c', null,
                    null, false, 'Createddate desc', false, true);
            } catch (Exception e) {

            }
            DynamicListViewController.getSobjectRecords('Printed_Medical_Record_Request__c', 'Medical_Record_List_View', 
                null, null,
                null, false, 'Createddate desc', false, true);
        Test.stopTest();
    }

    @IsTest
    static void testLightningDataTableController3() 
    {
        DynamicListViewController.DataTableColumns col = new DynamicListViewController.DataTableColumns('test','test','test', true);
        System.assertEquals(null, col.typeAttributes, 'typeAttributes should be null');
    }
    
}
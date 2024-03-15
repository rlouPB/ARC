@isTest
public class LookupComponentControllerTest {

    @testsetup static void setup(){
        
        List<Contact> conList = new List<Contact> {
            new Contact(FirstName = 'xj', LastName = 'TestCon1'),
            new Contact(FirstName = 'dw', LastName = 'TestCon2'),
            new Contact(LastName = 'TestCon3')
        };
        insert conList;
        
        List<Account> accountsList = new List<Account> {
            new Account(Name='TestRecOne',Type = 'Prospect', Description = 'Description Test First', Emergency_Contact__c = conList[0].Id),
            new Account(Name='TestRecTwo',Type = 'Other', Description = 'Description Test Second', Emergency_Contact__c = conList[1].Id),
            new Account(Name='TestRecThree',Type = 'Corporate', Description = 'Description Test Third', Emergency_Contact__c = conList[2].Id),
            new Account(Name='TestRecFour',Type = 'Prospect', Description = 'Description Test Fourth')
        };
        insert accountsList;        
    }
    
    private static testmethod void testfetchRecords()
    {
        List<Contact> conList = [SELECT Id, Name FROM Contact];
        List<Account> accList = [SELECT Id, Name, type, Description FROM Account];        
        //List<LookupComponentController.Criterion> testFilters = new List<LookupComponentController.Criterion>();
        //LookupComponentController.Criterion newCriterion = new LookupComponentController.Criterion('Name', '!=', 'badName');
        //testFilters.add(newCriterion);
        //String serializedTestFilters = JSON.serialize(testFilters);
        String serializedTestFilters = '[{"fieldName": "Name", "condition": "!=", "value": "badName"}]';
        Test.startTest();
            List<LookupComponentController.RecordWrapper> wrpInsList = new List<LookupComponentController.RecordWrapper>();
            
            // Tested with empty displayField and empty filterStr.
            String resultStr = LookupComponentController.fetchRecords('Test', 'Account', 'Name', '', 'Name', serializedTestFilters, False, 5, '', '');       
            System.assertEquals(resultStr, JSON.serialize(wrpInsList));
            
            // Tested with displayFieldValue as Id and no matched records.
            String resultStr3 = LookupComponentController.fetchRecords('Test', 'Account', 'Type', 'Name', 'Id', serializedTestFilters, False, 5, '', '');
            System.assertEquals(resultStr3, JSON.serialize(wrpInsList)); 
            
            // Tested with displayFieldValue as Id and matched records.
            String resultStr4 = LookupComponentController.fetchRecords('Pro', 'Account', 'Type', 'Name', 'Id', serializedTestFilters, False, 5, '', 'Patient_Contact__r.Distinguished_Name__c');
            List<LookupComponentController.RecordWrapper> wrpInsList1 = (List<LookupComponentController.RecordWrapper>) JSON.deserialize(resultStr4,List<LookupComponentController.RecordWrapper>.class);          
            System.assertEquals(2, wrpInsList1.size());
                    
            // Tested with displayFieldValue as Description and matched records.
            String resultStr6 = LookupComponentController.fetchRecords('Pro P', 'Account', 'Type,Name', 'Name', 'Description', serializedTestFilters, true, 10, '', '  Id ASC ');
            List<LookupComponentController.RecordWrapper> wrpInsList3 = (List<LookupComponentController.RecordWrapper>) JSON.deserialize(resultStr6,List<LookupComponentController.RecordWrapper>.class);
            System.assertEquals(2, wrpInsList3.size());
                   
            // Tested with filterStr and displayFieldValue as Description and matched records.
            String resultStr7 = LookupComponentController.fetchRecords('Pro', 'Account', 'Type,Name', 'Name', 'Description', serializedTestFilters, True, 5, '', 'Name');
            List<LookupComponentController.RecordWrapper> wrpInsList4 = (List<LookupComponentController.RecordWrapper>) JSON.deserialize(resultStr7,List<LookupComponentController.RecordWrapper>.class);
            System.assertEquals(2, wrpInsList4.size());  

            // special search contact firstname and lastname
            String resultStr8 = LookupComponentController.fetchRecords('d test', 'Contact', 'FirstName,Name', 'Name', 'Description', serializedTestFilters, True, 5, 'FirstLast|Starting', 'FirstName ASC ');
            List<LookupComponentController.RecordWrapper> wrpInsList5 = (List<LookupComponentController.RecordWrapper>) JSON.deserialize(resultStr8,List<LookupComponentController.RecordWrapper>.class);
            System.assertEquals(1, wrpInsList5.size());  
             
            // special search contact firstname and lastname
            String resultStr9 = LookupComponentController.fetchRecords('test', 'Contact', 'FirstName,Name', 'Name', 'Description', serializedTestFilters, True, 5, 'FirstLast|Starting', ' LastName ASC, FirstName DESC NULLS LAST');
            List<LookupComponentController.RecordWrapper> wrpInsList6 = (List<LookupComponentController.RecordWrapper>) JSON.deserialize(resultStr9,List<LookupComponentController.RecordWrapper>.class);
            System.assertEquals(3, wrpInsList6.size());  
        Test.stopTest();
         
    }
    
    private static testmethod void testgetRecord(){
        List<Contact> conList = [SELECT Id, Name FROM Contact];
        List<Account> accList = [SELECT Id, Name, type, Description FROM Account];
        
        // Tested with empty displayFieldValue.
        String resultStr = LookupComponentController.getRecord('Account','Type','',String.valueOf(conList[0].Id));
        LookupComponentController.RecordWrapper wrpIns = new LookupComponentController.RecordWrapper();
        System.assertEquals(resultStr, JSON.serialize(wrpIns));
        
        //Tested with displayFieldValue as lookup field.
        /*String resultStr1 = LookupComponentController.getRecord('Account','Type','Emergency_Contact__c ',String.valueOf(conList[0].Id));
        LookupComponentController.RecordWrapper wrpInsResult = (LookupComponentController.RecordWrapper) JSON.deserialize(resultStr1,LookupComponentController.RecordWrapper.class);
        System.assertEquals('Prospect', wrpInsResult.label);*/
        
        //Tested with displayFieldValue as Name.
        String resultStr1 = LookupComponentController.getRecord('Account','Type','Name','TestRecOne');
        LookupComponentController.RecordWrapper wrpInsResult = (LookupComponentController.RecordWrapper) JSON.deserialize(resultStr1,LookupComponentController.RecordWrapper.class);
        System.assertEquals('Prospect', wrpInsResult.label);
        
    }

}
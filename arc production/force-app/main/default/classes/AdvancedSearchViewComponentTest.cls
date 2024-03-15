@isTest
public class AdvancedSearchViewComponentTest {
	@testSetup static void setup() {

         
            //Related Contact RecordTypeId
            String personalRelatedContactRecordTypeId = Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
            String professionalRelatedContactRecordTypeId = Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName().get('Professional').getRecordTypeId();
            
            //Contact RecordTypeId
            String personalContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
            String professionalContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Professional').getRecordTypeId();
    
            List<Contact> contacts = new List<Contact>{
                new Contact(LastName = 'Test_Patient1',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(LastName = 'Test_Patient2',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(LastName = 'Test_Patient3',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(LastName = 'Test_Patient4',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(LastName = 'Test_Patient5',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(RecordTypeId = professionalContactRecordTypeId,LastName = 'Test_Patient6',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(RecordTypeId = professionalContactRecordTypeId,LastName = 'Test_Patient61',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(RecordTypeId = professionalContactRecordTypeId,LastName = 'Test_Patient62',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890'),
                new Contact(RecordTypeId = professionalContactRecordTypeId,LastName = 'Test_Patient63',Gender__c='Male',MailingCity = 'test',HomePhone='1234567890')
           };
            insert contacts;
            Map<Id,Contact> accountWithContact = new  Map<Id,Contact>([SELECT Id,AccountId  FROM Contact]);

            
    
            List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
                new Related_Contact__c(Contact__c  = contacts[0].Id, Account__c = accountWithContact.get(contacts[0].Id).AccountId,RecordTypeId = personalRelatedContactRecordTypeId ),
                new Related_Contact__c(Contact__c  = contacts[1].Id, Account__c = accountWithContact.get(contacts[0].Id).AccountId,RecordTypeId = personalRelatedContactRecordTypeId ),
                new Related_Contact__c(Contact__c  = contacts[2].Id, Account__c = accountWithContact.get(contacts[0].Id).AccountId,RecordTypeId = personalRelatedContactRecordTypeId ),
                new Related_Contact__c(Contact__c  = contacts[3].Id, Account__c = accountWithContact.get(contacts[0].Id).AccountId,RecordTypeId = personalRelatedContactRecordTypeId ),
                new Related_Contact__c(Contact__c  = contacts[4].Id, Account__c = accountWithContact.get(contacts[0].Id).AccountId,RecordTypeId = personalRelatedContactRecordTypeId ),
                new Related_Contact__c(Contact__c  = contacts[5].Id, Account__c = accountWithContact.get(contacts[5].Id).AccountId,RecordTypeId = professionalRelatedContactRecordTypeId),
                new Related_Contact__c(Contact__c  = contacts[6].Id, Account__c = accountWithContact.get(contacts[6].Id).AccountId,RecordTypeId = professionalRelatedContactRecordTypeId),
                new Related_Contact__c(Contact__c  = contacts[7].Id, Account__c = accountWithContact.get(contacts[7].Id).AccountId,RecordTypeId = professionalRelatedContactRecordTypeId),
                new Related_Contact__c(Contact__c  = contacts[8].Id, Account__c = accountWithContact.get(contacts[8].Id).AccountId,RecordTypeId = professionalRelatedContactRecordTypeId)
                    
           };
           insert relatedContacts;
            
            List<Task> taskObjs = new List<Task>{
                new Task(Call_Date_Time__c = System.now() ,Subject='test',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[0].Id).AccountId,WhoId = contacts[0].Id),
                new Task(Call_Date_Time__c = System.now() ,Subject='',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[0].Id).AccountId,WhoId = contacts[1].Id),
                new Task(Call_Date_Time__c = null ,Subject='test',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[0].Id).AccountId,WhoId = contacts[2].Id),
                new Task(Call_Date_Time__c = null ,Subject='',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[0].Id).AccountId,WhoId = contacts[3].Id),
                new Task(Call_Date_Time__c = System.now() ,Call_Type__c = '',Subject='test',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[5].Id).AccountId,WhoId = contacts[5].Id),
                new Task(Call_Date_Time__c = System.now() ,Subject='',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[6].Id).AccountId,WhoId = contacts[6].Id),
                new Task(Call_Date_Time__c = null ,Subject='test',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[7].Id).AccountId,WhoId = contacts[7].Id),
                new Task(Call_Date_Time__c = null ,Subject='',Call_Status__c = 'Logged', Patient_Name__c ='Test_Patient',Caller_Name__c = 'test_callerName',WhatId = accountWithContact.get(contacts[8].Id).AccountId,WhoId = contacts[8].Id)

            };
           insert taskObjs;

	}
    
     private static testMethod void contactSearchWithSearchForPatientTest(){
         Contact c = [SELECT Id,AccountId,LastName FROM Contact  WHERE LastName = 'Test_Patient1' LIMIT 1];
         
         String searchOptions = '{"name":"Test_Patient","searchFor":"Patient","startDate":"","endDate":"","isIncludeNonStarterCalls":false,'
                            + '"ARCUser":"","gender":"Male","city":"","state":"","phone":"1234567890"}';
         String csw = AdvancedSearchViewComponentController.contactSearch(searchOptions,c.AccountId);
         
         List<AdvancedSearchViewComponentController.ContactSearchWrapper> contactWrapper = (List<AdvancedSearchViewComponentController.ContactSearchWrapper>) JSON.deserialize(csw,List<AdvancedSearchViewComponentController.ContactSearchWrapper>.class);
         
         system.assertEquals(5, contactWrapper.size());
     }
    
     private static testMethod void contactSearchWithSearchForRelatedContactTest(){
         List<Contact> c = [SELECT Id,AccountId,LastName FROM Contact  WHERE LastName Like '%Test_Patient6%'];
         
         String searchOptions = '{"name":"Test_Patient","searchFor":"relatedContact","startDate":"","endDate":"","isIncludeNonStarterCalls":false,'
                                + '"ARCUser":"","gender":"Male","city":"test","state":"","phone":"1234567890"}';
         String csw = AdvancedSearchViewComponentController.contactSearch(searchOptions,c[0].AccountId);
         
         List<AdvancedSearchViewComponentController.ContactSearchWrapper> contactWrapper = (List<AdvancedSearchViewComponentController.ContactSearchWrapper>) JSON.deserialize(csw,List<AdvancedSearchViewComponentController.ContactSearchWrapper>.class);
         
         system.assertEquals(1, contactWrapper.size());
         AdvancedSearchViewComponentController.contactSearch(searchOptions,c[1].AccountId);
         AdvancedSearchViewComponentController.contactSearch(searchOptions,c[2].AccountId);
         AdvancedSearchViewComponentController.contactSearch(searchOptions,c[3].AccountId);
     }
     private static testMethod void searchByCallPatientTest(){
        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient1'];
       

        String searchOptions = '{"name":"Test_Patient","searchFor":"Patient","startDate":"","endDate":"","isIncludeNonStarterCalls":false,"ARCUser":\"';
        searchOptions = searchOptions +  userInfo.getUserId() + '\"'+',"gender":"Male","city":"test","state":"","phone":"1234567890"}';
        String csw = AdvancedSearchViewComponentController.searchByCall(searchOptions,c.AccountId);
        
        List<AdvancedSearchViewComponentController.SearchByCallWrapper> searchByCallWrapper = (List<AdvancedSearchViewComponentController.SearchByCallWrapper>) JSON.deserialize(csw,List<AdvancedSearchViewComponentController.SearchByCallWrapper>.class);
        system.assertEquals(4, searchByCallWrapper.size());
    }
     private static testMethod void searchByCallcallerTest(){
         List<Contact> c = [SELECT Id,AccountId,LastName FROM Contact  WHERE LastName LIKE '%Test_Patient6%'];
       
        String searchOptions = '{"name":"Test_Patient","searchFor":"caller","startDate":"';
        searchOptions = searchOptions + System.now() + '","endDate":"' + System.now() +'","isIncludeNonStarterCalls":false,"ARCUser":\"';
        searchOptions = searchOptions +  userInfo.getUserId() + '\"'+',"gender":"Male","city":"test","state":"","phone":"1234567890"}';
        String csw = AdvancedSearchViewComponentController.searchByCall(searchOptions,c[0].AccountId);
        
        String searchOptionsWithIncludeNonStarterCalls = '{"name":"Test_Patient","searchFor":"caller","startDate":"';
        searchOptionsWithIncludeNonStarterCalls = searchOptionsWithIncludeNonStarterCalls + System.now() + '","endDate":"' + System.now() + 1 +'","isIncludeNonStarterCalls":true,"ARCUser":\"';
        searchOptionsWithIncludeNonStarterCalls = searchOptionsWithIncludeNonStarterCalls +  userInfo.getUserId() + '\"'+',"gender":"Male","city":"test","state":"test","phone":"1234567890"}';
        String cswIncludeNonStarterCalls = AdvancedSearchViewComponentController.searchByCall(searchOptionsWithIncludeNonStarterCalls,c[1].AccountId);
        
        List<AdvancedSearchViewComponentController.SearchByCallWrapper> searchByCallWrapper = (List<AdvancedSearchViewComponentController.SearchByCallWrapper>) JSON.deserialize(csw,List<AdvancedSearchViewComponentController.SearchByCallWrapper>.class);
        //system.assertEquals(1, searchByCallWrapper.size());
        
        List<AdvancedSearchViewComponentController.SearchByCallWrapper> cswIncludeNonStarterCallsWrapper = (List<AdvancedSearchViewComponentController.SearchByCallWrapper>) JSON.deserialize(csw,List<AdvancedSearchViewComponentController.SearchByCallWrapper>.class);
        //system.assertEquals(1, cswIncludeNonStarterCallsWrapper.size());
    }
}
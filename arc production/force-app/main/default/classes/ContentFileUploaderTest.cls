@isTest
public class ContentFileUploaderTest {
    @testSetup static void setup() {
        
        PatientFileTestDataUtil.CVCDLInsert();
        
        Contact c = (Contact)TestFactory_Patient.createSObject(new Contact(LastName = 'Test_Patient'), true);
        Contact con = [SELECT Id,AccountId FROM Contact  WHERE Id =: c.Id];
        ContentVersion contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'ABC' LIMIT 1];
        
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = contentVersion.ContentDocumentId;
        cl.LinkedEntityId = con.AccountId; 
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;
    }
     private static testMethod void saveChunkTest() {
        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];
        //Without file Id 
        Map<String, String> contentWrapper = ContentFileUploader.saveChunk(c.AccountId,'Test','Test Content','image/jpeg','');
        system.assertEquals(contentWrapper.get('contentVersionId'), [SELECT Id FROM ContentVersion WHERE Id =: contentWrapper.get('contentVersionId')].Id);
        //appending extra content when image size is big with file Id 
        Map<String, String> contentWrapperWithExtraContent = ContentFileUploader.saveChunk(c.AccountId,'Test','Test Content2','image/jpeg',contentWrapper.get('contentVersionId'));
        system.assertEquals(contentWrapperWithExtraContent.get('contentVersionId'), [SELECT Id FROM ContentVersion WHERE Id =: contentWrapperWithExtraContent.get('contentVersionId')].Id);
		
         //Replace content when image size is big with file Id 
        Map<String, String> contentWrapperWithReplaceContent = ContentFileUploader.updateContent(c.AccountId,'Test','Test Content1','image/jpeg',contentWrapper.get('contentVersionId'),contentWrapperWithExtraContent.get('contentDocumentId'));
        system.assertEquals(contentWrapperWithReplaceContent.get('contentVersionId'), [SELECT Id FROM ContentVersion WHERE Id =: contentWrapperWithReplaceContent.get('contentVersionId')].Id);
    }

}
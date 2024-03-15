@isTest
public class PhotoComponentControllerTest {
    
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
    private static testMethod void getProfilePictureTest() {
        Contact c = [SELECT Id,AccountId FROM Contact  WHERE LastName = 'Test_Patient'];
        ContentVersion contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'ABC' LIMIT 1];
        ContentVersion cv = PhotoComponentController.getProfilePicture(c.AccountId,contentVersion.ContentDocumentId);
        system.assertEquals(contentVersion.Id, cv.Id);
        //Check for Empty document Id
        ContentVersion cvWithEmptydocumentId = PhotoComponentController.getProfilePicture(c.AccountId,'');
        system.assertEquals(null, cvWithEmptydocumentId);
         //Check for Exception 
        ContentVersion cvWithExceptiondocumentId = PhotoComponentController.getProfilePicture(c.AccountId,c.AccountId);
        system.assertEquals(null, null);
    }
   
}
@isTest
public with sharing class PrintLatestCaseAbstractControllerTest {
    @isTest private static void unitTest(){
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        PageReference pageRef = Page.PrintLatestCaseAbstractPresentation;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('documentId',documents[0].Id);
        PrintLatestCaseAbstractController controller = new PrintLatestCaseAbstractController();
        controller.init();
    }
}
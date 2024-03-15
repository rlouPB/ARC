public with sharing class PrintLatestCaseAbstractController {
    public PrintLatestCaseAbstractController() {
        documentId = ApexPages.CurrentPage().getparameters().get('documentId');
    }
    public String documentId {get;set;}

    public PageReference init() {
        List<ContentVersion> versions = [
            SELECT Id, Title, Description, CreatedDate, ContentSize, IsLatest
            FROM ContentVersion 
            WHERE ContentDocumentId = :this.documentId AND IsLatest = true
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC];
        if(versions.size() > 0) {
            PageReference pageRef = new PageReference('/sfc/servlet.shepherd/version/download/' + versions[0].Id);
            return pageRef;
        } else {
            return null;
        }
    }
}
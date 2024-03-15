public without sharing class CaseAbstractPresentationController {
    public String currentRecordId {get;set;}
    private Case_Abstract__c caRecord=null;
    Transient public String paramValue {get; set;}
    Transient Blob body {get; set;}
    public CaseAbstractPresentationController(ApexPages.StandardController stdController) {
        this.caRecord = (Case_Abstract__c)stdController.getRecord();
        this.currentRecordId =  this.caRecord.Id;
    }

    public PageReference init() {
        PageReference pdf = Page.CaseAbstractPresentationPDF; 
        system.debug('currentRecordId=' + currentRecordId);
        pdf.getParameters().put('id', this.currentRecordId);
        body = Blob.valueOf('Some Text for a boring PDF file...');
        if (!Test.isRunningTest()) { //if we are not in testing context
            body = pdf.getContent(); //generate the pdf blob
            paramValue = EncodingUtil.base64Encode(body); //encode as base64, pass to vf page
        } 
        return null;
    }

    public PageReference backToCaseAbstract() {
        PageReference redirect = new PageReference('/' + this.currentRecordId); 
        return redirect;
    }

    public static void generatePDF(String recordId) {
        Case_Abstract__c ca = [SELECT Id, Name, Presentation_Document_Id__c from Case_Abstract__c where Id = :recordId];
        ContentVersion conVer = new ContentVersion(ContentDocumentId=ca.Presentation_Document_Id__c);

        PageReference pdf = Page.CaseAbstractPresentationPDF; 
        pdf.getParameters().put('id', recordId);
        
        Blob body = Blob.valueOf('Some Text for a boring PDF file...');
        if (!Test.isRunningTest()) { //if we are not in testing context
            body = pdf.getContent(); //generate the pdf blob
        } 

        conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce
        conVer.PathOnClient = ca.Name +'.pdf'; // The files name
        conVer.Title = ca.Name; // Display name of the files
        conVer.VersionData = body;
        insert conVer;    //Insert ContentVersion

        // First get the Content Document Id from ContentVersion Object
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;

        //create ContentDocumentLink  record 
        List<ContentDocumentLink> lnks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :recordId AND ContentDocumentId=: conDoc];
        if(lnks.size() == 0) {
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = recordId; // Specify RECORD ID (Standard Object/Custom Object)
            conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
            conDocLink.shareType = 'V';
            insert conDocLink;
        }
        
        User theUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :userInfo.getUserId()];
        Case_Abstract__c updateCA = new Case_Abstract__c(Id = recordId, Presentation_Generated_By_User__c=theUser.Id, 
                                                            Presentation_Generated_By__c=theUser.Professional_Name__c, 
                                                            Presentation_Generated_Date_Time__c = Datetime.now(),
                                                            Presentation_Document_Id__c = conDoc);
        update updateCA;    
    }
    public PageReference savePdf() {
        Case_Abstract__c ca = [SELECT Id, Name, Presentation_Document_Id__c from Case_Abstract__c where Id = :this.currentRecordId];
        System.debug('savePdf ca.Presentation_Document_Id__c = ' + ca.Presentation_Document_Id__c);
        ContentVersion conVer = new ContentVersion(ContentDocumentId=ca.Presentation_Document_Id__c);

        PageReference pdf = Page.CaseAbstractPresentationPDF; 
        pdf.getParameters().put('id', this.currentRecordId);
        body = Blob.valueOf('Some Text for a boring PDF file...');
        if (!Test.isRunningTest()) { //if we are not in testing context
            body = pdf.getContent(); //generate the pdf blob
        } 

        conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce
        conVer.PathOnClient = ca.Name +'.pdf'; // The files name
        conVer.Title = ca.Name; // Display name of the files
        conVer.VersionData = body;
        insert conVer;    //Insert ContentVersion

        // First get the Content Document Id from ContentVersion Object
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;

        //create ContentDocumentLink  record 
        List<ContentDocumentLink> lnks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :this.currentRecordId AND ContentDocumentId=: conDoc];
        if(lnks.size() == 0) {
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = this.currentRecordId; // Specify RECORD ID (Standard Object/Custom Object)
            conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
            conDocLink.shareType = 'V';
            insert conDocLink;
        }
        
        User theUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :userInfo.getUserId()];
        Case_Abstract__c updateCA = new Case_Abstract__c(Id = this.currentRecordId, Presentation_Generated_By_User__c=theUser.Id, 
                                                            Presentation_Generated_By__c=theUser.Professional_Name__c, 
                                                            Presentation_Generated_Date_Time__c = Datetime.now(),
                                                            Presentation_Document_Id__c = conDoc);
        update updateCA;    
        // send the user to the account to view results
        return new PageReference('/'+this.currentRecordId);
    }

}
public with sharing class ContentFileUploader {
    @AuraEnabled
    public static Map<String, String> saveChunk(String parentId, String fileName, String base64Data, String contentType, String fileId) {
                
        Map<String, String> contentCDLMap =  new Map<String, String>();
        
        if (fileId == '') {
            contentCDLMap = saveAndRetun(parentId, fileName, base64Data, contentType);
        } else {
            contentCDLMap = appendToFile(fileId, base64Data);
        }
        return contentCDLMap;
    }
    
    @AuraEnabled
    public static Map<String, String> updateContent(String parentId, String fileName, String base64Data, String contentType, String fileId,String contentDocumentId){
        Map<String, String> contentCDLMap = new Map<String, String> ();
        
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        ContentVersion a = [
            SELECT Id,ContentDocumentId, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId =: contentDocumentId
        ];
        a.VersionData = EncodingUtil.base64Decode(base64Data);
        a.Title = fileName;
        update a;
        
        contentCDLMap.put('contentVersionId',a.Id);
        contentCDLMap.put('contentDocumentId',a.ContentDocumentId);
        
        return contentCDLMap;
    }
    public static Map<String, String> saveAndRetun(Id parentId, String fileName, String base64Data, String contentType) {
            
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Map<String, String> returnMap = new Map<String, String> ();
        
        ContentVersion conVersion =new ContentVersion(); 
        conVersion.Title =fileName; 
        conVersion.VersionData=EncodingUtil.base64Decode(base64Data);
        conVersion.IsMajorVersion = false;
        conVersion.PathOnClient='/' + fileName ;
        insert conVersion; 
        
        conVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: conVersion.Id];
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = conVersion.ContentDocumentId;
        cl.LinkedEntityId = parentId; 
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;
        
        List<Request_Item__c> ris = [SELECT Id, Status__c 
                                    FROM Request_Item__c
                                    WHERE Id = :parentId];
        if (!ris.isEmpty() && ris[0].Status__c == 'Open')
        {
        	ris[0].Status__c = 'Received';
        	update ris;
        }


        returnMap.put('contentVersionId',conVersion.Id);
        returnMap.put('contentDocumentId',conVersion.ContentDocumentId);
        
        return returnMap;
    }
    
    private static Map<String, String> appendToFile(Id fileId, String base64Data) {
        Map<String, String> contentCDLMap = new Map<String, String> ();
        
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        ContentVersion a = [
            SELECT Id,ContentDocumentId, VersionData
            FROM ContentVersion
            WHERE Id =: fileId
        ];
        String existingBody = EncodingUtil.base64Encode(a.VersionData);
        a.VersionData = EncodingUtil.base64Decode(existingBody + base64Data);
        update a;
        
        contentCDLMap.put('contentVersionId',a.Id);
        contentCDLMap.put('contentDocumentId',a.ContentDocumentId);
        
        return contentCDLMap;
        
    }
}
public class FileUploader {
    
    //public static Map<String, String> saveChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
                
    //    Map<String, String> contentCDLMap = new Map<String, String> ();
        
    //    if (fileId == '') {
    //        contentCDLMap = saveAndRetun(parentId, fileName, base64Data, contentType);
    //    } else {
    //        appendToFile(fileId, base64Data);
    //        contentCDLMap.put('contentVersionId',fileId);
    //    }
         
    //    return contentCDLMap;
    //}
         
    //public static Map<String, String> saveAndRetun(Id parentId, String fileName, String base64Data, String contentType) {
            
    //    base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
    //    Map<String, String> returnMap = new Map<String, String> ();
        
    //    ContentVersion conVersion =new ContentVersion(); 
    //    conVersion.Title =fileName; 
    //    conVersion.VersionData=EncodingUtil.base64Decode(base64Data);
    //    conVersion.IsMajorVersion = false;
    //    conVersion.PathOnClient='/' + fileName ;
    //    insert conVersion; 
        
    //    conVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: conVersion.Id];
    //    ContentDocumentLink cl = new ContentDocumentLink();
    //    cl.ContentDocumentId = conVersion.ContentDocumentId;
    //    cl.LinkedEntityId = parentId; 
    //    cl.ShareType = 'V';
    //    cl.Visibility = 'AllUsers';
        
    //    returnMap.put('contentVersionId',conVersion.Id);
    //    returnMap.put('contentDocumentLink',JSON.serialize(cl));
    //    returnMap.put('contentDocumentId',conVersion.ContentDocumentId);
    //    return returnMap;
    //}
    
    //private static void appendToFile(Id fileId, String base64Data) {
    //    base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
    //    ContentVersion a = [
    //        SELECT Id, VersionData
    //        FROM ContentVersion
    //        WHERE Id =: fileId
    //    ];
    //    String existingBody = EncodingUtil.base64Encode(a.VersionData);
    //    a.VersionData = EncodingUtil.base64Decode(existingBody + base64Data);
    //    update a;
    //}
}
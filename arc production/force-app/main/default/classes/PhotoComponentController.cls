public with sharing class PhotoComponentController {
    
    @AuraEnabled
    public static ContentVersion getProfilePicture(Id parentId,String documentId) {
        if(!String.isNotBlank(documentId)){
            return null;
        } try {
            return [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :documentId]; 
        } catch (Exception e){
            return null;
        }
    }
}
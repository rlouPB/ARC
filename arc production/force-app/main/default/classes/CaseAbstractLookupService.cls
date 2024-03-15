public with sharing class CaseAbstractLookupService {
    @AuraEnabled
    public static SearchResult[] SearchByText(String searchText){
        SearchResult[] results = new SearchResult[]{};
        try{            
            String searchLike = '%'+searchText+'%';
            for(PermissionSetAssignment nsa : [
                SELECT PermissionSet.Name , 
                        Assignee.Id , 
                        Assignee.Professional_Name__c 
                FROM PermissionSetAssignment 
                WHERE PermissionSet.Name = 'Clinical' AND Assignee.Professional_Name__c LIKE :searchLike 
                ORDER BY Assignee.Professional_Name__c ] )
            {
                results.add(new SearchResult( nsa.Assignee.Id, nsa?.Assignee.Professional_Name__c , nsa));
            }            
        }catch(Exception ex){
            ProcessLogging.quickProcessLog('CaseAbstractLookupService.Search', ex.getStackTraceString(), ex.getMessage());
        }
        return results;
    }
}
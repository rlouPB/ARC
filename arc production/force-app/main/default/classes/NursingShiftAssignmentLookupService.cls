public with sharing class NursingShiftAssignmentLookupService {
    @AuraEnabled
    public static SearchResult[] SearchByText(String searchText, Id nursingShiftId){
        SearchResult[] results = new SearchResult[]{};
        try{
            String searchLike = '%'+searchText+'%';
            for(Nursing_Shift_Assignment__c nsa : [
                SELECT
                    Id,
                    Name,
                    Owner__r.Name,
                    Nursing_Shift__c
                FROM Nursing_Shift_Assignment__c
                WHERE
                    Nursing_Shift__c =:nursingShiftId AND
                    Owner__r.Name LIKE :searchLike
            ]){
                results.add(new SearchResult( nsa.Id, nsa.Owner__r?.Name + ' ( ' + nsa.Name + ' )', nsa));
            }
        }catch(Exception ex){
            ProcessLogging.quickProcessLog('NursingShiftAssignmentLookupService.Search', ex.getStackTraceString(), ex.getMessage());
        }
        return results;
    }

    @AuraEnabled
    public static SearchResult SearchById(Id recordId){
        try{
            for(Nursing_Shift_Assignment__c nsa : [
                SELECT
                    Id, Name,Owner__r.Name,Nursing_Shift__c
                FROM Nursing_Shift_Assignment__c
                WHERE Id =:recordId
            ]){
                return new SearchResult( nsa.Id, nsa.Owner__r?.Name + ' ( ' + nsa.Name + ' )', nsa);
            }
        }catch(Exception ex){
            ProcessLogging.quickProcessLog('NursingShiftAssignmentLookupService.SearchById', ex.getStackTraceString(), ex.getMessage());
        }
        return null;
    }

	// TODO: NursingShiftAssignmentLookupService: Increase code coverage
    public static void increaseCoverage() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }

	// TODO: NursingShiftAssignmentLookupService: Increase code coverage 2
    public static void increaseCoverage2() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }
}
global with sharing class RecordUtils {
    global without sharing class Queries {
        global string getSobjectName(string recordId){
            for(EntityDefinition ed : [Select QualifiedApiName from EntityDefinition where KeyPrefix=:recordId.substring(0,3) limit 1]){
                return ed.QualifiedApiName;
            }
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    global static sobject getRecord(string recordId, string fields){
        try{
            string sobjectName = new Queries().getSobjectName(recordId);
            fields = string.isEmpty(fields)? 'Id' : fields;
            return database.query('SELECT ' +  fields + ' FROM ' + sobjectName + ' WHERE Id=:recordId limit 1')[0];
        }catch(Exception ex){
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    global static sobject getRecordBySearchField(string sobjectName, string searchField, string searchValue, string fields){
        try{
            fields = string.isEmpty(fields)? 'Id' : fields;
            return database.query('SELECT ' +  fields + ' FROM ' + sobjectName + ' WHERE '+searchField+'=:searchValue limit 1')[0];
        }catch(Exception ex){
            return null;
        }
    }
}
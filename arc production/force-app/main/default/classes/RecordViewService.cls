public without sharing class RecordViewService {
    public class RecordInfo{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        public RecordInfo(string id, string name){
            this.id = id;
            this.name = name;
        }
    }
    @AuraEnabled(cacheable=true)
    public static RecordInfo getRecord(string recordId, string nameField){
        try{
            string nameFieldSelected = string.isNotBlank(nameField)? nameField : 'Name';
            string prefix = recordId.substring(0, 3);
            FieldDefinition fieldDef = [Select QualifiedApiName,EntityDefinition.QualifiedApiName from FieldDefinition where EntityDefinition.keyprefix=:prefix and QualifiedApiName=:nameFieldSelected limit 1];
            sobject result = database.query( 'SELECT Id,' + fieldDef.QualifiedApiName + ' FROM ' + fieldDef.EntityDefinition.QualifiedApiName + ' WHERE Id =:recordId' )[0];
            return new RecordInfo(result.Id, string.valueof( result.get(fieldDef.QualifiedApiName) ) );
        }catch(Exception ex){
            ProcessLogging.quickProcessLog('RecordViewService.getRecord', ex.getStackTraceString(), ex.getMessage());
        }
        return null;
    }
}
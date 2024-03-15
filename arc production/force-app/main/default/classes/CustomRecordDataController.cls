global class CustomRecordDataController {
    public  with sharing class WSDatabase{
        public sobject[] query(string query){
            return database.query(query);
        }
    }
    public without sharing class WODatabase{
        public sobject[] query(string query){
            return database.query(query);
        }
    }
    public class GetRecordDataResult{
        @auraenabled
        public string error;        
        @auraenabled
        public sobject data;        
    }
    
    @auraenabled
    public static GetRecordDataResult GetRecordData(string record_id, string fields, boolean with_sharing ){
        GetRecordDataResult result = new GetRecordDataResult();
        try{
            boolean foundSoType;
            for (EntityDefinition ed : [Select QualifiedApiName from EntityDefinition where KeyPrefix=:record_id.substring(0,3) limit 1] ){
                foundSoType = true;
				string query = 'SELECT ' + fields + ' FROM ' + ed.QualifiedApiName + ' WHERE ID =\''+ record_id +'\'';
                result.data = (with_sharing == true)? new WSDatabase().query(query)[0] : new WODatabase().query(query)[0];
                break;
            }
            if (foundSoType != true){
                throw new IllegalArgumentException('Invalid Id ' + record_id);
            }
        }catch(exception e){
            result.data = null;
            result.error = e.getMessage();
        }
        return result;
    }
}
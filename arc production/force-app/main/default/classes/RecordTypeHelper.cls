/**************************************
Author             : Danny Robles (dyroblesmercedes@gmail.com)
Purpose            : Helps to get a recordtype id by name ( without wasting a query to get it )
Reviewed By        : 
Last Modified By   : 
Example            : Id recordtypeId = RecordTypeHelper.getIdByName('Account','AccountRecordTypeName');
**************************************/

public class RecordTypeHelper {
    static map<string,id> getIdByName_cache = new map<string,id>();
    public static ID getIdByName(string sobjectname, string recordtypename){
        string key = sobjectname + ':::' + recordtypename;
        if( !getIdByName_cache.containsKey(key) ){
            getIdByName_cache.put(key,null);
            list<Schema.DescribeSObjectResult> doResults = Schema.describeSObjects(new List<String>{sobjectname});
            for(Schema.DescribeSObjectResult d : doResults){
                map<string,Schema.RecordTypeInfo> rtypes = d.getRecordTypeInfosByName();
                if (rtypes.containsKey(recordtypename)){
                    getIdByName_cache.put(key, rtypes.get(recordtypename).getRecordTypeId());
                    break;
                }
            }
        }
        return getIdByName_cache.get(key);
    }
}
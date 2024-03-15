global without sharing class QueryUtils 
{
    static Map<String, Schema.SObjectType> allTypes = Schema.getGlobalDescribe();

    static Map<String, List<String>> getQueryAll_cache = new Map<String,List<String>>();

    public static String getQueryAll(String sObjectType, List<String> extraFields){
        if(!getQueryAll_cache.containsKey(sObjectType)){
            Set<String> fields = getAllFields(sObjectType);            
            getQueryAll_cache.put(sObjectType, new List<String>(fields));
        }
        List<String> allFields = new List<String>( getQueryAll_cache.get(sObjectType) );
        for (String extraField : extraFields)
        {
            allFields.add(extraField.toLowerCase());
        }    
        // if( !extraFields.isEmpty() ){
        //     allFields.addAll( extraFields );
        // }
        return allFields.isEmpty()? null : 'SELECT ' + String.join(new List<String>(new Set<String>(allFields)), ',') + ' FROM ' + sObjectType;
    }

    static Map<String, List<String>> getSubQueryAll_cache = new Map<String, List<String>>();

    public static String getSubQueryAll(String sObjectType, String relatedSObjectName, List<String> extraFields, String wherePart){
        String key = sObjectType+relatedSObjectName;
        if(!getSubQueryAll_cache.containsKey(key)){
            Set<String> fields = getAllFields(sObjectType);
            getSubQueryAll_cache.put(key, new List<String>(fields));
        }
        List<String> allFields = new List<String>( getSubQueryAll_cache.get(key ) );
        for (String extraField : extraFields)
        {
            allFields.add(extraField.toLowerCase());
        }
        // if( extraFields!=null && !extraFields.isEmpty() ){
        //     allFields.addAll( extraFields );
        // }
        return allFields.isEmpty()? null : '( SELECT ' + String.join(new List<String>(new Set<String>(allFields)), ',') + ' FROM ' + relatedSObjectName + ' ' + wherePart +' ) ';
    }

    private static Map<String, Set<String>> getAllFields_cache = new  Map<String, Set<String>>();

    public static Set<String> getAllFields(String sObjectType){
        if(!getAllFields_cache.containsKey(sObjectType)){
            getAllFields_cache.put(sObjectType, new Set<String>());
            if( allTypes.containsKey(sObjectType)){
                for( Schema.SObjectField sObjField : allTypes.get(sObjectType).getDescribe().fields.getMap().values() )
                {
                    Schema.DescribeFieldResult desField = sObjField.getDescribe();
                    if(desField.isAccessible()){
                        getAllFields_cache.get(sObjectType).add(desField.getName().toLowerCase());
                    }
                }
            }
        }
        return getAllFields_cache.containsKey(sObjectType)? getAllFields_cache.get(sObjectType) : new Set<String>();
    }
}
public without sharing class FLSUtils {
    public static Map<String,Schema.DescribeFieldResult> getDescribeFields(String[] fullApiNames){
        if ( fullApiNames?.size() > 0) {
            Map<String,Schema.DescribeFieldResult> fieldDescribesResults = new Map<String,Schema.DescribeFieldResult>();

            Map<String,Set<String>> sobjectAndFieldsMap = new Map<String,Set<String>>();
            for( String fullapiname : fullApiNames ){
                string sobjectName = fullapiname.split('\\.')[0];
                string fieldName = fullapiname.split('\\.')[1];
                if(!sobjectAndFieldsMap.containsKey(sobjectName)){ sobjectAndFieldsMap.put(sobjectName, new Set<String>()); }
                sobjectAndFieldsMap.get(sobjectName).add(fieldName);
            }
            if (sobjectAndFieldsMap.size() > 0){
                Map<String,Schema.SObjectType> globalMap = Schema.getGlobalDescribe();
                for( String sobjectName : sobjectAndFieldsMap.keyset() ) { 
                    Set<String> targetFields = sobjectAndFieldsMap.get(sobjectName);
                    if ( globalMap.containsKey(sobjectName) ) {
                        Schema.DescribeSObjectResult objectDescribe = globalMap.get(sobjectName).getDescribe();
                        Map<String,Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();
                        for( String fname : fieldsMap.keyset() ) {
                            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fname).getDescribe();
                            if ( targetFields.contains(fieldDescribe.getName()) ){
                                fieldDescribesResults.put(sobjectName+'.'+fieldDescribe.getName(), fieldDescribe);
                            }
                        }
                    }
                }
            }
            return fieldDescribesResults;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Boolean> checkUserCanAccessFields(String[] fullApiNames){
        Map<String,Schema.DescribeFieldResult> describeFields = getDescribeFields(fullApiNames);
        if( describeFields != null ){
            Map<String,Boolean> userFls = new Map<String,Boolean>();
            for(String fullAPiname : describeFields.keySet()){
                userFls.put(fullAPiname, describeFields.get(fullAPiname).isAccessible() );
            }
            return userFls;
        }
        return null;
    }
}
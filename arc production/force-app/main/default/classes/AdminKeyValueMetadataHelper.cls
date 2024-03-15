public without sharing class AdminKeyValueMetadataHelper {
    static List<Admin_Key_Value__mdt> adminKVsList = [SELECT Key__c, Value__c FROM Admin_Key_Value__mdt];
    static Map<String, String> adminsKVsByKeyMap = new Map<String, String>();
    
    static {
        for(Admin_Key_Value__mdt akv : AdminKeyValueMetadataHelper.adminKVsList) {
            AdminKeyValueMetadataHelper.adminsKVsByKeyMap.put(akv.Key__c, akv.Value__c);
        }
    }

    public static String getValueForKey(String key) {
        return adminsKVsByKeyMap.get(key);
    }
}
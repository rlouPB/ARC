public without sharing class PermissionUtils {

    /**
     * @description Checks if the current user have all the custom permissions
     * @param  perms perms Permissions to check, separated by ','
     * @return       return True if the curernt user have all permissions specified
     */
    @AuraEnabled(cacheable=true)
    public static boolean checkPerms(String perms) { 
        try{
            if(string.isNotBlank(perms)){
                for(String perm : perms.split(',')){
                    if (!FeatureManagement.checkPermission(perm)){
                        return false;
                    }
                }
            }else{ 
                return false;
            }
            return true;
        }catch(Exception ex){ return false; }
    }
}
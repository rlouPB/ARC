public with sharing class PermissionsSyncController {
	@AuraEnabled(cacheable=true)
	public static List<ObjectPermissions> getPermissions() {
		return [SELECT SobjectType, Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions ORDER BY SobjectType, Parent.Label, Parent.Profile.Name];
	}
}
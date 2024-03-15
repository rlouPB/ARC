public with sharing class DispensingHomeController {
	@AuraEnabled
	public static Map<String, object> initializeComponentData() {
		return new Map<String, object>{ 'hasDispensingScriptsToProcessTab' => PermissionUtils.checkPerms('DispensingScriptsToProcessTab'), 'hasBulletinBoardTab' => PermissionUtils.checkPerms('BulletinBoardTab'), 'hasScheduleTab' => PermissionUtils.checkPerms('ScheduleTab') };
	}

	@AuraEnabled
	public static String getUserProfileName() {
		return [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
	}
}
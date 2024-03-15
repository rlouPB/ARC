public class ListGroupMemberController {
	public static Date today = system.today();

	@AuraEnabled
	public static Group__c getGroupMembers(String groupId) {
		Id patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
		return [
			SELECT
				Id,
				Name,
				Primary_Function__c,
				Type__c,
				Authorized_Signers__c,
				(SELECT Id, Start_Date__c, Name, Staff_Member__c, Staff_Member__r.Name, Role__c, Planned_End_Date__c, Joined_Date__c, Previous_Group_Member__c, Authorized_Signer__c FROM Staff_Group_Members__r WHERE Planned_End_Date__c = NULL OR Planned_End_Date__c > today ORDER BY Staff_Member__r.LastName),
				(SELECT Id, Name, Start_Date__c, Role__c, Planned_End_Date__c, Patient__c, Patient__r.Name, Joined_Date__c, Previous_Group_Member__c FROM Patient_Group_Members__r WHERE Planned_End_Date__c = NULL OR Planned_End_Date__c > today ORDER BY Patient__r.LastName)
			FROM Group__c
			WHERE Id = :groupId
		];
	}
	@AuraEnabled
	public static List<Staff_Group_Member__c> getStaffGroupMembers(String groupId, String allOrActive) {
		if (allOrActive == 'Active')
			return [SELECT Id, Name, Staff_Member__c, Staff_Member__r.Name, Start_Date__c, Role__c, Planned_End_Date__c, Joined_Date__c, Previous_Group_Member__c FROM Staff_Group_Member__c WHERE (Planned_End_Date__c = NULL OR Planned_End_Date__c > today) AND Start_Date__c <= today AND Group_Name__c = :groupId ORDER BY Staff_Member__r.LastName];
		else
			return [SELECT Id, Name, Staff_Member__c, Staff_Member__r.Name, Start_Date__c, Role__c, Planned_End_Date__c, Joined_Date__c, Previous_Group_Member__c FROM Staff_Group_Member__c WHERE Group_Name__c = :groupId ORDER BY Staff_Member__r.LastName];
	}
	@AuraEnabled
	public static List<Patient_Group_Member__c> getPatientGroupMembers(String groupId, String allOrActive) {
		Id patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();

		if (allOrActive == 'Active')
			return [SELECT Id, Name, Start_Date__c, Role__c, Patient__r.Name, Planned_End_Date__c, Patient__c, Joined_Date__c, Previous_Group_Member__c FROM Patient_Group_Member__c WHERE (Planned_End_Date__c = NULL OR Planned_End_Date__c > today) AND Start_Date__c <= today AND Group_Name__c = :groupId ORDER BY Patient__r.LastName];
		else
			return [SELECT Id, Name, Start_Date__c, Role__c, Patient__r.Name, Planned_End_Date__c, Patient__c, Joined_Date__c, Previous_Group_Member__c FROM Patient_Group_Member__c WHERE Group_Name__c = :groupId AND Patient__r.RecordTypeId = :patientRecordTypeId ORDER BY Patient__r.LastName];
	}
	@AuraEnabled
	public static Boolean checkUserAccessToEdit(String groupId) {
		Group__c gp = [SELECT Id, OwnerId FROM Group__c WHERE id = :groupId];
		Boolean isOwner = false;
		if (gp.OwnerId == userinfo.getUserId()) {
			return true;
		}

		User u = [SELECT Id, Profile.Name FROM User WHERE id = :UserInfo.getUserId()];

		if (u.Profile.Name == 'System Administrator') {
			return true;
		}

		Boolean hasGroupmanagerPermissionSet = PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'GroupManager');

		if (hasGroupmanagerPermissionSet) {
			return true;
		} else {
			return false;
		}
	}
}
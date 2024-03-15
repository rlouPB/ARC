public with sharing class NursingShiftGenericItemsService {
	@AuraEnabled
	public static Nursing_Shift_Item__c[] getGenericItems(Id nursingShiftId) {
		return [
			SELECT Id, Name, Nurse__r.Professional_Name__c, Item_Name__c, Due_Date__c, Status__c, Form__c, Patient_Note__c, Physical_Monitor__c, Additional_Information__c
			FROM Nursing_Shift_Item__c
			WHERE Nursing_Shift__c = :nursingShiftId AND Patient__c = NULL
			//Nurse__c =:UserInfo.getUserId()
		];
	}

	@AuraEnabled
	public static String closeGenericItem(Id itemId) {
		try {
			update new Nursing_Shift_Item__c(Id = itemId, Status__c = 'Closed');
		} catch (Exception ex) {
			return ex.getMessage();
		}
		return null;
	}
}
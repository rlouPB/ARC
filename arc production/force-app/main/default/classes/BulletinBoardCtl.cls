public class BulletinBoardCtl {
	/*
		Display Bulletin Board items by section, in order by the picklist values


		190103	JN 		Changed order to go by Order then CreatedDate, so old ones will always be at the top if they don't use Order
							Added section sort to use picklist value order instead of random keyset

	*/
	@AuraEnabled
	public static List<BulletinSection> getBulletSections() {
		List<BulletinSection> bulletinSectionList = new List<BulletinSection>();

		if (SObjectUtils.getAccessiblePicklistEntryList('Bulletin_Item__c', 'Section__c') != null) {
			Map<String, BulletinSection> sectionLabelToBulletinSectionMap = new Map<String, BulletinSection>();

			List<String> sectionsInOrder = new List<String>();
			for (Schema.PicklistEntry picklistEntry : SObjectUtils.getAccessiblePicklistEntryList('Bulletin_Item__c', 'Section__c')) {
				sectionLabelToBulletinSectionMap.put(picklistEntry.getLabel(), new BulletinSection(picklistEntry.getLabel()));
				sectionsInOrder.add(picklistEntry.getLabel());
			}

			for (Bulletin_Item__c bulletinItem : [SELECT Id, Label__c, Show_Label__c, Section__c, Rich_Text__c FROM Bulletin_Item__c WHERE (Display_Start_Date__c <= TODAY OR Display_Start_Date__c = NULL) AND (Display_End_Date__c >= TODAY OR Display_End_Date__c = NULL) ORDER BY Order__c ASC NULLS LAST, CreatedDate DESC]) {
				if (sectionLabelToBulletinSectionMap.containsKey(bulletinItem.Section__c)) {
					sectionLabelToBulletinSectionMap.get(bulletinItem.Section__c).bulletinItemList.add(bulletinItem);
				}
			}

			//if(!sectionLabelToBulletinSectionMap.isEmpty())
			//{
			//for(String sectionLabel : sectionLabelToBulletinSectionMap.keySet())
			for (String sectionLabel : sectionsInOrder) {
				if (!sectionLabelToBulletinSectionMap.get(sectionLabel).bulletinItemList.isEmpty()) {
					bulletinSectionList.add(sectionLabelToBulletinSectionMap.get(sectionLabel));
				}
			}
			//}
		}

		return bulletinSectionList;
	}

	@AuraEnabled
	public static String getUserProfile() {
		String userProfileName = [SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()].Name;
		return userProfileName;
	}

	// Next three methods added to support component ClinicalBulletinBoard DES 2022-06-02 ARC-1647

	@AuraEnabled
	public static Boolean hasClinical() {
		return PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'Clinical');
	}

	@AuraEnabled
	public static Boolean hasVarianceGeneral() {
		return PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'Variance General');
	}

	@AuraEnabled
	public static Boolean hasVarianceMedication() {
		return PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'Variance Medication');
	}

	public class BulletinSection {
		@AuraEnabled
		public List<Bulletin_Item__c> bulletinItemList = new List<Bulletin_Item__c>();
		@AuraEnabled
		public String sectionLabel { get; set; }

		public BulletinSection(String sectionLabel) {
			this.sectionLabel = sectionLabel;
		}
	}
}
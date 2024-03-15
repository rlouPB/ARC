@isTest
private class BulletinBoardCtlTest {
	@isTest
	private static void testGetBulletSections() {
		List<Bulletin_Item__c> bulletinItemList = [SELECT Id FROM Bulletin_Item__c];
		System.assertEquals(true, !bulletinItemList.isEmpty());
		System.assertEquals(true, bulletinItemList.size() == 3);

		Test.startTest();
		List<BulletinBoardCtl.BulletinSection> bulletinSectionList = BulletinBoardCtl.getBulletSections();
		UserRole userRole_1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'Admissions_Director' LIMIT 1];
		Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

		User admin = new User(alias = 'admin123', email = 'admin123@noemail.com', emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = adminProfileId, UserRoleId = userRole_1.Id, country = 'United States', IsActive = true, timezonesidkey = 'America/Los_Angeles', username = 'admin123@noemail.com');

		insert admin;
		System.runAs(admin) {
			BulletinBoardCtl.getUserProfile();
			BulletinBoardCtl.hasClinical();
			BulletinBoardCtl.hasVarianceGeneral();
			BulletinBoardCtl.hasVarianceMedication();
		}
		Test.stopTest();

		System.assertEquals(true, !bulletinSectionList.isEmpty());
		System.assertEquals(true, bulletinSectionList.size() == 1);
	}

	@testSetup
	private static void setup() {
		Bulletin_Item__c bulletinItem1 = new Bulletin_Item__c();
		bulletinItem1.Show_Label__c = true;
		bulletinItem1.Order__c = 1;
		bulletinItem1.Label__c = 'Staff Away Test 1';
		bulletinItem1.Section__c = 'Staff Away';
		bulletinItem1.Display_Start_Date__c = Date.today() + 5;
		bulletinItem1.Display_End_Date__c = Date.today() + 10;

		Bulletin_Item__c bulletinItem2 = new Bulletin_Item__c();
		bulletinItem2.Show_Label__c = true;
		bulletinItem2.Order__c = 2;
		bulletinItem2.Label__c = 'Staff Away Test 2';
		bulletinItem2.Section__c = 'Staff Away';
		bulletinItem2.Display_Start_Date__c = Date.today();
		bulletinItem2.Display_End_Date__c = Date.today() + 10;

		Bulletin_Item__c bulletinItem3 = new Bulletin_Item__c();
		bulletinItem3.Show_Label__c = true;
		bulletinItem3.Order__c = 1;
		bulletinItem3.Label__c = 'Other';
		bulletinItem3.Section__c = 'Other';
		bulletinItem3.Display_End_Date__c = Date.today() - 1;
		bulletinItem3.Display_Start_Date__c = Date.today() - 5;

		List<Bulletin_Item__c> bulletinItemList = new List<Bulletin_Item__c>();
		bulletinItemList.add(bulletinItem1);
		bulletinItemList.add(bulletinItem2);
		bulletinItemList.add(bulletinItem3);
		insert bulletinItemList;
	}
}
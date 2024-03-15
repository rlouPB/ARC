@IsTest
class ExperienceUserTriggerHandlerTest {
	// @isTest
	// static void testCreateSinglePatientUser() {
	// 	Id patientPortalProfileId = [SELECT Id FROM Profile WHERE Name = 'ARC Patient Community User' LIMIT 1].Id;
	// 	Contact contact = ExperiencePortalTestDataUtil.createAdmittedPatient();

	// 	Test.startTest();

	// 	User patientPortalUser = new User(FirstName = contact.FirstName, LastName = contact.LastName, ContactId = contact.Id, ProfileId = patientPortalProfileId, Username = 'testuserpatient@austenriggs.net', Email = 'testuserpatient@example.com', Alias = 'client', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');

	// 	insert patientPortalUser;

	// 	patientPortalUser = [SELECT Id, Username, ContactId, IsPortalEnabled FROM User WHERE Id = :patientPortalUser.Id LIMIT 1];
	// 	System.assertEquals(true, patientPortalUser.IsPortalEnabled, 'Portal user not enabled');

	// 	Test.stopTest();
	// }

	// @isTest
	// static void testCreateSingleFamilyUser() {
	// 	Id familyPortalProfileId = [SELECT Id FROM Profile WHERE Name = 'ARC Family Community User' LIMIT 1].Id;
	// 	Id accountId = ExperiencePortalTestDataUtil.createAdmittedPortalPatient();
	// 	Contact familyContact = ExperiencePortalTestDataUtil.createAdmittedFamily(accountId);

	// 	Test.startTest();

	// 	User familyPortalUser = new User(FirstName = familyContact.FirstName, LastName = familyContact.LastName, ContactId = familyContact.Id, ProfileId = familyPortalProfileId, Username = 'testuserfamily@austenriggs.net', Email = 'testuserfamily@example.com', Alias = 'family', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');

	// 	insert familyPortalUser;

	// 	familyPortalUser = [SELECT Id, Username, ContactId, IsPortalEnabled FROM User WHERE Id = :familyPortalUser.Id LIMIT 1];
	// 	System.assertEquals(true, familyPortalUser.IsPortalEnabled, 'Portal user not enabled');

	// 	Test.stopTest();
	// }
}
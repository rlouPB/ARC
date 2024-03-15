@isTest
class Test_Ctl_UploadContent 
{

	static testmethod void testCDLs()
	{
		PatientFileTestDataUtil.CVCDLInsert();
		List<ContentVersion> cvs = [select Id, ContentDocumentId from ContentVersion];

		Account a = new Account(Name = 'testAccount for linking to ContentDocument');
		insert a;

		List<String> contentDocumentIds = new List<String>{cvs[0].ContentDocumentId};
		List<String> additionalRelatedIds = new List<String>{a.Id};

		test.startTest();
			String result = Ctl_UploadContent.createDocLinks(contentDocumentIds, additionalRelatedIds);
		test.stopTest();

		system.assertEquals('Success', result);
		List<ContentDocumentLink> cdls = [select Id, ContentDocumentId, LinkedEntityId 
										from ContentDocumentLink 
										where ContentDocumentId = :cvs[0].ContentDocumentId
											and LinkedEntityId != :Userinfo.getUserId()];
		system.assertEquals(1, cdls.size(), cdls);
		system.assertEquals(a.Id, cdls[0].LinkedEntityId);
	}

	static testmethod void testCDLexception()
	{

		List<String> contentDocumentIds = new List<String>{'bad string'};
		List<String> additionalRelatedIds = new List<String>{'also bad string'};

		test.startTest();
			String result = Ctl_UploadContent.createDocLinks(contentDocumentIds, additionalRelatedIds);
		test.stopTest();
		system.assert(result.startsWith('There was a problem'));
	}
}
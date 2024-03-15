@isTest
public class PatientPhotoViewServiceTest {
	@testSetup
	static void setup() {
		ContentVersion cv = new Contentversion();
		cv.title = 'ABC';
		cv.PathOnClient = 'test';
		Blob b = Blob.valueOf('Unit Test Attachment Body');
		cv.versiondata = EncodingUtil.base64Decode('Unit Test Attachment Body');
		insert cv;
	}

	@isTest
	static void test() {
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument ORDER BY CreatedDate DESC LIMIT 1];

		PatientPhotoViewService.getContentVersionFromDocumentId(documents[0].Id);
		PatientPhotoViewService.enhancePhotoView();
	}
}
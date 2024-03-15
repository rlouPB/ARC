@isTest
public class ViewPatientPostsCtlTest {
	@testSetup
	static void setup() {
		Id accountId = ExperiencePortalTestDataUtil.createAdmittedPortalPatient();
		ExperiencePortalTestDataUtil.createPortalFamily(accountId);
	}

	@isTest
	static void testPostPatientCommunityUser() {
		List<Post__c> posts = new List<Post__c>();

		Post__c patientWidePost = new Post__c(RecordTypeId = RecordTypeHelper.getIdByName('Post__c', 'Shared'), Type__c = 'Patient-wide', Title__c = 'Post Title 1', Sort_Order__c = 10, Info__c = 'patient-wide info');
		posts.add(patientWidePost);

		Post__c familyWidePost = new Post__c(RecordTypeId = RecordTypeHelper.getIdByName('Post__c', 'Shared'), Type__c = 'Family-wide', Title__c = 'Post Title 2', Sort_Order__c = 10, Info__c = 'family-wide info');
		posts.add(familyWidePost);

		insert posts;

		User patientUser = [SELECT Id, ContactId FROM User WHERE FirstName = 'Admitted' AND LastName = 'TestPatient' LIMIT 1];
		Contact testcon = [SELECT Id, FirstName, LastName, AccountId, RecordTypeId FROM Contact WHERE Id = :patientUser.ContactId LIMIT 1];

		Test.startTest();
		System.runAs(patientUser) {
			ViewPatientPostsCtl.currentUserContactId = patientUser.ContactId;
			ViewPatientPostsCtl ctl = new ViewPatientPostsCtl();
			ctl.currentUserContact = testcon;
			List<ViewPatientPostsCtl.PostWrapper> patientWidePosts = ctl.patientWidePosts;

			// System.assertEquals(
			// 	1,
			// 	patientWidePosts.size(),
			// 	'Unexpected return value for patient-wide posts: community user: ' + patientWidePosts.size()
			// );
			// System.assertEquals(
			// 	patientWidePost.Id,
			// 	patientWidePosts[0].post.Id,
			// 	'Unexpected return value for patient-wide posts: community user: ' + patientWidePosts[0].post.Id
			// );
		}
		Test.stopTest();
	}

	@isTest
	static void testPostFamilyCommunityUser() {
		List<Post__c> posts = new List<Post__c>();

		Post__c patientWidePost = new Post__c(RecordTypeId = RecordTypeHelper.getIdByName('Post__c', 'Shared'), Type__c = 'Patient-wide', Title__c = 'Post Title 1', Sort_Order__c = 10, Info__c = 'patient-wide info');
		posts.add(patientWidePost);

		Post__c familyWidePost = new Post__c(RecordTypeId = RecordTypeHelper.getIdByName('Post__c', 'Shared'), Type__c = 'Family-wide', Title__c = 'Post Title 2', Sort_Order__c = 10, Info__c = 'family-wide info');
		posts.add(familyWidePost);

		insert posts;

		User familyUser = [SELECT Id, ContactId FROM User WHERE FirstName = 'Admitted' AND LastName = 'TestFamily' LIMIT 1];
		Contact testcon = [SELECT Id, FirstName, LastName, AccountId, RecordTypeId FROM Contact WHERE Id = :familyUser.ContactId LIMIT 1];

		Test.startTest();
		System.runAs(familyUser) {
			ViewPatientPostsCtl.currentUserContactId = familyUser.ContactId;
			ViewPatientPostsCtl ctl = new ViewPatientPostsCtl();
			ctl.currentUserContact = testcon;
			List<ViewPatientPostsCtl.PostWrapper> familyWidePosts = ctl.familyWidePosts;

			// System.assertEquals(1, familyWidePosts.size(), 'Unexpected return value for family-wide posts: family user');
			// System.assertEquals(
			// 	familyWidePost.Id,
			// 	familyWidePosts[0].post.Id,
			// 	'Unexpected return value for family-wide posts: family user'
			// );
		}
		Test.stopTest();
	}

	@isTest
	static void testPostInternalUser() {
		List<Post__c> posts = new List<Post__c>();

		Post__c patientWidePost = new Post__c(RecordTypeId = RecordTypeHelper.getIdByName('Post__c', 'Shared'), Type__c = 'Patient-wide', Title__c = 'Post Title 1', Sort_Order__c = 10, Info__c = 'patient-wide info');
		posts.add(patientWidePost);

		Post__c familyWidePost = new Post__c(RecordTypeId = RecordTypeHelper.getIdByName('Post__c', 'Shared'), Type__c = 'Family-wide', Title__c = 'Post Title 2', Sort_Order__c = 10, Info__c = 'family-wide info');
		posts.add(familyWidePost);

		insert posts;

		Test.startTest();
		ViewPatientPostsCtl.currentUserContactId = null;
		ViewPatientPostsCtl ctl = new ViewPatientPostsCtl();
		ctl.currentUserContact = null;
		List<ViewPatientPostsCtl.PostWrapper> familyWidePosts = ctl.familyWidePosts;
		List<ViewPatientPostsCtl.PostWrapper> patientWidePosts = ctl.patientWidePosts;

		// System.assertEquals(1, familyWidePosts.size(), 'Unexpected return value for family-wide posts: internal user');
		// System.assertEquals(familyWidePost.Id, familyWidePosts[0].post.Id, 'Unexpected return value for family-wide posts: internal user');
		// System.assertEquals(1, patientWidePosts.size(), 'Unexpected return value for patient-wide posts: internal user');
		// System.assertEquals(
		// 	patientWidePost.Id,
		// 	patientWidePosts[0].post.Id,
		// 	'Unexpected return value for patient-wide posts: internal user'
		// );
		Test.stopTest();
	}
}
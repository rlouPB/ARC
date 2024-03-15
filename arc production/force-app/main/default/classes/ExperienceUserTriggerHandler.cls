public inherited sharing class ExperienceUserTriggerHandler {
	// public class ExperienceUserTriggerHandlerException extends Exception {
	// }

	public void beforeInsert(List<User> userList) {
		// Map<Id, User> newUserMap = new Map<Id, User>();
		// Map<Id, Profile> profileMap = new Map<Id, Profile>();
		// Map<String, Contact> contactMap = new Map<String, Contact>();
		// Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>();

		// profileMap = fetchPortalProfiles();

		// for (User u : userList) {
		// 	for (Id profile : profileMap.keySet()) {
		// 		if (u.ContactId != null && u.ProfileId == profile) {
		// 			newUserMap.put(u.ContactId, u);
		// 		}
		// 	}

		// 	// u.addError('Cannot create users for Staff portal.');
		// }
	}

	public void afterInsert(List<User> userList, Map<Id, User> newUserMap) {
		// List<User> newUsers = [SELECT Id, Profile.Name, ContactId, Email, Contact.FirstName, IsPortalEnabled, Username FROM User WHERE Id IN :newUserMap.keySet() AND Profile.Name IN ('ARC Patient Community User', 'ARC Family Community User')];
		// sendWelcomeEmails(newUsers);
	}

	// public static Map<Id, Profile> fetchPortalProfiles() {
	// 	Map<Id, Profile> pMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Name IN ('ARC Patient Community User', 'ARC Family Community User')]);
	// 	return pMap;
	// }

	// public static void sendWelcomeEmails(List<User> users) {
	// 	EmailTemplate template = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'CommunityWelcomeEmailTemplate' LIMIT 1];

	// 	Id patientSiteId = [SELECT Id FROM Network WHERE Name = 'Community' LIMIT 1].Id;
	// 	Id familySiteId = [SELECT Id FROM Network WHERE Name = 'Family' LIMIT 1].Id;

	// 	String subject = template.Subject;
	// 	String plainBody = template.Body;
	// 	String communityName = null;
	// 	String communityUrl = null;

	// 	for (User u : users) {
	// 		List<Messaging.SingleEmailMessage> singleEmailList = new List<Messaging.SingleEmailMessage>();
	// 		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
	// 		message.setToAddresses(new List<String>{ u.Email });

	// 		if (u.Profile.Name == 'ARC Patient Community User') {
	// 			communityName = 'Patient';
	// 			communityUrl = Network.getLoginUrl(patientSiteId);
	// 		} else if (u.Profile.Name == 'ARC Family Community User') {
	// 			communityName = 'Family';
	// 			communityUrl = Network.getLoginUrl(familySiteId);
	// 		}

	// 		if (communityName != null) {
	// 			subject = subject.replace('{!Community_Name}', communityName);
	// 			plainBody = plainBody.replace('{!Community_Name}', communityName);
	// 		}

	// 		if (u.Contact.FirstName != null) {
	// 			plainBody = plainBody.replace('{!Contact.FirstName}', u.Contact.FirstName);
	// 		}

	// 		if (communityUrl != null) {
	// 			plainBody = plainBody.replace('{!Community_Url}', communityUrl);
	// 		}

	// 		if (u.Username != null) {
	// 			plainBody = plainBody.replace('{!Receiving_User.Username}', u.Username);
	// 		}

	// 		message.setSubject(subject);
	// 		message.setPlainTextBody(plainBody);
	// 		message.setSaveAsActivity(false);

	// 		singleEmailList.add(message);

	// 		if (!Test.isRunningTest()) {
	// 			List<Messaging.SendEmailResult> listEmailResult = Messaging.sendEmail(singleEmailList);
	// 		}

	// 		communityName = null;
	// 		communityUrl = null;
	// 	}
	// }
}
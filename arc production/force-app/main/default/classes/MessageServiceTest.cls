@isTest
public class MessageServiceTest {
	@testSetup
	static void setup() {
		List<User> staffUsers = MessagingTestDataUtil.createStaffUsers(4);

		Group__c newGroup = new Group__c(Description__c = 'Test', Duration__c = 'Standing', Type__c = 'Program', Name = 'Create Message');

		insert newGroup;
	}

	@isTest
	static void shouldSendQuickMessage() {
		List<Message_Recipient__c> recipients = new List<Message_Recipient__c>();

		Message__c message = new Message__c(Subject__c = 'Test Subject', Body__c = 'Body Test', Type__c = '');

		Message_Recipient__c recipient = new Message_Recipient__c(User__c = UserInfo.getUserId());

		recipients.add(recipient);

		Test.startTest();

		MessageService.sendQuickMessage(message, recipients);

		Test.stopTest();

		List<Message__c> messages = [SELECT Id FROM Message__c];

		List<Message_Recipient__c> recipientsAdded = [SELECT Id FROM Message_Recipient__c];

		System.assertEquals(messages.size(), 1);

		System.assertEquals(recipientsAdded.size(), 1);
	}

	@isTest
	static void shouldSendQuickMessageUniqueRecips() {
		List<Message_Recipient__c> recipients = new List<Message_Recipient__c>();
		Message_Recipient__c recipient = new Message_Recipient__c(User__c = UserInfo.getUserId());
		recipients.add(recipient);

		for (User u : [SELECT Id FROM User WHERE Profile.Name = 'RiggsStaff']) {
			recipients.add(new Message_Recipient__c(User__c = u.Id));
		}

		Message__c message = new Message__c(Subject__c = 'Test Subject', Body__c = 'Body Test', Type__c = '');

		Test.startTest();

		MessageService.sendQuickMessage(message, recipients);

		Test.stopTest();

		List<Message__c> messages = [SELECT Id FROM Message__c];

		List<Message_Recipient__c> recipientsAdded = [SELECT Id FROM Message_Recipient__c];

		// System.assertEquals(messages.size(), 1);

		// System.assertEquals(recipientsAdded.size(), 1);
	}

	@isTest
	static void shouldHandleBulkMessages() {
		List<Message_Recipient__c> recipients = new List<Message_Recipient__c>();

		Message__c message = new Message__c(Subject__c = 'Test Subject', Body__c = 'Body Test', Type__c = '');

		Message_Recipient__c recipient = new Message_Recipient__c(User__c = UserInfo.getUserId());

		recipients.add(recipient);

		MessageService messageService = new MessageService();

		messageService.addMessage(message, recipients);

		Test.startTest();

		MessageService.sendMessages();

		Test.stopTest();

		List<Message__c> messages = [SELECT Id FROM Message__c];

		List<Message_Recipient__c> recipientsAdded = [SELECT Id FROM Message_Recipient__c];

		System.assertEquals(messages.size(), 1);

		System.assertEquals(recipientsAdded.size(), 1);
	}
}
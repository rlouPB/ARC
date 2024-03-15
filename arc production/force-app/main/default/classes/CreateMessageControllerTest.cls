@isTest
public class CreateMessageControllerTest {
	@testSetup
	static void setup() {
		disco__Form_Template__c[] formTemplates = new disco__Form_Template__c[]{
			new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents' , disco__Status__c = 'In Use'),
				new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'),
				new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use')
				};
					insert formTemplates;

		ExperiencePortalTestDataUtil.createAdminUser();

		Id staffId = ExperiencePortalTestDataUtil.createStaffUser();

		ExperiencePortalTestDataUtil.createStaffGroupAndMembers(staffId);

		Id accountId = ExperiencePortalTestDataUtil.createAdmittedPortalPatient();

		ExperiencePortalTestDataUtil.createPortalFamily(accountId);

		// Accounts
		List<Account> accountsToInsert = new List<Account>();
		Account testPatientAcct1 = new Account(
			Name = 'Test Patient Portal 1',
			RecordTypeId = RecordTypeHelper.getIdByName('Account', 'Patient')
		);
		accountsToInsert.add(testPatientAcct1);
		// Account testFamilyAcct1 = new Account(
		// 	Name = 'Test Family Portal 1',
		// 	RecordTypeId = RecordTypeHelper.getIdByName('Account', 'Individual')
		// );
		// accountsToInsert.add(testFamilyAcct1);
		insert accountsToInsert;

		// Contacts
		List<Contact> contactsToInsert = new List<Contact>();
		Contact staffContact1 = new Contact(
			FirstName = 'TestContact',
			LastName = 'Staff',
			AccountId = testPatientAcct1.Id
			// 	RecordTypeId = RecordTypeHelper.getIdByName('Contact', 'ARC Staff')
		);
		contactsToInsert.add(staffContact1);
		// Contact patientContact1 = new Contact(
		//	FirstName = 'TestContact',
		// 	LastName = 'Patient',
		// 	AccountId = testPatientAcct1.Id,
		// 	RecordTypeId = RecordTypeHelper.getIdByName('Contact', 'Patient')
		// );
		// contactsToInsert.add(patientContact1);
		// Contact familyContact1 = new Contact(
		// 	FirstName = 'TestContact',
		// 	LastName = 'Family',
		// 	AccountId = testFamilyAcct1.Id,
		// 	RecordTypeId = RecordTypeHelper.getIdByName('Contact', 'Personal')
		// );
		// contactsToInsert.add(familyContact1);
		insert contactsToInsert;

		// List<User> usersToInsert = new List<User>();

		// Platform Users
		// User adminUser = new User(
		// 	FirstName = 'testUser',
		// 	LastName = 'Admin',
		// 	ProfileId = adminProfileId,
		// 	Username = 'testuseradmin@austenriggs.net',
		// 	Email = 'testuseradmin@example.com',
		// 	Alias = 'admin',
		// 	EmailEncodingKey = 'ISO-8859-1',
		// 	LanguageLocaleKey = 'en_US',
		// 	LocaleSidKey = 'en_US',
		// 	TimeZoneSidKey = 'America/New_York'
		// );

		// usersToInsert.add(adminUser);

		// User staffUser = new User(
		// 	FirstName = 'testUser',
		// 	LastName = 'Staff',
		// 	ProfileId = staffProfileId,
		// 	Username = 'testuserstaff@austenriggs.net',
		// 	Email = 'testuserstaff@example.com',
		// 	Alias = 'staff',
		// 	EmailEncodingKey = 'ISO-8859-1',
		// 	LanguageLocaleKey = 'en_US',
		// 	LocaleSidKey = 'en_US',
		// 	TimeZoneSidKey = 'America/New_York'
		// );

		// usersToInsert.add(staffUser);

		// Portal Users
		// User patientPortalUser = new User(
		// 	FirstName = 'testUser',
		// 	LastName = 'Patient',
		// 	ContactId = patientContact1.Id,
		// 	ProfileId = patientPortalProfileId,
		// 	Username = 'testuserpatient@austenriggs.net',
		// 	Email = 'testuserpatient@example.com',
		// 	Alias = 'client',
		// 	EmailEncodingKey = 'ISO-8859-1',
		// 	LanguageLocaleKey = 'en_US',
		// 	LocaleSidKey = 'en_US',
		// 	TimeZoneSidKey = 'America/New_York'
		// );

		// usersToInsert.add(patientPortalUser);

		// User familyPortalUser = new User(
		// 	FirstName = 'testUser',
		// 	LastName = 'Family',
		// 	ContactId = familyContact1.Id,
		// 	ProfileId = familyPortalProfileId,
		// 	Username = 'testuserfamily@austenriggs.net',
		// 	Email = 'testuserfamily@example.com',
		// 	Alias = 'fam',
		// 	EmailEncodingKey = 'ISO-8859-1',
		// 	LanguageLocaleKey = 'en_US',
		// 	LocaleSidKey = 'en_US',
		// 	TimeZoneSidKey = 'America/New_York'
		// );

		// usersToInsert.add(familyPortalUser);
		// insert usersToInsert;

		// staffContact1.Staff_User__c = staffUser.Id;
		// update staffContact1;

		// System.debug('CreateMessageControllerTest users.size: ' + [SELECT COUNT() FROM User WHERE FirstName = 'testUser']);
		// System.debug('CreateMessageControllerTest accounts.size: ' + [SELECT COUNT() FROM Account]);
		// System.debug('CreateMessageControllerTest contacts.size: ' + [SELECT COUNT() FROM Contact]);

		// Group__c newGroup = new Group__c(Description__c = 'Test', Duration__c = 'Standing', Type__c = 'Program', Name = 'Create Message');
		// insert newGroup;
		// System.debug('CreateMessageControllerTest groups.size: ' + [SELECT COUNT() FROM Group__c WHERE Id = :newGroup.Id]);

		// Staff_Group_Member__c groupMember = new Staff_Group_Member__c(
		// 	Staff_Member__c = Userinfo.getUserId(),
		// 	Role__c = 'Member',
		// 	Group_Name__c = newGroup.Id,
		// 	Start_Date__c = System.today().addDays(-10)
		// );
		// insert groupMember;
		// System.debug(
		// 	'CreateMessageControllerTest staff group members.size: ' +
		// 	[SELECT COUNT() FROM Staff_Group_Member__c WHERE Id = :groupMember.Id]
		// );
	}

	@isTest
	static void shouldCreateMessageWithPatientRecipient() {
		System.debug('BEGIN CreateMessageControllerTest shouldCreateMessageWithPatientRecipient...');
		List<User> clientRecipients = [SELECT Id FROM User WHERE IsActive = TRUE AND Username = 'testuserpatient@austenriggs.net'];
		List<String> recipientIds = new List<String>();

		for (User recip : clientRecipients) {
			recipientIds.add(recip.Id);
		}
		Map<String, String> messageMap = new Map<String, String>{
			'subject' => 'Test Subject',
				'body' => 'Test Body',
				'type' => 'Standard Message',
				'isReply' => 'false',
				'messageProfile' => 'Patient',
				'hasNotification' => 'false',
				'notificationMessage' => ''
				};
					System.debug('BEGIN CreateMessageControllerTest shouldCreateMessageWithPatientRecipient recipientIds: ' + recipientIds);
		System.debug('BEGIN CreateMessageControllerTest shouldCreateMessageWithPatientRecipient messageMap: ' + messageMap);

		Test.startTest();

		CreateMessageController.send2(JSON.serialize(recipientIds), '[]', '[]', '[]', JSON.serialize(messageMap), '', '', '', '', '');

		List<Message__c> messages = [SELECT Id,type__c, Message_Profile__c FROM Message__c];

		List<Message_Recipient__c> recipients = [SELECT Id FROM Message_Recipient__c];

		// System.assertEquals(messages.size(), 1);

		// System.assertEquals(recipients.size(), 1);

		// System.assertEquals('Patient', messages[0].Message_Profile__c, 'test error: invalid or null message profile');
		Account staffContact1 = [SELECT id from account limit 1];
		Message__c msgDetails = CreateMessageController.getMessageDetails(messages[0].Id);
		// String msgProfile = CreateMessageController.getMessageProfile(messages[0].Id);
		CreateMessageController.preview(messages[0].Id, true);
		CreateMessageController.preview(messages[0].Id, false);
		CreateMessageController.getAllMessages( staffContact1.id);
		account acc = new account(name = 'test');
		insert acc;
		contact c = new contact (lastname ='test', accountid= acc.id);
		insert c;
		try{
			CreateMessageController.getMessages(messages[0].type__C, '', 1, 'Subject__c', 'Subject__c', true, acc.id, messages[0].Message_Profile__c);
			CreateMessageController.getMessages(messages[0].type__C, '', 1, 'Subject__c', 'Subject__c', true, '', messages[0].Message_Profile__c);

		}
		catch(exception ex){}
		try{

			CreateMessageController.getMessages(messages[0].type__C, '', 1, 'Subject__c', 'Subject__c', true, '', messages[0].Message_Profile__c);

		}
		catch(exception ex){}
		try{
			messages[0].type__c = 'Deleted Messages';

			CreateMessageController.getMessages('Deleted Messages', '', 1, 'Subject__c', 'Subject__c', true, '', messages[0].Message_Profile__c);

		}
		catch(exception ex){}
		try{
			messages[0].type__c = '';

			CreateMessageController.getMessages('', '', 1, 'Subject__c', 'Subject__c', true, '', messages[0].Message_Profile__c);

		}
		catch(exception ex){}

		CreateMessageController.getUnread(messages[0].type__C);
		CreateMessageController.getUnreadNotifications(messages[0].type__C);
		CreateMessageController.updateStatus(recipients[0].id, '', true);
		CreateMessageController.updateStatus(recipients[0].id, 'read', true);
		CreateMessageController.updateStatus(recipients[0].id, 'delete', true);
		CreateMessageController.updateStatus(recipients[0].id, '', false);
		CreateMessageController.updateStatus(recipients[0].id, 'read', false);
		CreateMessageController.updateStatus(recipients[0].id, 'undelete', false);
		CreateMessageController.getUserProfile();
		CreateMessageController.getSharedPosts();
		CreateMessageController.getUserDetails();
		//JN 221014
		// CreateMessageController.UpdateOriginalMessage(messages[0].id);


		 Group__c newGroup = new Group__c(Description__c = 'Test', Duration__c = 'Standing', Type__c = 'Program', Name = 'Create Message');
		insert newGroup;
		Patient_Group_Member__c pgm = new Patient_Group_Member__c();
			pgm.Group_Name__c =newGroup.id ;
		pgm.Patient__c = c.id;
		pgm.Start_Date__c = date.today();
			insert pgm;
		try{
			CreateMessageController.getClientRecipients(new list<id>{recipients[0].id}, new list<String>{newGroup.id});
		}
		catch(exception ex){}
		CreateMessageController.hasPatientPortalMessaging();
		CreateMessageController.hasFamilyPortalMessaging();
		CreateMessageController.deleteRecycleBin(new list<id>{messages[0].id},true);
		CreateMessageController.deleteRecycleBin(new list<id>{messages[0].id},false);

		CreateMessageController.getMessageCountsMap();

		messageMap = new Map<String, String>{
			'subject' => 'Test Subject',
				'body' => 'Test Body',
				'type' => 'Clinical Alert',
				'isReply' => 'false',
				'messageProfile' => 'Patient',
				'hasNotification' => 'false',
				'patient'=>acc.id,
				'notificationMessage' => ''
				};
					try{
						CreateMessageController.send2(JSON.serialize(recipientIds), '[]', '[]', '[]', JSON.serialize(messageMap), '', '', '', '', '');
					}
		catch(exception ex){}
		Test.stopTest();
	}

	// @isTest
	// static void shouldCreatePatientMessageWithUserRecipient() {
	// 	System.debug('BEGIN CreateMessageControllerTest shouldCreatePatientMessageWithUserRecipient...');
	// 	List<String> userRecipients = new List<String>{ UserInfo.getUserId() };
	// 	Map<String, String> message = new Map<String, String>{ 'subject' => 'Test Subject', 'type' => '', 'body' => 'Test Body' };

	// 	Test.startTest();
	// 	CreateMessageController.send2(JSON.serialize(userRecipients), '[]', JSON.serialize(message));
	// 	List<Message__c> messages = [SELECT Id FROM Message__c];
	// 	List<Message_Recipient__c> recipients = [SELECT Id FROM Message_Recipient__c];

	// 	System.assertEquals(messages.size(), 1);
	// 	System.assertEquals(recipients.size(), 1);
	// 	Test.stopTest();
	// }

	@isTest
	static void shouldCreateMsgRecordWithStaffRecipFromPortal() {
		System.debug('BEGIN CreateMessageControllerTest shouldCreateMsgRecordWithStaffRecipFromPortal...');
		List<String> userRecipients = new List<String>{ UserInfo.getUserId() };
			Map<String, String> message = new Map<String, String>{ 'subject' => 'Test Subject', 'type' => '', 'body' => 'Test Body' };

				Test.startTest();
		CreateMessageController.send(JSON.serialize(userRecipients), '[]', JSON.serialize(message));
		Test.stopTest();

		List<Message__c> messages = [SELECT Id FROM Message__c];
		List<Message_Recipient__c> recipients = [SELECT Id FROM Message_Recipient__c];
		// System.assertEquals(messages.size(), 1);
		// System.assertEquals(recipients.size(), 1);
	}

	@isTest
	static void shouldCreateMessageRecordWithUserGroupRecipients() {
		System.debug('BEGIN CreateMessageControllerTest shouldCreateMessageRecordWithUserGroupRecipients...');
		List<Message__c> existingMessages = [SELECT Id, Subject__c FROM Message__c];
		// System.assertEquals(0, existingMessages.size(), existingMessages);

		Group__c groupNew = [SELECT Id, (SELECT Staff_Member__c FROM Staff_Group_Members__r) FROM Group__c LIMIT 1];

		// System.assertEquals(1, groupNew.Staff_Group_Members__r.size(), groupNew.Staff_Group_Members__r);

		List<String> userRecipients = new List<String>{ UserInfo.getUserId() };

			List<String> groupRecipients = new List<String>{ groupNew.Id };

				Map<String, String> message = new Map<String, String>{ 'subject' => 'Test Subject', 'type' => '', 'body' => 'Test Body' };

					Test.startTest();

		CreateMessageController.send(JSON.serialize(userRecipients), JSON.serialize(groupRecipients), JSON.serialize(message));

		List<Message__c> messages = [SELECT Id, Subject__c FROM Message__c];

		// System.assertEquals(1, messages.size(), messages);

		for (Message_Recipient__c r : [
			SELECT Id, Message__c, Added_As_Group_Member__c, Added_Under_Group_Name__c, Group_Membership__c, Is_Deleted__c, Read__c, User__c
			FROM Message_Recipient__c
		]) {
			System.debug('recipient: ' + r);
		}

		List<Message_Recipient__c> recipients = [SELECT Id, User__c, User__r.Name, Group_Membership__c FROM Message_Recipient__c];

		// System.assertEquals(2, recipients.size(), recipients);

		Test.stopTest();
	}

	static testMethod Void hetmessageCounttest(){
		Message__c message = new Message__c(
			Subject__c = 'parsedMessage.get()',
			Body__c = 'parsedMessage.get,',
			Type__c = 'Standard Message',
			Is_Reply__c = true,
			Message_Profile__c = 'Staff',

			Short_Notification_Message__c = ''
		);
		 Message__c message1 = new Message__c(
			Subject__c = 'parsedMessage.get()',
			Body__c = 'parsedMessage.get,',
			Type__c = 'Standard Message',

			Message_Profile__c = 'Patient',

			Short_Notification_Message__c = ''
		);
		 Message__c message2 = new Message__c(
			Subject__c = 'parsedMessage.get()',
			Body__c = 'parsedMessage.get,',
			Type__c = 'Standard Message',
			Is_Reply__c = true,
			Message_Profile__c = 'Family',
			ownerid = userinfo.getuserid(),
			Short_Notification_Message__c = ''
		);
		insert new list<Message__c>{message,message1,message2};
			Message_Recipient__c recipient = new Message_Recipient__c(User__c = userinfo.getUserId(),message__c = message.id,
			 Read__c =true);

			Message_Recipient__c recipient1 = new Message_Recipient__c(User__c = userinfo.getUserId(),message__c = message.id
			 );

				Message_Recipient__c recipient2 = new Message_Recipient__c(User__c = userinfo.getUserId(),message__c = message1.id,
			 Read__c =true);

			Message_Recipient__c recipient3 = new Message_Recipient__c(User__c = userinfo.getUserId(),message__c = message1.id
			 );

				Message_Recipient__c recipient4 = new Message_Recipient__c(User__c = userinfo.getUserId(),message__c = message2.id,
			 Read__c =true);

			Message_Recipient__c recipient5 = new Message_Recipient__c(User__c = userinfo.getUserId(),message__c = message2.id
			 );
		insert new Message_Recipient__c[]{recipient,recipient1,recipient2,recipient3,recipient4,recipient5};
		CreateMessageController.getMessageCountsMap();
	}
}
public with sharing class CreateMessageController 
{

	private static Integer PAGE_SIZE = 10;	
	
	//TODO remove this method 220926 JN, superseded by send2()
	@AuraEnabled
	public static void send(String sUserRecipients, String sGroupRecipients, String sMessage) {
		System.debug('CreateMessageController send...');
		Map<String, String> parsedMessage = (Map<String, String>) JSON.deserialize(sMessage, Map<String, String>.class);
		Message__c message = new Message__c(
			Subject__c = parsedMessage.get('subject'),
			Body__c = parsedMessage.get('body'),
			Type__c = parsedMessage.get('type')
		);

		includeLinkedFields(message, parsedMessage);

		List<Message_Recipient__c> recipients = new List<Message_Recipient__c>();
		
		if(null != sUserRecipients) {
			List<String> parsedUserRecipients = (List<String>) JSON.deserialize(sUserRecipients, List<String>.class);
		
				if(null != parsedUserRecipients) {
				for (String sRecipient : parsedUserRecipients) {
					Message_Recipient__c recipient = new Message_Recipient__c(User__c = Id.valueOf(sRecipient));
					recipients.add(recipient);
				}
			}
		}

		if(null != sGroupRecipients) {
			List<String> parsedGroupRecipients = (List<String>) JSON.deserialize(sGroupRecipients, List<String>.class);
		
			if(null != parsedGroupRecipients) {
				for (String sRecipient : parsedGroupRecipients) {
					Message_Recipient__c recipient = new Message_Recipient__c(Group_Membership__c = Id.valueOf(sRecipient));
					recipients.add(recipient);
				}
			}
		}

		// if (parsedMessage.get('type') == 'Clinical Alert') {
		// 	String patientAccountId = parsedMessage.get('patient');
		// 	Contact patient = [SELECT Id FROM Contact WHERE AccountId = :patientAccountId LIMIT 1];
		// 	message.Contact__c = patient.Id;
		// }

		// String patientNoteId = parsedMessage.get('patientNoteId');

		// if (patientNoteId != null && patientNoteId != '') {
		// 	message.Patient_Note__c = patientNoteId;
		// }

		// String prescriptionId = parsedMessage.get('prescriptionId');
		// if (prescriptionId != null && prescriptionId != '') {
		// 	message.Prescription__c = prescriptionId;
		// }

		try {
			MessageService.sendQuickMessage(message, recipients);
		} catch (Exception e) {
			throw new AuraException('CreateMessageController.send error: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static void send2(
		String sClientRecipients,
		String sUserRecipients,
		String sClientGroupRecipients,
		String sUserGroupRecipients,
		String sMessage,
		String sIsReply,
		String sOriginalMsgId,
		String sMessageProfile,
		String sHasNotification,
		String sNotificationMessage) 
	{
		System.debug('CreateMessageController send2... sMessageProfile ' + sMessageProfile);
		Map<String, String> parsedMessage = (Map<String, String>) JSON.deserialize(sMessage, Map<String, String>.class);

		Message__c message = new Message__c(
			Subject__c = parsedMessage.get('subject'),
			Body__c = parsedMessage.get('body'),
			Type__c = parsedMessage.get('type'),
			Is_Reply__c = Boolean.valueOf(parsedMessage.get('isReply')),
			// Message_Replied_To__c = parsedMessage.get('originalMsgId'),
			Message_Profile__c = parsedMessage.get('messageProfile'),
			Has_Notification_Message__c = parsedMessage.get('hasNotification') != null
				? Boolean.valueOf(parsedMessage.get('hasNotification'))
				: false,
			Short_Notification_Message__c = parsedMessage.get('notificationMessage')
		);
		includeLinkedFields(message, parsedMessage);
		System.debug('send2 message ' + message);

		List<Message_Recipient__c> recipients = new List<Message_Recipient__c>();
		List<String> parsedClientRecipients = new List<String>();
		List<String> parsedUserRecipients = new List<String>();
		List<String> parsedClientGroupRecipients = new List<String>();
		List<String> parsedUserGroupRecipients = new List<String>();
		Id recipientId = null;

		if (sClientRecipients == '[]') {
			sClientRecipients = null;
		}
		if (sUserRecipients == '[]') {
			sUserRecipients = null;
		}
		if (sClientGroupRecipients == '[]') {
			sClientGroupRecipients = null;
		}
		if (sUserGroupRecipients == '[]') {
			sUserGroupRecipients = null;
		}

		if (sClientRecipients != null && sClientRecipients.length() > 0) {
			parsedClientRecipients = (List<String>) JSON.deserialize(sClientRecipients, List<String>.class);
			recipientId = parsedClientRecipients[0];
			for (String sRecipient : parsedClientRecipients) {
				Message_Recipient__c recipient = new Message_Recipient__c(User__c = Id.valueOf(sRecipient));
				recipients.add(recipient);
			}
		}

		if (sUserRecipients != null && sUserRecipients.length() > 0) {
			parsedUserRecipients = (List<String>) JSON.deserialize(sUserRecipients, List<String>.class);
			for (String sRecipient : parsedUserRecipients) {
				Message_Recipient__c recipient = new Message_Recipient__c(User__c = Id.valueOf(sRecipient));
				recipients.add(recipient);
			}
		}

		if (sClientGroupRecipients != null && sClientGroupRecipients.length() > 0) {
			parsedClientGroupRecipients = (List<String>) JSON.deserialize(sClientGroupRecipients, List<String>.class);
			for (String sRecipient : parsedClientGroupRecipients) {
				Message_Recipient__c recipient = new Message_Recipient__c(Group_Membership__c = Id.valueOf(sRecipient));
				recipients.add(recipient);
			}
		}

		if (sUserGroupRecipients != null && sUserGroupRecipients.length() > 0) {
			parsedUserGroupRecipients = (List<String>) JSON.deserialize(sUserGroupRecipients, List<String>.class);
			for (String sRecipient : parsedUserGroupRecipients) {
				Message_Recipient__c recipient = new Message_Recipient__c(Group_Membership__c = Id.valueOf(sRecipient));
				recipients.add(recipient);
			}
		}

		List<Group_Membership_Hierarchy__c> groupHierarchy = [SELECT Id, Parent_Group_Membership__c, 
																	Children_Group_Membership__c 
																FROM Group_Membership_Hierarchy__c
																WHERE Parent_Group_Membership__c in :parsedUserGroupRecipients];
		for(Group_Membership_Hierarchy__c h : groupHierarchy) {
			Message_Recipient__c recipient = new Message_Recipient__c(Group_Membership__c = h.Children_Group_Membership__c);
			recipients.add(recipient);
		}
		try {
			MessageService.sendQuickMessage(message, recipients);
		} catch (Exception e) {
			throw new AuraException('CreateMessageController.send2 error: ' + e.getMessage());
		}
	}

	static void includeLinkedFields(Message__c message, Map<String, String> parsedMessage)
	{
		if (parsedMessage.get('type') == 'Clinical Alert') {
			String patientAccountId = parsedMessage.get('patient');
			Contact patient = [SELECT Id FROM Contact WHERE AccountId = :patientAccountId LIMIT 1];
			message.Contact__c = patient.Id;
		}

		String patientNoteId = parsedMessage.get('patientNoteId');
		if (patientNoteId != null && patientNoteId != '') {
			message.Patient_Note__c = patientNoteId;
		}

		String prescriptionId = parsedMessage.get('prescriptionId');
		if (prescriptionId != null && prescriptionId != '') {
			message.Prescription__c = prescriptionId;
		}

	}

	// @testVisible
	// private static void UpdateOriginalMessage(String origMsgId) {
	// 	System.debug('CreateMessageController UpdateOriginalMessage...');

	// 	Message__c updateMessage = new Message__c(Id = origMsgId, Replied__c = true);

	// 	try {
	// 		update updateMessage;
	// 	} catch (Exception e) {
	// 		throw new AuraException('CreateMessageController.UpdateOriginalMessage error: ' + e.getMessage());
	// 	}
	// }

	@AuraEnabled
	public static Message__c getMessageDetails(String messageId) 
	{
		// System.debug('CreateMessageController getMessageDetails...');
        try 
		{
			return [
				SELECT Id, Body__c, Subject__c, Message_Profile__c, Has_Notification_Message__c, OwnerId, CreatedDate, FORMAT(CreatedDate) formattedCreatedDate,
						Notification_Sent__c, Short_Notification_Message__c, Is_Reply__c, 
						Prescription__c, Patient_Note__c, Patient_Note__r.Type__c, Contact__c, Contact__r.Name, Contact__r.Distinguished_Name__c,
						TYPEOF Owner 
							WHEN User THEN Name, Professional_Name__c
						END,
					(SELECT Id, User__c, User__r.Name, Group_Membership__c, Group_Membership__r.Name, Is_Deleted__c, 
							Message__r.Prescription__c, Message__r.Patient_Note__c, Message__r.Contact__c
						FROM Message_Recipients__r
						WHERE User__c != :UserInfo.getUserId())
				FROM Message__c
				WHERE Id = :messageId
				LIMIT 1];
        } catch (Exception e) {
			throw new AuraException('CreateMessageController.UpdateOriginalMessage getMessageDetails: ' + e.getMessage());
		}
	}

	// @AuraEnabled
	// public static String getMessageProfile(String messageId) {
	// 	System.debug('CreateMessageController getMessageProfile...');

	// 	try {
    //         String msgType = [SELECT Id, Message_Profile__c FROM Message__c WHERE Id = :messageId LIMIT 1].Message_Profile__c;
    //         return msgType;
    //     } catch (Exception e) {
    //         throw new AuraException('CreateMessageController.getMessageProfile error: ' + e.getMessage());
	// 	}
	// }

	@AuraEnabled
	public static Object preview(String messageId, Boolean patientView) {
		System.debug('CreateMessageController preview... ' + messageId);
		Object message;

		String messagePrefix = Schema.SObjectType.Message__c.getKeyPrefix();
		Boolean isRecipientId = (messageId.left(3) == messagePrefix ? false : true);

		if (patientView == true) {
			//query for message only, no recipients
			message = [
				SELECT Id, CreatedDate, Type__c, Body__c, Subject__c, Owner.Name, OwnerId, Message_Profile__c, 
					Has_Notification_Message__c, Notification_Sent__c, Short_Notification_Message__c,
					Contact__c, Contact__r.Name, Contact__r.Distinguished_Name__c, Patient_Note__c, Patient_Note__r.Type__c, Prescription__c
				FROM Message__c
				WHERE Id = :messageId
				LIMIT 1
				ALL ROWS
			];
		} else {
			if (isRecipientId) {
				//Get Message Id from that recipient Id
				List<Message_Recipient__c> allRecipients = new List<Message_Recipient__c>();

				List<Message_Recipient__c> firstRecipient = [
					SELECT Id, Message__c
					FROM Message_Recipient__c
					WHERE Id = :messageId
					ALL ROWS
				];
				if (!firstRecipient.isEmpty()) {
					messageId = firstRecipient[0].Message__c;
				}
			}
			List<Message_Recipient__c> allRecipients = [
				SELECT
					Id,
					User__c,
					User__r.Name,
					Read__c,
					Is_Deleted__c,
					IsDeleted,
					Message__c,
					Message__r.IsDeleted,
					Message__r.Subject__c,
					Message__r.Type__c,
					Message__r.Body__c,
					Message__r.CreatedDate,
					Message__r.OwnerId,
					Message__r.Owner.Name,
					Added_As_Group_Member__c,
					Added_Under_Group_Name__c,
					Group_Membership__r.Name,
					Message__r.Message_Profile__c,
					Message__r.Contact__c,
					Message__r.Contact__r.Name,
					Message__r.Contact__r.Distinguished_Name__c,
					Message__r.Patient_Note__c,
					Message__r.Patient_Note__r.Type__c,
					Message__r.Prescription__c
				FROM Message_Recipient__c
				WHERE Message__c = :messageId
                    AND Group_Membership__c = null
                    AND User__c != null
				ALL ROWS
			];

			message = new MessageWrapper(allRecipients);
		}

		try {
            return message;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.preview error: ' + e.getMessage());
		}
	}

	public class MessageWrapper {
		@AuraEnabled
		public Message__c msg;
		@AuraEnabled
		public List<Message_Recipient__c> allRecipients;

		public MessageWrapper(List<Message_Recipient__c> recipients) {
			if (!recipients.isEmpty()) {
				this.msg = recipients[0].Message__r;
			}
			this.allRecipients = recipients;
		}
	}

	@AuraEnabled
	public static Integer getUnread(String type) {
		System.debug('CreateMessageController getUnread...');

		Integer unread = [
			SELECT COUNT()
			FROM Message_Recipient__c
			WHERE Read__c = FALSE AND Is_Deleted__c = FALSE AND Message__r.Type__c = :type AND User__c = :UserInfo.getUserId()
		];

		try {
            return unread;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getUnread error: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static Integer getUnreadNotifications(String type) {
		System.debug('CreateMessageController getUnreadNotifications...');

		Integer unread = [
			SELECT COUNT()
			FROM Message_Recipient__c
			WHERE
				Read__c = FALSE
				AND Is_Deleted__c = FALSE
				AND Message__r.Type__c = :type
				AND Message__r.Has_Notification_Message__c = TRUE
				// AND Message__r.Notification_Sent__c = TRUE
				AND User__c = :UserInfo.getUserId()
		];

		try {
            return unread;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getUnread error: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static Map<String, Integer> getMessageCountsMap() {
		System.debug('CreateMessageController getMessageCountsMap...');
		Map<String, Integer> resultsMap = new Map<String, Integer>();
		Integer familyCounter = 0;
		Integer inboxCounter = 0;
		Integer patientCounter = 0;
		Integer sentCounter = 0;
		Integer staffCounter = 0;
		Integer unreadCounter = 0;

		Id userId = UserInfo.getUserId();
		// List<String> messageFilters = new List<String>{ 'All', 'Unread' };

		List<Message__c> sentMessages = new List<Message__c>();
		List<Message_Recipient__c> inboxMessages = new List<Message_Recipient__c>();
		List<Message_Recipient__c> deletedMessages = new List<Message_Recipient__c>();

		try {
			sentMessages = [
				SELECT
					Id,
					Subject__c,
					Is_Reply__c,
					IsDeleted,
					Is_Deleted__c,
					Message_Profile__c,
					Owner.Name,
					OwnerId,
					CreatedBy.Id,
					CreatedBy.Name,
					CreatedBy.Contact.RecordType.DeveloperName,
					CreatedDate,
					Owner.Type,
					Search_Body__c
				FROM Message__c
				WHERE OwnerId = :userId AND Type__c = 'Standard Message' AND Message_Profile__c != NULL AND Is_Deleted__c = false
				ORDER BY CreatedDate DESC
				// ALL ROWS
			];
		} catch (Exception e) {
			throw new AuraException('CreateMessageController.getMessageCountsMap Error: ' + e.getMessage());
		}

		try {
			inboxMessages = [
				SELECT
					Id,
					Message__r.Id,
					Message__r.Message_Profile__c,
					Read__c,
					Is_Deleted__c,
					CreatedDate,
					Added_As_Group_Member__c,
					Added_Under_Group_Name__c,
					Group_Membership__r.Id,
					Group_Membership__r.Name,
					Group_Membership__r.Active__c,
					Group_Membership__r.Primary_Function__c
				FROM Message_Recipient__c
				WHERE Is_Deleted__c = FALSE AND Message__r.Type__c = 'Standard Message' AND User__c = :userId
				// WHERE User__r.Id = :userId AND Message__r.Message_Profile__c != NULL AND Message__r.Owner.IsActive = TRUE
				ORDER BY CreatedDate DESC
			];
		} catch (Exception e) {
			throw new AuraException('CreateMessageController.getMessageCountsMap Error: ' + e.getMessage());
		}

		try {
			deletedMessages = [
				SELECT
					Id,
					Message__r.Id,
					Message__r.Message_Profile__c,
					Read__c,
					Is_Deleted__c,
					CreatedDate,
					Added_As_Group_Member__c,
					Added_Under_Group_Name__c,
					Group_Membership__r.Id,
					Group_Membership__r.Name,
					Group_Membership__r.Active__c,
					Group_Membership__r.Primary_Function__c
				FROM Message_Recipient__c
				WHERE Is_Deleted__c = TRUE AND Message__r.Type__c = 'Standard Message' AND User__c = :userId
				ORDER BY CreatedDate DESC
			];
		} catch (Exception e) {
			throw new AuraException('CreateMessageController.getMessageCountsMap Error: ' + e.getMessage());
		}

		for (Message__c parent : sentMessages) {
			sentCounter++;

			if (parent.Message_Profile__c == 'Family') {
				familyCounter++;
			} else if (parent.Message_Profile__c == 'Patient') {
				patientCounter++;
			} else if (parent.Message_Profile__c == 'Staff') {
				staffCounter++;
			}
		}
		resultsMap.put('SentMessages', sentCounter);
		resultsMap.put('SentFamily', familyCounter);
		resultsMap.put('SentPatient', patientCounter);
		resultsMap.put('SentStaff', staffCounter);

		familyCounter = 0;
		// resultsMap.put('UnreadFamily', familyCounter);
		patientCounter = 0;
		// resultsMap.put('UnreadPatient', patientCounter);
		staffCounter = 0;
		// resultsMap.put('UnreadStaff', staffCounter);

		for (Message_Recipient__c child : inboxMessages) {
			if (!child.Is_Deleted__c) {
				if (!child.Read__c) {
					unreadCounter++;

					if (child.Message__r.Message_Profile__c == 'Family') {
						familyCounter++;
					} else if (child.Message__r.Message_Profile__c == 'Patient') {
						patientCounter++;
					} else if (child.Message__r.Message_Profile__c == 'Staff') {
						staffCounter++;
					}
				}
			}
		}
		resultsMap.put('UnreadMessages', unreadCounter);
		resultsMap.put('UnreadFamily', familyCounter);
		resultsMap.put('UnreadPatient', patientCounter);
		resultsMap.put('UnreadStaff', staffCounter);

		familyCounter = 0;
		// resultsMap.put('ReadFamily', familyCounter);
		patientCounter = 0;
		// resultsMap.put('ReadPatient', patientCounter);
		staffCounter = 0;
		// resultsMap.put('ReadStaff', staffCounter);

		for (Message_Recipient__c child : inboxMessages) {
			if (!child.Is_Deleted__c) {
				if (child.Read__c) {
					if (child.Message__r.Message_Profile__c == 'Family') {
						familyCounter++;
					} else if (child.Message__r.Message_Profile__c == 'Patient') {
						patientCounter++;
					} else if (child.Message__r.Message_Profile__c == 'Staff') {
						staffCounter++;
					}
				}
			}
		}
		resultsMap.put('ReadFamily', familyCounter);
		resultsMap.put('ReadPatient', patientCounter);
		resultsMap.put('ReadStaff', staffCounter);

		resultsMap.put('DeletedMessages', deletedMessages.size());
		resultsMap.put('InboxFamily', resultsMap.get('ReadFamily') + resultsMap.get('UnreadFamily'));
		resultsMap.put('InboxPatient', resultsMap.get('ReadPatient') + resultsMap.get('UnreadPatient'));
		resultsMap.put('InboxStaff', resultsMap.get('ReadStaff') + resultsMap.get('UnreadStaff'));
		resultsMap.put('InboxMessages', resultsMap.get('InboxFamily') + resultsMap.get('InboxPatient') + resultsMap.get('InboxStaff'));

		//Clinical Alerts
		resultsMap.put('UnreadClinicalAlert', 0);
		resultsMap.put('ReadClinicalAlert', 0);

		List<AggregateResult> alertArs = [SELECT Read__c read, Count(Id) cnt
											FROM Message_Recipient__c
											WHERE User__c = :Userinfo.getUserId() 
												AND Message__r.Type__c = 'Clinical Alert'
												AND Is_Deleted__c = false
											GROUP BY Read__c];
		for (AggregateResult ar : alertArs)
		{
			if (ar.get('read') == false) resultsMap.put('UnreadClinicalAlert', (Integer)ar.get('cnt'));
			if (ar.get('read') == true) resultsMap.put('ReadClinicalAlert', (Integer)ar.get('cnt'));
		}
		resultsMap.put('ClinicalAlert', resultsMap.get('ReadClinicalAlert') + resultsMap.get('UnreadClinicalAlert'));

		try {
            return resultsMap;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getMessageCountsMap error: ' + e.getMessage());
		}
	}

	//object wrapper for getMessages() method 221020 JN
	@AuraEnabled
	public static String getMessagesWrapper(
		String type,
		String searchTerm,
		Integer page,
		String sortAsc,
		String field,
		Boolean unreadOnly,
		String clientId,
		String messageProfile)
	{
		MessagesWrapper returnMw = new MessagesWrapper((List<sObject>)getMessages(type, searchTerm, page, sortAsc, field, unreadOnly, clientId, messageProfile));
		
		return JSON.serialize(returnMw);
	}

	@AuraEnabled
	public static List<Object> getMessages(
		String type,
		String searchTerm,
		Integer page,
		String sortAsc,
		String field,
		Boolean unreadOnly,
		String clientId,
		String messageProfile
	) {
		System.debug('CreateMessageController getMessages...');
		Integer offset = PAGE_SIZE * page;
		String search = '%' + searchTerm + '%';
		Id userId = UserInfo.getUserId();
		List<sObject> messages = new List<sObject>();

		System.debug('getMessages type ' + type + ' page ' + page + ' offset ' + offset + ' searchTerm ' + searchTerm + ' messageProfile ' + messageProfile + ' unreadOnly ' + unreadOnly);
		if (clientId != '') {
			Id cId = [SELECT Id FROM Contact WHERE AccountId = :clientId].Id;
			messages = (List<Message__c>) Database.query(
				'SELECT Id, Owner.Name, OwnerId, Subject__c, Body__c, CreatedDate, CreatedBy.Name, Message_Profile__c, Has_Notification_Message__c, Notification_Sent__c, Replied__c, Short_Notification_Message__c' +
				' FROM Message__c' +
				' WHERE Type__c = :type' +
					' AND Contact__c = :cId' +
					(messageProfile != '' ? ' AND Message_Profile__c = :messageProfile' : '') +
					(searchTerm != '' ? ' AND (Subject__c LIKE :search OR Search_Body__c LIKE :search)' : '') +
				' ORDER BY ' + field + ' ' + sortAsc +
				' LIMIT :PAGE_SIZE' +
				' OFFSET ' + offset
			);
		} else if (type == 'Standard Message' || type == 'Clinical Alert') 
		{
			String queryFilters = ' WHERE Message__r.Type__c = \'' + type + '\'' +
										' AND User__c = :userId' +
										' AND Is_Deleted__c = false' +
										(messageProfile != null ? ' AND Message__r.Message_Profile__c = :messageProfile' : '') +
										(searchTerm != '' ? ' AND (Message__r.Owner.Name LIKE :search OR Message__r.Subject__c LIKE :search OR Message__r.Search_Body__c LIKE :search)' : '') +
										(unreadOnly ? ' AND Read__c = false' : '') +
									' ORDER BY ' + field + ' ' + sortAsc + 
									' LIMIT ' + PAGE_SIZE + 
									' OFFSET ' + offset;
			System.debug('queryFilters ' + queryFilters);
			messages = (List<Message_Recipient__c>) Database.query(
				'SELECT Id, Message__c, User__r.Name, Read__c, Message__r.Message_Profile__c, Message__r.Body__c, Message__r.Owner.Name, Message__r.OwnerId, Message__r.Replied__c, Message__r.Subject__c, Message__r.CreatedDate, Message__r.CreatedBy.Name, Message__r.Has_Notification_Message__c, Message__r.Notification_Sent__c, Message__r.Short_Notification_Message__c' +
				' FROM Message_Recipient__c' +
				queryFilters
			);
		} else if (type == 'Deleted Messages') {
			//two groups of messages in my recycle bin:
			//messages TO me where I marked the recipient Is_Deleted__c TRUE
			//messages FROM me where I marked the Message__c as Is_Deleted = true
			List<Message_Recipient__c> deletedRecipientsToMe = (List<Message_Recipient__c>) Database.query(
				'SELECT Id, Message__c, User__r.Name, Read__c, Message__r.Owner.Name, Message__r.Message_Profile__c,  Message__r.Body__c,' +
					' Message__r.OwnerId, Message__r.Subject__c, Message__r.CreatedDate, Message__r.CreatedBy.Name, Message__r.Has_Notification_Message__c,' +
					' Message__r.Notification_Sent__c, Message__r.Replied__c, Message__r.Short_Notification_Message__c' +
				' FROM Message_Recipient__c' +
				' WHERE User__c = :userId' +
					' AND Is_Deleted__c = true' +
					(searchTerm != ''
						? ' AND (Message__r.Owner.Name LIKE :search OR Message__r.Subject__c LIKE :search OR Message__r.Search_Body__c LIKE :search)'
						: '')
			);

			Set<Id> deletedMessageIds = new Set<Id>();

			for (Message_Recipient__c recip : deletedRecipientsToMe) {
				deletedMessageIds.add(recip.Message__c);
			}

			List<Message__c> deletedMessages = (List<Message__c>) Database.query(
				'SELECT Id, Subject__c, Body__c, OwnerId, Owner.Name, CreatedDate, LastModifiedDate, CreatedBy.Name, Message_Profile__c,' +
					' (SELECT Id, User__c, User__r.Name, Is_Deleted__c, Read__c, LastModifiedDate' +
						' FROM Message_Recipients__r)' +
				' FROM Message__c' +
				' WHERE ((OwnerId = :userId AND Is_Deleted__c = true)' +
					' OR (Id in :deletedMessageIds))' +
					(messageProfile != null ? ' AND Message_Profile__c = :messageProfile' : '') +
				' ORDER BY ' + field + ' ' + sortAsc +
				' LIMIT :PAGE_SIZE' +
				' OFFSET ' + offset
				//+ ' ALL ROWS'
			);

			messages = deletedMessages;
		} else {
			String query =
				'SELECT Id, OwnerId, Owner.Name, Subject__c, Body__c, CreatedDate, CreatedBy.Name, Message_Profile__c, Has_Notification_Message__c, Notification_Sent__c, Replied__c, Short_Notification_Message__c,' +
					' (SELECT Id, User__c, User__r.Name, Read__c, Is_Deleted__c' +
						' FROM Message_Recipients__r' +
						' ORDER BY User__r.Name ASC)' +
						//' WHERE Is_Deleted__c = false)' +
				' FROM Message__c ' +
				' WHERE Type__c = \'Standard Message\' AND OwnerId = :userId ' +
					(messageProfile != null ? ' AND Message_Profile__c = :messageProfile' : '') +
					(searchTerm != '' ? ' AND (Subject__c LIKE :search OR Search_Body__c LIKE :search)' : '') +
				' ORDER BY ' + field + ' ' + sortAsc +
				' LIMIT :PAGE_SIZE' +
				' OFFSET ' + offset;

			//Sent Messages
			messages = (List<sObject>) Database.query(query);

			// List<sObject> newList = new List<sObject>();

			// for (sObject msg : messages) {
			// 	List<sObject> recipients = (List<Sobject>) msg.getSobjects('Message_Recipients__r');
			// 	newList.add(msg);
			// }

			// messages = newList;
		}

		try {
            return messages;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getMessages error: ' + e.getMessage());
		}
	}

	//TODO remove this, not in use
	@AuraEnabled
	public static List<Object> getAllMessages(String clientId) {
		System.debug('CreateMessageController getAllMessages...');
		Id userId = UserInfo.getUserId();
		List<sObject> messages = new List<sObject>();

		messages = [
			SELECT
				Body__c,
				CreatedDate,
				Has_Notification_Message__c,
				Id,
				Is_Reply__c,
				Message_Profile__c,
				Name,
				Notification_Sent__c,
				OwnerId,
				Owner.Type,
				Owner.Name,
				Contact__c,
				Contact__r.Distinguished_Name__c,
				Contact__r.Name,
				Patient_Note__c,
				Patient_Note__r.Type__c,
				Prescription__c,
				Replied__c,
				Search_Body__c,
				Subject__c,
				Type__c,
				(
					SELECT
						Added_As_Group_Member__c,
						Added_Under_Group_Name__c,
						CreatedById,
						CreatedDate,
						Group_Membership__c,
						Id,
						Is_Deleted__c,
						IsDeleted,
						Message__c,
						Name,
						Read__c,
						User__c,
						User__r.Name,
						User__r.ContactId,
						User__r.Contact.Name
					FROM Message_Recipients__r
					WHERE User__r.ContactId != NULL
					ORDER BY CreatedDate DESC
				)
			FROM Message__c
			ORDER BY CreatedDate DESC
		];

		try {
            return messages;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getAllMessages error: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static void updateStatus(String messageRecipientId, String updateType, Boolean value) {
		System.debug('CreateMessageController updateStatus...');

		List<Message_Recipient__c> recipients = [
			SELECT
				Id,
				Read__c,
				Is_Deleted__c,
				User__c,
				IsDeleted,
				Message__c,
				Message__r.Id,
				Message__r.OwnerId,
				Message__r.Type__c,
				Message__r.isDeleted
			FROM Message_Recipient__c
			WHERE Id = :messageRecipientId
			ALL ROWS
		];

		if (!recipients.isEmpty()) {
			List<Message_Recipient__c> recipientsToUpdate = new List<Message_Recipient__c>();
			if (updateType == 'Read') {
				for (Message_Recipient__c recipient : recipients) {
					if (recipient.User__c == Userinfo.getUserId() && recipient.Read__c != value) {
						recipient.Read__c = value;
						recipientsToUpdate.add(recipient);
					}
				}
			} else if (updateType == 'Delete' || updateType == 'UnDelete') {
				Message__c msg = recipients[0].Message__r;
				if (msg.OwnerId == Userinfo.getUserId()) {
					if (updateType == 'Delete') {
						
						// JN 221004 do not delete message, just mark this recipient as Is Deleted
						// List<Message_Recipient__c> allRecipients = [SELECT Id FROM Message_Recipient__c WHERE Message__c = :msg.Id];
						// delete allRecipients;
						// delete msg;
						recipients[0].Is_Deleted__c = true;
						recipientsToUpdate.add(recipients[0]);
					} else if (updateType == 'Undelete') {
						//undelete msg;
						recipients[0].Is_Deleted__c = false;
						recipientsToUpdate.add(recipients[0]);

						// List<Message_Recipient__c> allDeletedRecipients = [
						// 	SELECT Id, Is_Deleted__c, IsDeleted
						// 	FROM Message_Recipient__c
						// 	WHERE Message__c = :msg.Id AND isDeleted = TRUE
						// 	ALL ROWS
						// ];

						//undelete allDeletedRecipients;
						// for (Message_Recipient__c recip : allDeletedRecipients) {
						// 	if (recip.Is_Deleted__c == true) {
						// 		recip.Is_Deleted__c = false;
						// 		recipientsToUpdate.add(recip);
						// 	}
						// }
					}
				} else {
					for (Message_Recipient__c recipient : recipients) {
						if (recipient.Is_Deleted__c != value) {
							recipient.Is_Deleted__c = value;
							recipientsToUpdate.add(recipient);
						}
					}
				}
			}

			List<Database.SaveResult> results = Database.update(recipientsToUpdate, true);

			for (Database.SaveResult dsr : results) {
				if (!dsr.isSuccess()) {
                    throw new AuraException('CreateMessageController.updateStatus error ' + String.valueOf(dsr.getErrors()));
				}
			}
		}
	}

	@AuraEnabled
	public static void deleteRecycleBin(List<Id> messageReceiptIds, Boolean clientUser) {
		System.debug('CreateMessageController deleteRecycleBin...');

		if (clientUser) {
			List<Message__c> recordsToDelete = [SELECT Id FROM Message__c WHERE Id IN :messageReceiptIds];

			List<Database.DeleteResult> deleteResults = Database.delete(recordsToDelete, true);

			for (Database.DeleteResult deleteResult : deleteResults) {
				if (!deleteResult.isSuccess()) {
                    throw new AuraException('CreateMessageController.deleteRecycleBin error');
				}
			}
		} else {
			List<Message_Recipient__c> recordsToDelete = [SELECT Id FROM Message_Recipient__c WHERE Id IN :messageReceiptIds];

			List<Database.DeleteResult> deleteResults = Database.delete(recordsToDelete, true);

			for (Database.DeleteResult deleteResult : deleteResults) {
				if (!deleteResult.isSuccess()) {
                    throw new AuraException('CreateMessageController.deleteRecycleBin error');
				}
			}
		}
	}

	@AuraEnabled
	public static Boolean hasFamilyPortalMessaging() {
		System.debug('CreateMessageController hasFamilyPortalMessaging...');

		User u = [SELECT Id, Profile.Name FROM User WHERE id = :UserInfo.getUserId()];
		Boolean hasFam = PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'FamilyPortalMessaging');

		try {
		    return u.Profile.Name == 'System Administrator' || hasFam;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.hasFamilyPortalMessaging error: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static Boolean hasPatientPortalMessaging() {
		System.debug('CreateMessageController hasPatientPortalMessaging...');

		User u = [SELECT Id, Profile.Name FROM User WHERE id = :UserInfo.getUserId()];
		Boolean hasPatient = PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'PatientPortalMessaging');

		try {
		    return u.Profile.Name == 'System Administrator' || hasPatient;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.hasPatientPortalMessaging error: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static List<String> getClientRecipients(List<String> ids, List<String> groups) {
		System.debug('CreateMessageController getClientRecipients...');

		List<Id> contactIds = new List<Id>();

		List<User> users = [SELECT Id, ContactId, Contact.RecordType.Name, Contact.Name FROM User WHERE Id IN :ids];

		for (User u : users) {
			contactIds.add(u.ContactId);
		}

		List<Patient_Group_Member__c> groupMembers = [SELECT Id, Patient__c FROM Patient_Group_Member__c WHERE Group_Name__c IN :groups];

		for (Patient_Group_Member__c m : groupMembers) {
			contactIds.add(m.Patient__c);
		}

		List<Related_Contact__c> relContacts = [
			SELECT
				Id,
				Related_Contact_Official_Long_Name__c,
				Contact_Name__c,
				RecordType.Name,
				Account__r.Name,
				Contact__r.LastName,
				Contact__r.FirstName,
				Type__c,
				Long_Role__c
			FROM Related_Contact__c
			WHERE Contact__c IN :contactIds
			ORDER BY Contact__r.LastName, Contact__r.FirstName, Type__c
		];

		List<String> officialNames = new List<String>();

		for (Related_Contact__c rel : relContacts) {
			if (rel.RecordType.Name == 'Personal') {
				officialNames.add(
					rel.Contact_Name__c +
					',' +
					rel.Long_Role__c +
					' of <span class=\'bold\'>' +
					rel.Account__r.Name +
					'</span>'
				);
			} else {
				officialNames.add('<span class=\'bold\'>' + rel.Contact_Name__c + '</span>, ' + rel.Long_Role__c);
			}
		}

		try {
		    return officialNames;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getClientRecipients error: ' + e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<User> getUserDetails() {
		System.debug('CreateMessageController getUserDetails...');
		List<User> users = [SELECT Id, Name, Contact.Account.Current_Admission_Stage__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		try {
            return users;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getUserDetails error: ' + e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<Post__c> getSharedPosts() {
		System.debug('CreateMessageController getSharedPosts...');

        try {
        return [
			SELECT Id, Type__c, Title__c, Active__c, Info__c, Patient_Contact__c, Sort_Order__c, LastModifiedDate, LastModifiedBy.Name
			FROM Post__c
			WHERE Active__c = TRUE AND Recordtype.DeveloperName = 'Shared'
			ORDER BY Sort_Order__c ASC NULLS LAST, LastModifiedDate DESC
		];
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getSharedPosts error: ' + e.getMessage());
		}

	}

	@AuraEnabled(cacheable=true)
	public static String getUserProfile() {
		System.debug('CreateMessageController getUserProfile...');
		User u = [
			SELECT Id, Profile.Name
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

        try {
            return u.Profile.Name;
        } catch (Exception e) {
            throw new AuraException('CreateMessageController.getUserDetails error: ' + e.getMessage());
		}
	}

	public class MessagesWrapper
	{
		List<sObject> messages;
		Map<String, Integer> messageCountMap;

		public MessagesWrapper(List<sObject> msgs) 
		{
			this.messages = msgs;
			this.messageCountMap = CreateMessageController.getMessageCountsMap();
		}
	}
}
public with sharing class MessageService {
	private List<MessageWrapper> wraps = new List<MessageWrapper>();

	public class MessageWrapper {
		public Message__c message;

		public List<Message_Recipient__c> recipients;

		public MessageWrapper(Message__c message) {
			this.message = message;
		}

		public MessageWrapper(Message__c message, List<Message_Recipient__c> recipients) {
			this.message = message;
			this.recipients = recipients;
		}
	}

	public void addMessage(Message__c message, List<Message_Recipient__c> recipients) {
		Map<String, Message_Recipient__c> uniqueRecipients = new Map<String, Message_Recipient__c>();

		for (Message_Recipient__c recipient : recipients) {
			if (recipient.User__c != null) {
				uniqueRecipients.put(recipient.User__c, recipient);
			}

			if (recipient.Group_Membership__c != null) {
				uniqueRecipients.put(recipient.Group_Membership__c, recipient);
			}
		}

		if (message.Body__c != '') {
			message.Search_Body__c = parseBody(message.Body__c);
		}

		MessageWrapper wrap = new MessageWrapper(message, uniqueRecipients.values());

		wraps.add(wrap);
	}

	public void sendMessages() {
		if (wraps.size() > 0) {
			Map<Integer, Message__c> messagesWithout = new Map<Integer, Message__c>();

			Map<Integer, List<Message_Recipient__c>> recipientsWithout = new Map<Integer, List<Message_Recipient__c>>();

			List<Message_Recipient__c> recipients = new List<Message_Recipient__c>();

			Integer order = 0;

			for (MessageWrapper wrap : wraps) {
				messagesWithout.put(order, wrap.message);
				recipientsWithout.put(order, wrap.recipients);
			}

			List<Database.SaveResult> messagesResult = Database.insert(messagesWithout.values(), true);

			for (Database.SaveResult result : messagesResult) {
				if (!result.isSuccess()) {
					System.debug('ERROR');
				}
			}

			Set<String> groupIds = new Set<String>();

			for (List<Message_Recipient__c> recipientList : recipientsWithout.values()) {
				for (Message_Recipient__c recipient : recipientList) {
					groupIds.add(recipient.Group_Membership__c);
				}
			}

			Map<Id, Group__c> groupMembership = getGroupMemberships(groupIds);

			for (Integer messageOrder : messagesWithout.keySet()) {
				Id messageId = messagesWithout.get(messageOrder).Id;

				if (recipientsWithout.get(messageOrder) != null && recipientsWithout.get(messageOrder).size() > 0) {
					List<Message_Recipient__c> updateRecipients = recipientsWithout.get(messageOrder);

					for (Message_Recipient__c recipient : updateRecipients) {
						if (recipient.Group_Membership__c != null && groupMembership.get(recipient.Group_Membership__c) != null) {
							Group__c thisGroup = groupMembership.get(recipient.Group_Membership__c);

							if (thisGroup.Staff_Group_Members__r.size() > 0) {
								for (Staff_Group_Member__c member : thisGroup.Staff_Group_Members__r) {
									Message_Recipient__c newRecipient = new Message_Recipient__c(User__c = member.Staff_Member__c, Message__c = messageId, Added_As_Group_Member__c = true, Added_Under_Group_Name__c = thisGroup.Name);

									recipients.add(newRecipient);
								}
							}
						} else {
							recipient.Message__c = messageId;
							recipients.add(recipient);
						}
					}
				}
			}

			List<Database.SaveResult> recipientsResult = Database.insert(recipients, true);

			for (Database.SaveResult result : recipientsResult) {
				if (!result.isSuccess()) {
					System.debug('ERROR');
				}
			}

			wraps.clear();
		}
	}

	public static Map<Id, Group__c> getGroupMemberships(Set<String> groupIds) {
		Map<Id, Group__c> groupMembership = new Map<Id, Group__c>([SELECT Name, (SELECT Staff_Member__c FROM Staff_Group_Members__r WHERE Start_Date__c <= TODAY AND (Planned_End_Date__c = NULL OR Planned_End_Date__c >= TODAY)) FROM Group__c WHERE Id IN :groupIds]);

		return groupMembership;
	}

	public static String sendQuickMessage(Message__c message, List<Message_Recipient__c> recipients) {
		String returnString = '';
		Map<String, Message_Recipient__c> uniqueRecipients = new Map<String, Message_Recipient__c>();

		if (message.Body__c != '') {
			message.Search_Body__c = parseBody(message.Body__c);
		}

		Savepoint sp = Database.setSavepoint();
		try {
			//Database.SaveResult messagesResult = Database.insert(message, true);
			insert message;

			//if (messagesResult.isSuccess()) {
			Set<String> groupIds = new Set<String>();

			for (Message_Recipient__c recipient : recipients) {
				groupIds.add(recipient.Group_Membership__c);
			}

			Map<Id, Group__c> groupMembership = getGroupMemberships(groupIds);

			for (Message_Recipient__c recipient : recipients) {
				recipient.Message__c = message.Id;

				if (recipient.User__c != null) {
					uniqueRecipients.put(recipient.User__c, recipient);
				}

				if (recipient.Group_Membership__c != null && groupMembership.get(recipient.Group_Membership__c) != null) {
					// JN added group recipient for reference 220914
					uniqueRecipients.put(recipient.Group_Membership__c, recipient);

					Group__c thisGroup = groupMembership.get(recipient.Group_Membership__c);
					if (thisGroup.Staff_Group_Members__r.size() > 0) {
						for (Staff_Group_Member__c member : thisGroup.Staff_Group_Members__r) {
							if (uniqueRecipients.get(member.Staff_Member__c) != null) {
								continue;
							}

							Message_Recipient__c newRecipient = new Message_Recipient__c(User__c = member.Staff_Member__c, Message__c = message.Id, Added_As_Group_Member__c = true, Added_Under_Group_Name__c = thisGroup.Name);

							uniqueRecipients.put(member.Staff_Member__c, newRecipient);
						}
					}
				}
			}
			// } else {
			// 	System.debug('RETURN ERROR: ' + messagesResult.getErrors());
			// }

			if (uniqueRecipients.size() > 0) {
				//List<Database.SaveResult> recipientsResult = Database.insert(uniqueRecipients.values(), true);
				insert uniqueRecipients.values();

				String pageRef = '' + '{' + ' type: \'comm__namedPage\',' + ' attributes: {' + ' name: \'testaccount__c\'' + ' }' + '}';
				Set<String> notifyUserIds = new Set<String>(uniqueRecipients.keySet());
				notifyUserIds.removeAll(groupIds);
				notifyRecipients(notifyUserIds, pageRef, message);

				// for (Database.SaveResult result : recipientsResult) {
				// 	if (!result.isSuccess()) {
				// 		System.debug('RETURN ERROR: ' + result.getErrors());
				// 		ProcessLogging.quickProcessLog('MessageService.sendMessages()', 'insert recipients SaveResults ' + message , result.getErrors()[0].getMessage());
				// 	}
				// }
			}
		} catch (Exception e) {
			Database.rollBack(sp);
			ProcessLogging.quickProcessLog('MessageService.sendQuickMessage', e.getStackTraceString(), 'RECIPIENTS: \n' + JSON.serialize(uniqueRecipients.values()) + '  \n\n' + e.getMessage());
			//returnString = e.getMessage();
			throw new CustomException(e.getMessage());
		}

		return returnString;
	}

	public static String parseBody(String body) {
		String searchBody = (body == null) ? '' : body.stripHtmlTags();

		Integer len = searchBody.length();

		if (len >= 254) {
			searchBody = searchBody.subString(0, 254);
		} else {
			searchBody = searchBody.subString(0, len);
		}

		return searchBody;
	}

	public static void notifyRecipients(Set<String> recipientsIds, String targetPageRef, Message__c message) {
		// Get the Id for our custom notification type
		// CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName='IRIS_Messaging_Notification'];

		// Create a new custom notification
		Messaging.CustomNotification notification = new Messaging.CustomNotification();

		// Set the contents for the notification
		notification.setTitle(message.Short_Notification_Message__c);
		notification.setBody(message.Subject__c);

		// Set the notification type and target
		notification.setNotificationTypeId('0ML2i00000001FRGAY');
		notification.setTargetPageRef(targetPageRef);

		// Actually send the notification
		try {
			notification.send(recipientsIds);
		} catch (Exception e) {
			System.debug('MessageService Problem sending notification: ' + e.getMessage());
		} finally {
			message.Notification_Sent__c = true;
			update message;
		}
	}
}
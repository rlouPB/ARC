/* eslint-disable no-undef */
/* eslint-disable no-else-return */
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
	fetch: function (component, searchTerm, page) {
		console.log("UserMessagesHelper fetch...");
		//let action = component.get("c.getMessages");
		let action = component.get("c.getMessagesWrapper");
		if (!action) 
		{
			//component.set("v.loading", false);
			return;
		}
		let inbox = (component.get('v.type') != 'Clinical Alert');
		let messageType = (inbox ? component.get("v.messageFilter") : component.get('v.alertFilter'));
		let messageProfile = component.get("v.messageProfileFilter");
		let unreadOnly = false;

		if (messageType === "Unread") {
			unreadOnly = true;
		}
		if (messageProfile === "AllTypes") {
			messageProfile = null;
		}

		let thisField = this.getField(component.get("v.sortField"), component.get("v.type"));

		component.set("v.loading", true);


		action.setParams({
			type: component.get("v.type"),
			searchTerm: searchTerm,
			page: page,
			sortAsc: component.get("v.sortAsc") ? "ASC" : "DESC",
			field: thisField,
			unreadOnly: unreadOnly,
			clientId: component.get("v.clientId"),
			messageProfile: messageProfile
		});

		action.setCallback(this, function (response) {
			let state = response.getState();

			if (state === "SUCCESS") {
				var messagesWrapper = JSON.parse(response.getReturnValue());
				//var messages = response.getReturnValue();
				var messages = messagesWrapper.messages;

				//force update of message counts on parent
				let e = $A.get("e.c:MessageResetPageEvent");
				e.setParams({
					messageCountMap: messagesWrapper.messageCountMap,
					type: component.get("v.type")
				});

				e.fire();

				if (component.get("v.type") === "Sent Messages" || component.get("v.clientId") !== "") {
					messages = messages.map((message) => {
						let recipient = message.Message_Recipients__r != null ? message.Message_Recipients__r.records[0] : null;

						let names =
							message.Message_Recipients__r != null
								? message.Message_Recipients__r.records.filter((r) => {
										if (r.User__c != null) return r;
									}).map((r) => {
										return r.User__r.Name;
									})
								: [];

						let sTo = recipient != null ? names.join(", ") : "";

						return {
							to: recipient != null ? names.join(", ") : "",
							id: recipient != null ? recipient.Id : message.Id,
							messageId: message.Id,
							read: true,
							fromId: message.CreatedById,
							from: message.CreatedBy.Name,
							subject: message.Subject__c,
							sent: message.CreatedDate,
							messageProfile: message.Message_Profile__c
						};
					});
				} else {
					messages = messages.map((message) => {
						return {
							id: message.Id,
							messageId: message.Message__c,
							read: message.Read__c,
							fromId: message.Message__c != null ? message.Message__r.CreatedById : message.createdById,
							from: message.Message__c != null ? message.Message__r.CreatedBy.Name : message.CreatedBy.Name,
							to: message.User__c != null ? message.User__r.Name : "",
							subject: message.Message__c != null ? message.Message__r.Subject__c : message.Subject__c,
							sent: message.Message__c != null ? message.Message__r.CreatedDate : message.CreatedDate,
							messageProfile: message.Message__c != null ? message.Message__r.Message_Profile__c : message.Message_Profile__c
						};
					});
				}

				component.set("v.data", messages);

				if (searchTerm === "") {
					component.set("v.allData", messages);
				}

				component.set("v.loading", false);
			} else if (state === "ERROR") {
				let errors = response.getError();

				component.find("notifLib").showToast({
					variant: "error",
					title: "Error!",
					message: errors[0].message
				});
			}
		});

		$A.enqueueAction(action);
	},

	deleteBin: function (component, ids) {
		console.log("UserMessagesHelper deleteBin...");
		component.set("v.loading", true);

		let action = component.get("c.deleteRecycleBin");

		action.setParams({
			messageReceiptIds: ids,
			clientUser: false
		});

		action.setCallback(this, function (response) {
			let state = response.getState();

			if (state === "SUCCESS") {
				component.set("v.data", []);

				component.set("v.allData", []);

				component.set("v.loading", false);

				component.find("notifLib").showToast({
					variant: "success",
					title: "Success!",
					message: "Recycle Bin Emptied"
				});
			} else if (state === "ERROR") {
				let errors = response.getError();

				component.find("notifLib").showToast({
					variant: "error",
					title: "Error!",
					message: "Error. Please check log."
				});
			}
		});

		$A.enqueueAction(action);
	},

	getField: function (field, type) {
		console.log("UserMessagesHelper getField...");
		switch (field) {
			case "to":
				if (type === "Standard Message") {
					return "User__r.Name";
				}
				return "Name";
			// break;
			case "from":
				if (type === "Deleted Messages") {
					return "CreatedBy.Name";
				}
				return "Message__r.CreatedBy.Name";
			case "subject":
				if (type === "Standard Message") {
					return "Message__r.Subject__c";
				}
				return "Subject__c";
			// break;
			case "sent":
				return "CreatedDate";
			case "messageProfile":
				if (type === "Standard Message") {
					return "Message__r.Message_Profile__c";
				}
				return "Message_Profile__c";
			default:
				return "CreatedDate";
		}
	},

	getMessageCounts: function (component) {
		console.log("UserMessagesHelper getMessageCounts...");
		let action = component.get("c.getMessageCountsMap");

		action.setCallback(this, function (response) {
			let state = response.getState();

			if (state === "SUCCESS") {
				var countMap = response.getReturnValue();
			} else if (state === "ERROR") {
				let errors = response.getError();
			}
		});

		$A.enqueueAction(action);
	},

	handleEvent: function (component, received) {
		console.log("UserMessagesHelper handleEvent...");
		let payload = received.data.payload;
		let recipient = payload.Recipient__c;
		let messageType = payload.Message_Type__c;
		this.fetch(component, "", 0);
	},

	sendPreviewEvent: function (component, id, read) {
		console.log("UserMessagesHelper sendPreviewEvent...");
		let e = $A.get("e.c:MessagePreviewEvent");

		e.setParams({
			id: id,
			messageType: component.get("v.type"),
			clientId: component.get("v.clientId"),
			isRead: read,
			update: true,
			page: component.get("v.page")
		});

		e.fire();
	},

	sendUnreadEvent: function (type, count) {
		console.log("ViewMessageHelper sendUnread...");
		let e = $A.get("e.c:MessageUnreadEvent");

		e.setParams({
			count: count,
			type: type
		});

		e.fire();
	},

	showMessageModal: function (component, message) {
		console.log("UserMessagesHelper showMessageModal...");
		// component.set("v.showModal", true);
		var createMessage;
		var createMessageFooter;
		// var createClientMessage;
		// var createClientMessageFooter;
		// var createFamilyMessage;
		// var createFamilyMessageFooter;

		let thisMessage = message;

		// if (thisMessage.messageProfile === "Patient") {
		// 	$A.createComponents(
		// 		[["c:CreateClientMessage", { type: component.get("v.type") }], ["c:CreateClientMessageFooter"]],
		// 		function (components, status) {
		// 			if (status === "SUCCESS") {
		// 				createClientMessage = components[0];
		// 				createClientMessageFooter = components[1];

		// 				component.find("overlayLibUserMsg").showCustomModal({
		// 					header: "Create " + thisMessage.messageProfile + "-Focused Message",
		// 					footer: createClientMessageFooter,
		// 					body: createClientMessage,
		// 					showCloseButton: false,
		// 				});
		// 			}
		// 		}
		// 	);
		// } else if (thisMessage.messageProfile === "Family") {
		// 	$A.createComponents(
		// 		[["c:CreateFamilyMessage", { type: component.get("v.type") }], ["c:CreateFamilyMessageFooter"]],
		// 		function (components, status) {
		// 			if (status === "SUCCESS") {
		// 				createFanilyMessage = components[0];
		// 				createFamilyMessageFooter = components[1];

		// 				component.find("overlayLibUserMsg").showCustomModal({
		// 					header: "Create " + thisMessage.messageProfile + "-Focused Message",
		// 					footer: createFamilyMessageFooter,
		// 					body: createFamilyMessage,
		// 					showCloseButton: false,
		// 				});
		// 			}
		// 		}
		// 	);
		// } else if (thisMessage.messageProfile === "Staff") {
		$A.createComponents([["c:CreateMessage", message], ["c:CreateMessageFooter"]], function (components, status) {
			if (status === "SUCCESS") {
				createMessage = components[0];
				createMessageFooter = components[1];

				component.find("overlayLibUserMsg").showCustomModal({
					header: "Create Message",
					footer: createMessageFooter,
					body: createMessage,
					showCloseButton: false
				});
			}
		});
		// }
	},

	showViewMessageModal: function (component, message) {
		console.log("UserMessagesHelper showViewMessageModal...");
		console.log("UserMessagesHelper showViewMessageModal message: " + JSON.stringify(message));
		var createMessage;

		$A.createComponents([["c:ViewMessage", message]], function (components, status) {
			if (status === "SUCCESS") {
				createMessage = components[0];

				var modalPromise = component.find("overlayLibUserMsg").showCustomModal({
					body: createMessage,
					showCloseButton: true
				});
				
				component.set("v.modalPromise", modalPromise);
			}
		});
	},

	sortBy: function (component, field, sortDirection) {
		console.log("UserMessagesHelper sortBy...");
		let sortAsc = component.get("v.sortAsc");
		let sortField = component.get("v.sortField");
		let data = component.get("v.data");

		if (sortDirection) {
			sortAsc = sortDirection === "ASC" ? true : false;
		} else {
			sortAsc = sortField !== field || sortAsc === false;
		}

		component.set("v.sortAsc", sortAsc);
		component.set("v.sortField", field);
		component.set("v.data", data);

		let e = $A.get("e.c:MessageResetPageEvent");

		e.setParams({
			page: 0,
			type: component.get("v.type")
		});

		e.fire();

		this.fetch(component, component.get("v.searchTerm"), 0);
	},

	subscribe: function (component, event) {
		console.log("UserMessagesHelper subscribe...");
		const empApi = component.find("empApi");

		empApi.onError(
			$A.getCallback((error) => {
				console.error("EMP API error: ", error);
			})
		);

		const channel = "/event/SentMessageEvent__e";

		const replayId = -1;

		empApi
			.subscribe(
				channel,
				replayId,
				$A.getCallback((eventReceived) => {
					this.handleEvent(component, eventReceived);
				})
			)
			.then((subscription) => {
				console.log("Subscribed to channel ", subscription.channel);
			});
	},

	updateStatus: function (component, type, id, value, isPreview) {
		console.log("UserMessagesHelper updateStatus...");
		let action = component.get("c.updateStatus");

		action.setParams({
			messageRecipientId: id,
			updateType: type,
			value: value
		});

		action.setCallback(this, function (response) {
			let state = response.getState();

			if (state === "SUCCESS") {
				if (type === "Delete" || type === "UnDelete") {
					let data = component.get("v.data").filter((message) => message.id !== id);
					component.set("v.data", data);

					let alertsUnread = 0;
					let msgsUnread = 0;
					data.forEach((element) => {
						if (type === "Standard Message") {
							if (!element.read) {
								msgsUnread = msgsUnread + 1;
							}
						} else {
							if (!element.read) {
								alertsUnread = alertsUnread + 1;
							}
						}
					});

					component.set("v.unreadAlerts", alertsUnread);
					component.set("v.unreadMessages", msgsUnread);

					// if (type === "Standard Message") {
					//   this.sendUnreadEvent(type, component.get("v.unreadMessages"));
					// } else {
					//   this.sendUnreadEvent(type, component.get("v.unreadAlerts"));
					// }
				}

				if (type === "Delete") {
					let data = component.get("v.data");

					component.find("notifLib").showToast({
						variant: "success",
						title: "Success!",
						message: "Message Deleted"
					});
					component.set("v.data", data);
					//component.find('overlayLibUserMsg').notifyClose();
					// component.get("v.modalPromise").then(function (modal) {
					// 	modal.close();
					// });
					var modalPromise = component.get("v.modalPromise");
					if (modalPromise)
					{
						modalPromise.then(function (modal) {
							modal.close();
						});
					}
				}

				if (type === "UnDelete") {
					let data = component.get("v.data");

					component.find("notifLib").showToast({
						variant: "success",
						title: "Success!",
						message: "Message Undeleted"
					});

					component.set("v.data", data);
					var modalPromise = component.get("v.modalPromise");
					if (modalPromise)
					{
						modalPromise.then(function (modal) {
							modal.close();
						});
					}
				}

				if (type === "Read") {
					let data = component.get("v.data").map((message) => {
						if (message.id === id) {
							message.read = value;
						}

						return message;
					});

					component.set("v.data", data);
				}

				if (isPreview) {
					this.sendPreviewEvent(component, id, true);
				}
			}
		});

		$A.enqueueAction(action);
	}
});
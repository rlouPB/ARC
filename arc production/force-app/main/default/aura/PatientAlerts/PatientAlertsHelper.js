/* eslint-disable no-unused-expressions */
({
	subscribe: function (cmp, event) {
		console.log("patientLogicPath20 PatientAlertsHelper subscribe...");
		const empApi = cmp.find("empApi");

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
					this.check(cmp, eventReceived);
				})
			)
			.then((subscription) => {
				console.log("patientLogicPath20 PatientAlertsHelper subscribed to channel ", subscription.channel);
			});
	},
	check: function (cmp, received) {
		console.log("patientLogicPath20 PatientAlertsHelper check...");
		let payload = received.data.payload;

		let messageType = payload.Message_Type__c;

		let unread = cmp.get("v.unread");

		if (messageType == "Clinical Alert") {
			let patient = payload.Patient__c; // recordId

			if (patient == cmp.get("v.recordId")) {
				unread = unread + 1;

				cmp.set("v.unread", unread);

				cmp.set("v.badgeMessage", "Unread Alerts" + " (" + unread + ")");

				let e = $A.get("e.c:MessageEvent");

				e.setParams({
					type: "REFRESH_ALERT",
				});

				e.fire();
			}
		}
	},
	showMessageModal: function (cmp, type) {
		console.log("patientLogicPath20 PatientAlertsHelper showMessageModal...");
		var createMessage;
		var createMessageFooter;

		$A.createComponents(
			[["c:CreateMessage", { type: type, patientId: cmp.get("v.recordId") }], ["c:CreateMessageFooter"]],
			function (components, status) {
				if (status === "SUCCESS") {
					createMessage = components[0];
					createMessageFooter = components[1];

					cmp.find("overlayLib").showCustomModal({
						header: "Create Message",
						footer: createMessageFooter,
						body: createMessage,
						showCloseButton: false,
					});
				}
			}
		);
	},
});
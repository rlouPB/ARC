/* eslint-disable no-unused-expressions */
({
	handleDiscard: function (cmp, event, helper) {
		console.log("patientLogicPath20 MessageConfirmationController handleDiscard...");

		let e = $A.get("e.c:MessageEvent");

		e.setParams({
			type: "Cancel",
		});

		e.fire();

		cmp.find("overlayLibMsgConfirm").notifyClose();
	},

	handleBack: function (cmp, event, helper) {
		console.log("patientLogicPath20 MessageConfirmationController handleBack...");
		cmp.find("overlayLibMsgConfirm").notifyClose();
	},

	handleMessageEvent: function (cmp, event) {
		console.log("patientLogicPath20 MessageConfirmationController handleMessageEvent...");
		console.log("patientLogicPath20 MessageConfirmationController handleMessageEvent params: " + JSON.stringify(event.getParams()));
	},
});
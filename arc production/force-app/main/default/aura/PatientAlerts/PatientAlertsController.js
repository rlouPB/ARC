({
	init: function (cmp, event, helper) {
		console.log("patientLogicPath20 PatientAlertsController init...");
		let user = $A.get("$SObjectType.CurrentUser.Id");
		cmp.set("v.activeUser", user);
		cmp.set("v.badgeMessage", "No Unread Alerts");

		helper.subscribe(cmp, event);
	},
	onChangeSearchText: function (cmp, event) {
		console.log("patientLogicPath20 PatientAlertsController onChangeSearchText...");
		let container = event.target.id;

		var queryTerm = cmp.find(`${container}-search`).get("v.value");

		if (queryTerm != "" && queryTerm.length <= 2) return;

		cmp.set(`v.${container}Searching`, true);

		let box = cmp.find(container);
		let result = box.searchInbox(queryTerm);

		cmp.set(`v.${container}Searching`, result);
	},

	updateAlertFilter: function (cmp, event, helper) {
		console.log("patientLogicPath20 PatientAlertsController updateAlertFilter...");
		let type = event.getSource().get("v.value");
		cmp.set("v.alertFilter", type);

		let alert = cmp.find("alert");
		alert.filterMessages(type);
	},

	handleClinicalAlert: function (cmp, event, helper) {
		console.log("patientLogicPath20 PatientAlertsController handleClinicalAlert...");
		helper.showMessageModal(cmp, "Clinical Alert");
	},

	handleMessageEvent: function (cmp, event) {
		console.log("patientLogicPath20 PatientAlertsController handleMessageEvent...");
		console.log("patientLogicPath20 PatientAlertsController handleMessageEvent params: " + JSON.stringify(event.getParams()));
	},
});
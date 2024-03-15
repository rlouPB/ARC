/* eslint-disable no-unused-expressions */
({
	doInit: function (component, event, helper) {
		console.log("PatientNoteController doInit...");
		console.log("$$$$ record Id ---> ", component.get("v.recordId"));
		helper.getUser(component, helper);
		helper.getNote(component, helper);
		helper.getGroup(component, helper);
		// helper.getCanFinalize(component, helper);
	},

	handleSaveNote: function (component, event, helper) {
		console.log("PatientNoteController handleSaveNote...");
		helper.showSpinner(component);
		helper.saveNote(component, helper);
	},

	handleAutoSaveNote: function (component, event, helper) {
		console.log("PatientNoteController handleAutoSaveNote...");
		// helper.showSpinner(component);
		helper.autoSaveNote(component, helper);
	},
	reopenConfirmation: function (component, event, helper) {
		component.set("v.showReOpenConfirmationModal", true);
	},
	closeReOpenModelConfirm: function (component, event, helper) {
		component.set("v.showReOpenConfirmationModal", false);
	},
	
	// reopen: function (component, event, helper) {
	// 	console.log("PatientNoteController reopen...");
	// 	component.set("v.showReOpenConfirmationModal", false);
	// 	let patientNote = component.get("v.patientNote");
	// 	window.open("/" + patientNote.patientNote.Id);
	// 	helper.showSpinner(component);
	// 	helper.reopen(component).then($A.getCallback(function()
    //     {
	// 		let patientNote = component.get("v.patientNote");
	// 		helper.hideSpinner(component);
    //         window.open("/" + patientNote.patientNote.Id);
    //     }))
	// },
	reopen: function (component, event, helper) {
		console.log("PatientNoteController reopen...");
		component.set("v.buttonLabel", "Re-Open");
		let popup = component.find("popup");
		popup.confirm("Are you sure you want to Re-Open this patient note?", "Re-Open Patient Note", "WARN").then(
			$A.getCallback(function (result) {
				if (result) {
					helper.showSpinner(component);
					helper.reopen(component);
					//var status = "Draft";
					var status = "Reopen";
					helper.saveNote(component, helper, status);
				}
			})
		);
	},
	completeNote: function (component, event, helper) {
		console.log("PatientNoteController completeNote...");
		if (!helper.areRequiredFieldsValid(component, helper))
		{
			helper.showCustomToast(component, {
				type: "error",
				title: "Required Fields",
				message: "Please fill in the required fields",
			});
			helper.hideSpinner(component);
		} else 
		{
			component.set("v.buttonLabel", "Complete");
			let popup = component.find("popup");
			popup.confirm("Are you sure you want to Complete this patient note?", "Complete Patient Note", "WARN").then(
				$A.getCallback(function (result) {
					if (result) {
						helper.showSpinner(component);
						var status = "Complete";
						helper.saveNote(component, helper, status);
					}
				})
			);
		}
	},
	finalizeNote: function (component, event, helper) {
		console.log("PatientNoteController finalizeNote...");
		if (!helper.areRequiredFieldsValid(component, helper))
		{
			helper.showCustomToast(component, {
				type: "error",
				title: "Required Fields",
				message: "Please fill in the required fields",
			});
			helper.hideSpinner(component);
		} else 
		{
			component.set("v.buttonLabel", "Finalize");
			let popup = component.find("popup");
			popup.confirm("Are you sure you want to finalize this patient note?", "Finalize Patient Note", "WARN").then(
				$A.getCallback(function (result) {
					if (result) {
						helper.showSpinner(component);
						var status = "Finalize";
						helper.saveNote(component, helper, status);
					}
				})
			);
		}
	},
	cancelNote: function (component, event, helper) {
		component.set("v.buttonLabel", "Discard Note");
		let popup = component.find("popup");
		popup.confirm("Are you sure you want to throw away this patient note?", "Permanently Discard Patient Note", "WARN").then(
			$A.getCallback(function (result) {
				if (result) {
					helper.showSpinner(component);
					var status = "Cancelled";
					var patientNote = component.get("v.patientNote");
					patientNote.patientNote['Status__c'] = status;
					component.set("v.patientNote.patientNote", patientNote.patientNote);
					helper.saveNote(component, helper, status);
				}
			})
		);
	},
	handleNoteChanged: function (component, event, helper) {
		console.log("PatientNoteController handleNoteChanged...");
		// console.log('handleNoteChanged in PatientNote');
		var changedFields = event.getParam("changedFields");
		var patientNote = component.get("v.patientNote");
		var updatedPatientNoteFields = false;
		changedFields.forEach((element) => {
			if (patientNote.patientNote[element.field] != element.value) 
			{
				patientNote.patientNote[element.field] = element.value;
				updatedPatientNoteFields = true;
			}
		});
		patientNote.lastChangedFields = changedFields;
		component.set("v.patientNote.patientNote", patientNote.patientNote);
		if (updatedPatientNoteFields)
		{
			if (!component.get('v.isValid')) //if failed validation recently
			{
				if (helper.areRequiredFieldsValid(component, helper))
				{
					helper.hideCustomToast(component);
				}
			}
			component.set('v.isSaveDisabled', false);
			component.set('v.ASMessage', '');
			// helper.hideCustomToast(component);
			if (component.get("v.firstChange") == true) 
			{
				component.set("v.firstChange", false);
			} else {
				var asComp = component.find("autosaveComp");
				var timeoutId = asComp.get("v.timeoutId");
				if(!timeoutId) 
				{
					console.log('patientnote starting autosave timer');
					asComp.autosaveOn();
				}
			}
		}
	},
	handleCloseConfirmationModal: function (component, event, helper) {
		console.log("PatientNoteController handleCloseConfirmationModal...");
		component.set("v.showConfirmationModal", false);
	},
	handleOpenNewTab: function (component, event, helper) {
		console.log("PatientNoteController handleOpenNewTab...");
		let patientNote = component.get("v.patientNote");
		window.open("/" + patientNote.patientNote.Id);
	},
	handleStandardMessage: function (cmp, event, helper) {
		console.log("PatientNoteController handleStandardMessage...");
		helper.showMessageModal(cmp, "Standard Message", true);
	},
	handleAlert: function (cmp, event, helper) {
		console.log("PatientNoteController handleAlert...");
		helper.showMessageModal(cmp, "Clinical Alert", false);
	},
	handlePrint: function (component, event, helper) {
		console.log("PatientNoteController handlePrint...");
		let patientNote = component.get("v.patientNote");
		//let urlval = "/apex/SDOC__SDCreate1?id="+ patientNote.patientNote.Id +"&Object=Patient_Note__c&doclist=Patient Note&autoopen=0";
		let urlval = patientNote.patientNote.Print_Link__c.split('"')[1].replaceAll("&amp;", "&");
		window.open(urlval, "_blank");
	},

	// LMS HANDLERS
	handleMessage: function (component, message) {
		console.log("PatientNoteController handleMessage...");
		if (message != null && message.getParam("lmsData") != null) {
			component.set("v.messageRecieved", message.getParam("lmsData").value);
		}
	},
	inputHandler: function (component, event) {
		console.log("PatientNoteController inputHandler...");
		// console.log(event.target.value)
		component.set("v.messageValue", event.target.value);
	},
	publishMessage: function (component) {
		console.log("PatientNoteController publishMessage...");
		let msg = component.get("v.messageValue");
		let message = {
			lmsData: {
				value: msg,
			},
		};
		component.find("SampleMessageChannel").publish(message);
	},
});
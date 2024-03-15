/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
	getUser: function (component, helper) {
		// console.log("PatientNoteHelper getUser...");
		let me = this;
		var userId = $A.get("$SObjectType.CurrentUser.Id");
		helper.callApexMethod(
			component,
			"getUser",
			{
				userId: userId,
			},
			function (result) {
				// console.log("User " + JSON.stringify(result));
				component.set("v.requiresCoSign", result.Requires_Co_Signature__c);
				component.set("v.currentUser", result);
				// console.log(
				//   "**** currentUserId ---> ",
				//   component.get("v.currentUser.Id")
				// );
				helper.hideSpinner(component);
			},
			function (errorcallback) {
				helper.hideSpinner(component);
			}
		);
	},
	getNote: function (component, helper, isDraftSaveResult) {
		// console.log("PatientNoteHelper getNote...");
		let me = this;
		this.callApexMethod(
			component,
			"getNote",
			{
				patientNoteId: component.get("v.recordId"),
			},
			function (result) {
				// console.log("result " + JSON.stringify(result));

				// var parameters = JSON.stringify(JSON.parse(result.noteDefinition.Parameters__c));
				// if (!component.get('v.sidebarParams'))
				// {
					result.noteDefinition.Parameters__c = result.noteDefinition.Parameters__c
						? JSON.parse(result.noteDefinition.Parameters__c)
						: {};
					var sidebarParams = {};
					if (result.noteDefinition.Parameters__c.sidebar) {
						sidebarParams = JSON.parse(JSON.stringify(result.noteDefinition.Parameters__c.sidebar));
					}
					component.set("v.sidebarParams", sidebarParams);
				// }
				if (result.noteDefinition.DeveloperName == "Medication_SelfAdmininstration_MSA_Order") {
					component.set("v.NoteType", "MSA");
				} else if (result.noteDefinition.DeveloperName == "Away_Discharge_Med_Order") {
					component.set("v.NoteType", "AWAY");
				}

				if (isDraftSaveResult) {
					//copy in LastModifiedDate and a few other fields, don't overwrite anything else
					helper.updateAuditFields(component, helper, result);
				} else {
					helper.updateFields(component, helper, result);
				}

				// var imageUrl =
				// 	"/sfc/servlet.shepherd/version/download/" +
				// 	result.patientNote.Account__r.Photo_Version_Id__c +
				// 	"?t=" +
				// 	new Date().getTime();
				// component.set("v.imageUrl", imageUrl);

				helper.getCanFinalize(component, helper);
				component.set("v.canSeeCompleteButton", result.canSeeCompleteButton);
			},
			function (error) {
				// component.find('notifLib').showToast({
				// 	'title': 'Error while loading the Patient Note.',
				// 	'message': error,
				// 	'variant': 'error',
				// 	'mode': 'dismissable'
				// });
				helper.showCustomToast(component, {
					type: "error",
					title: "Error while loading the Patient Note.",
					message: error,
				});
				helper.hideSpinner(component);
			},
			!isDraftSaveResult //show spinner only for manual save
		);
	},
	reopen: function (component) {
		let self = this;
		return new Promise(
			$A.getCallback(function (resolve, reject) {
				let patientNote = component.get("v.patientNote");
				let action = component.get("c.reopenNote");
				action.setParams({ 	
					patientNoteId : patientNote.patientNote.Id,
					patientStatus : "Draft"	 
				});
				action.setCallback(self, (resp) => {
					if (resp.getState() == "SUCCESS") {
						
					} else if (resp.getState() == "ERROR") {
						
					}
				});
				$A.enqueueAction(action);
			})
		);
	},
	saveNote: function (component, helper, status) {
		// console.log("PatientNoteHelper saveNote...");
		
		if (component.get('v.isSaveDisabled')) 
		{
			// console.log('Save disabled. aborting manual save');
			// var asComp = component.find("autosaveComp");
			// asComp.autosaveOff();
			// component.set("v.firstChange", true);
			helper.hideSpinner(component);
			return;
		}

		if (status != 'Cancelled' && status != 'Reopen' 
				&& !helper.areRequiredFieldsValid(component, helper)) 
		{
			helper.showCustomToast(component, {
				type: "error",
				title: "Required Fields",
				message: "Please fill in the required fields",
			});
			helper.hideSpinner(component);
		} else {
			
			component.set('v.isSaveDisabled', true);
			let me = this;
			var note = component.get("v.patientNote");
			var errorMessage = "There was an error updating the Note.";
			var successMessage = "Successfully updated the Note.";
			if (!status || status == 'Reopen') 
			{
				status = "Draft";
			}

			if ($A.util.isObject(note.patientNote.Owner)) {
				delete note.patientNote.Owner;
			}
			
			this.callApexMethod(
				component,
				"saveNote",
				{
					patientNoteJSON: JSON.stringify(note.patientNote),
					newStatus: status,
				},
				function (result) {
					if (result === "success") {
						helper.hideCustomToast(component);
						component.find("notifLib").showToast({
							title: "Success!",
							message: successMessage,
						});
						component.set("v.status", status);
						if (status == "Completed" || status == "Finalized" || status == "Complete" || status == "Finalize") {
							component.set("v.readOnly", true);
						}
						component.set('v.ASMessage', '');
						// Sending message to scriptsurelwc to update prescriptions.
						let message = {
							lmsData: {
								value: "Save Prescriptions",
							},
						};
						component.find("SampleMessageChannel").publish(message);
						// this.callApexMethod(
						//   component,
						//   "updatePrescription",
						//   {
						//     patientNoteJSON: JSON.stringify(note.patientNote),
						//     newStatus: status
						//   },
						//   function (result) {},
						//   function (error) {
						//     helper.showCustomToast(component, {
						//       type: "error",
						//       title: "Error while saving a record",
						//       message: error
						//     });
						//     helper.hideSpinner(component);
						//   },
						//   true
						// );

						helper.getNote(component, helper);
						//$A.get('e.force:refreshView').fire();
					} else {
						if (result === "Patient Note is already finalized.") 
						{
							helper.showCustomToast(component, {
								type: "error",
								title: 'Problem Saving',
								message: result,
							});
							helper.getNote(component, helper);
						} else if ( result === "This Patient Note has been changed in a different session. To avoid overwriting changes, please edit the current version") 
						{
							component.set("v.showConfirmationModal", true);
							component.set("v.showErrorMessage", true);
							helper.hideSpinner(component);
						} else {
							helper.showCustomToast(component, {
								type: "error",
								title: 'Problem Saving',
								message: result,
							});
							helper.hideSpinner(component);
						}
						helper.hideSpinner(component);
					}

					// removed JN 221013, should be same behavior as Save or Finalize (was if Completed navigate to Patient Account)
					// if (status == "Complete") {
					// 	var navEvent = $A.get("e.force:navigateToSObject");
					// 	navEvent.setParams({
					// 		recordId: component.get("v.patientNote.patientNote").Account__c,
					// 		slideDevName: "detail",
					// 	});
					// 	navEvent.fire();
					// }
					component.set('v.isSaveDisabled', false);
				},
				function (error) {
					helper.showCustomToast(component, {
						type: "error",
						title: "Error while saving a record",
						message: error,
					});
					helper.hideSpinner(component);
					component.set('v.isSaveDisabled', false);
				},
				true
			);

			var asComp = component.find("autosaveComp");
			// console.log("Turn off autosave");
			asComp.autosaveOff();
			component.set("v.firstChange", true);
		}
	},
	autoSaveNote: function (component, helper, status) {
		// console.log("PatientNoteHelper autoSaveNote...");
		if (component.get('v.isSaveDisabled')) 
		{
			console.log('Save disabled. aborting autosave');
			var asComp = component.find("autosaveComp");
			asComp.autosaveOff();
			component.set("v.firstChange", true);
			return;
		}
		component.set('v.isSaveDisabled', true);
		var note = component.get("v.patientNote");
		component.set('v.ASMessage', 'Autosaving...');
		// component.find("autosaveComp").set('v.autoSaveMessage', 'Autosaving...');
		if (!status) {
			status = "Draft";
		}
		if ($A.util.isObject(note.patientNote.Owner)) 
		{
			delete note.patientNote.Owner;
		}
		
		this.callApexMethod(
			component,
			"saveNote",
			{
				patientNoteJSON: JSON.stringify(note.patientNote),
				newStatus: status,
			},
			function (result) {
				if (result === "success") {
					component.set("v.status", status);
					if (status == "Completed" || status == "Finalized" || status == "Complete" || status == "Finalize") {
						component.set("v.readOnly", true);
					}
					helper.hideCustomToast(component);
					component.set("v.ASMessage", "Saved!");
					helper.getNote(component, helper, true);
				} else {
					if (result === "This Patient Note has been changed in a different session. To avoid overwriting changes, please edit the current version") 
					{
						component.set("v.showConfirmationModal", true);
					} else {
						// component.find('notifLib').showToast({
						// 	'title': 'Erro Message during Auto-Save',
						// 	'message': result,
						// 	'variant': 'error',
						// 	'mode': 'dismissable'
						// });
						helper.showCustomToast(component, {
						    'type': 'error',
						    'title': 'Error Message during Auto-Save',
						    'message': result
						});
					}
					component.set("v.ASMessage", "Problem Saving!");
				}
				component.set('v.isSaveDisabled', false);
			},
			function (error) {
				// component.find('notifLib').showToast({
				// 	'title': 'Exception during Auto-Save',
				// 	'message': error,
				// 	'variant': 'error',
				// 	'mode': 'dismissable'
				// });
				helper.showCustomToast(component, {
				    'type': 'error',
				    'title': 'Exception during Auto-Save',
				    'message': error
				});
				component.set("v.ASMessage", "Problem Saving!");
				component.set('v.isSaveDisabled', false);
			},
			false
		);

		var asComp = component.find("autosaveComp");
		asComp.autosaveOff();
		component.set("v.firstChange", true);
	},
	updateFields: function (component, helper, result) {
		// console.log("PatientNoteHelper updateFields...");
		// console.log("PatientNoteHelper updateFields...");

		let me = this;
		var parameters = result.noteDefinition.Parameters__c;
		//component.set('v.parameters', result.noteDefinition.Parameters__c);
		var patientNote = result;
		// console.log("parameters before update " + JSON.stringify(parameters));
		if (parameters.header && parameters.header.fieldNames) {
			parameters.header.fieldNames.forEach((element) => {
				if (element.fieldName && !element.source) {
					var value = element.fieldName
						.split(".")
						.reduce((a, b) => (typeof a == "undefined" || a === null ? a : a[b]), patientNote.patientNote);
					element.value = value;
				}
			});
		}
		if (parameters.sidebar && parameters.sidebar.fieldNames) {
			parameters.sidebar.fieldNames.forEach((element) => {
				if (element.fieldName && !element.source) {
					var value = element.fieldName
						.split(".")
						.reduce((a, b) => (typeof a == "undefined" || a === null ? a : a[b]), patientNote.patientNote);
					element.value = value;
				}
			});
		}
		if (parameters.footer && parameters.footer.fieldNames) {
			parameters.footer.fieldNames.forEach((element) => {
				if (element.fieldName && !element.source) {
					var value = element.fieldName
						.split(".")
						.reduce((a, b) => (typeof a == "undefined" || a === null ? a : a[b]), patientNote.patientNote);
					element.value = value;
				}
			});
		}

		if (patientNote.noteItems) {
			patientNote.noteItems.forEach((element) => {
				//if(element.noteItem.Field_Name__c)
				if (element.noteItem.Type__c == "Field" && element.noteItem.Field_Name__c) {
					var value = element.noteItem.Field_Name__c.split(".").reduce((a, b) => a[b], patientNote.patientNote);
					if (element.value != value) {
						element.value = value;
					}
				}
			});
		}
		// console.log("parameters after update " + JSON.stringify(parameters));
		// console.log(
		//   "patientNote.noteItems after update " +
		//     JSON.stringify(patientNote.noteItems)
		// );
		component.set("v.parameters", parameters);
		component.set("v.patientNote", patientNote);

		// console.log(
		//   "PatientNoteHelper updateFields v.patientNote: " +
		//     JSON.stringify(component.get("v.patientNote"))
		// );

		var status = patientNote.patientNote.Status__c;
		// if(null != status && 'Finalized' == status) {
		//     var navEvent = $A.get("e.force:navigateToSObject");
		//     navEvent.setParams({
		//         recordId: 'a382i0000006pytAAA',
		//         //recordId: component.get("v.objSobject").Id,
		//         slideDevName: "detail"
		//     });
		//     navEvent.fire();
		// }

		component.set("v.status", status);
		if (null != patientNote.patientNote.Snapshot__c) {
			// console.log("======== PATIENT NOTE NOTES DEFINITION", patientNote.patientNote.Snapshot__c);
			var snapshotHtml = patientNote.patientNote.Snapshot__r.Html__c;
			component.set("v.snapshotHtml", snapshotHtml);
		}
		if (status == "Completed" || status == "Finalized") {
			component.set("v.readOnly", true);
		}
		component.set("v.showSpinner", false);
	},
	updateAuditFields: function (component, helper, newPatientNote) {
		// console.log("PatientNoteHelper updateAuditFields...");
		var auditFields = [
			"LastModifiedDate",
			"LastModifiedBy",
			"Completed_Date_Time__c",
			"Completed_By__c",
			"Finalized_Date_Time__c",
			"Finalized_By__c",
			"Status__c",
		];
		
		var oldPatientNote = component.get("v.patientNote.patientNote");
		auditFields.forEach((element) => {
			if (newPatientNote.patientNote[element]) {
				oldPatientNote[element] = newPatientNote.patientNote[element];
			}
		});
		component.set("v.patientNote.patientNote", oldPatientNote);
	},
	showMessageModal: function (cmp, type, showUser) {
		// console.log("PatientNoteHelper showMessageModal...");

		var createMessage;
		var createMessageFooter;

		// console.log(
		//   "**** showMessageModal v.patientNote --> ",
		//   cmp.get("v.patientNote")
		// );

		let selectedGroup = showUser === false ? cmp.get("v.defaultGroup") : null;
		let clientId = showUser ? "" : cmp.get("v.patientNote.patientNote.Account__c");
		// let recordId = showUser == false ? cmp.get('v.recordId') : null;
		let recordId = cmp.get("v.recordId");

		// console.log("**** showMessageModal clientId --> ", clientId);
		// console.log("**** showMessageModal recordId --> ", recordId);
		// console.log("**** showMessageModal selectedGroup --> ", selectedGroup);
		// console.log("**** showMessageModal showUser --> ", showUser);
		// console.log("**** showMessageModal type --> ", type);

		$A.createComponents(
			[
				[
					"c:CreateMessage",
					{
						type: type,
						showUser: showUser,
						clientId: clientId,
						patientNoteId: recordId,
						selectedGroup: selectedGroup,
					},
				],
				["c:CreateMessageFooter"],
			],
			function (components, status) {
				if (status === "SUCCESS") {
					createMessage = components[0];
					createMessageFooter = components[1];

					let title = showUser ? "Create Message" : "Create Alert";

					cmp.find("overlayLib").showCustomModal({
						header: title,
						footer: createMessageFooter,
						body: createMessage,
						showCloseButton: false,
					});
				}
			}
		);
	},
	getGroup: function (component, helper) {
		// console.log("PatientNoteHelper getGroup...");
		let me = this;
		var userId = $A.get("$SObjectType.CurrentUser.Id");
		helper.callApexMethod(
			component,
			"getGroup",
			{},
			function (result) {
				// console.log("**** Group --->" + result);
				component.set("v.defaultGroup", JSON.parse(result));
				helper.hideSpinner(component);
			},
			function (errorcallback) {
				helper.hideSpinner(component);
			}
		);
	},
	getCanFinalize: function (component, helper) {
		// console.log("PatientNoteHelper getCanFinalize...");
		let me = this;
		let noteId = component.get("v.recordId");
		helper.callApexMethod(
			component,
			"getCanFinalize",
			{
				noteId: noteId,
			},
			function (result) {
				// console.log("*** getCanFinalize " + result);
				component.set("v.canFinalize", result);
				// console.log("**** currentUserId ---> ", component.get("v.canFinalize"));
				helper.hideSpinner(component);
			},
			function (errorcallback) {
				helper.hideSpinner(component);
			}
		);
	},
	areRequiredFieldsValid: function (component, helper) {
		// console.log("PatientNoteHelper areRequiredFieldsValid...");
		// console.log("** Pass 2");
		let note = component.get("v.patientNote");
		// console.log("#### note ---> ", note);

		let isValid = true;

		for (let i = 0; i < note.noteItems.length; i++) {
			const item = note.noteItems[i];
			if (item.noteItem.Type__c != "Field") continue; //don't validate embedded components here

			//Confirm the current item exists as field in the Patient Note Object
			let fieldValue = note.patientNote[item.noteItem.Field_Name__c];
			if (item.noteItem.Is_Required__c && (fieldValue == null || fieldValue == "")) {
				isValid = false;
				break;
			}
		}
		component.set('v.isValid', isValid);
		return isValid;
	},
});
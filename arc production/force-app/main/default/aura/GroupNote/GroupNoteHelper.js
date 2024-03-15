({
	getGroupNote: function (component, event, helper) {
		helper.showSpinner(component);
		var action;
		action = component.get("c.getGroupNote"); //if received Group Note Id
		action.setParams({
			recordId: component.get("v.recordId"),
		});

		//JN removed 220720 to support meeting Id or Group Note Id
		// action = component.get("c.getMeetingGroupNote"); 
		// action.setParams({
		//   meetingId: component.get("v.recordId"),
		// });
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var groupNoteWrapper = response.getReturnValue();
				var objGroupNote = groupNoteWrapper.theNote;

				if (!objGroupNote) {
					var toastEvent = $A.get("e.force:showToast");

					toastEvent.setParams({
						title: "Error!",
						type: "error",
						message:
							"Unable to create or display group note. Please refresh page and try again.",
					});
					toastEvent.fire();
					return;
				} else if (objGroupNote.Id) {
					if (objGroupNote.Did_Group_Meet__c == "No") {
						component.set("v.isGroupMeet", true);
					}

					if (objGroupNote.Status__c == "Finalized") {
						component.set("v.isReadOnly", true);
					}

					if (objGroupNote.Attendance_Tracking__c == "No Attendance Tracking") 
					{
						component.set("v.noTracking", true);
					}

					let ownerObject = {
						value: objGroupNote.OwnerId,
						label: objGroupNote.Owner.Name,
						isRecord: true,
					};
					component.set("v.selectedOwner", ownerObject);

					component.set("v.objGroupNote", objGroupNote);
					component.set("v.isRecordLoaded", true);
				} else {
					var userAction = component.get("c.getUser");

					userAction.setCallback(this, function (response) {
						var state = response.getState();
						if (state === "SUCCESS") {
							objGroupNote.Owner = response.getReturnValue();
							component.set("v.objGroupNote", objGroupNote);
							component.set("v.isRecordLoaded", true);
							helper.changeOwner(
								component,
								event,
								helper,
								response.getReturnValue()
							);
						}
					});

					$A.enqueueAction(userAction);
				}

				var jsonData = groupNoteWrapper.lstGroupAttendance;
				if (groupNoteWrapper.lstGroupAttendance.length > 0) {
					jsonData.sort(function (a, b) {
						var nameA = a.lastName.toLowerCase();
						var nameB = b.lastName.toLowerCase();
						if (nameA < nameB)
							//sort string ascending
							return -1;
						if (nameA > nameB) return 1;
						return 0; //default return value (no sorting)
					});
				}
				component.set("v.lstGroupAttendance", jsonData);
				component.set("v.groupNoteWrapper", groupNoteWrapper);
				// window.setTimeout(
				//     $A.getCallback(function() {
				//        component.set("v.hasRecordUpdated", true);
				//     }), 2500
				// );
			} else {
				console.log('ERROR on getGroupNote: ' + response);
				helper.handleShowToast(component, event, helper, 'ERROR', 'Unable to retrieve Group Note', 'warning');
			}
			helper.hideSpinner(component);
		});
		$A.enqueueAction(action);
	},
	changeOwner: function (component, event, helper, owner) {
		if (!owner) {
			owner = component.get("v.objGroupNote.Owner");
		}
		component.set("v.ownerChange", true);
		var objMap = {};
		objMap["value"] = owner.Id;
		objMap["label"] = owner.Professional_Name__c
			? owner.Professional_Name__c
			: owner.Name;
		objMap["isRecord"] = true;
		component.set("v.selectedRecord", objMap);

		var childCmp = component.find("ownerLookup");
		var retnMsg = childCmp.setSelectedRecord(component.get("v.selectedRecord"));
		component.set("v.hasRecordUpdated", true);
	},

	clone: function (item) {
		return item ? JSON.parse(JSON.stringify(item)) : item;
	},

	upsertGroupNote: function (component, event, helper) {
		let me = this;
		helper.showSpinner(component);

		var isCmpDirty = component.get("v.isCmpDirty");
		if (isCmpDirty) {
			if (component.get("v.unsavedChanged")) {
				component.set("v.saveMessage", "Auto Saving...");
			}

			var action = component.get("c.updateGroupNote");

			let params = me.getParams(component);

			let GroupAttendanceList = params.GroupAttendanceList;
			//let objGroupNote = params.GroupNote;
			let objGroupNote = component.get('v.objGroupNote');
			delete objGroupNote.Group_Attendance__r;
			delete objGroupNote.Meeting__r;
			delete objGroupNote.Owner;

			if (objGroupNote.OwnerId && objGroupNote.OwnerId.startsWith("005")) {
				let actionParams = {
					objGroupNoteJson: JSON.stringify(objGroupNote),
					lstGroupAttendanceJson: JSON.stringify(GroupAttendanceList),
				};
				console.info("c.updateGroupNote : actionParams", actionParams);
				action.setParams(actionParams);

				action.setCallback(this, function (response) {
					var state = response.getState();
					var toastEvent = $A.get("e.force:showToast");

					if (state === "SUCCESS") {
						if (component.get("v.unsavedChanged") == true) {
							component.set("v.saveMessage", "Saved!");
						}
						component.set("v.isCmpDirty", false);
						if (component.get("v.calledFromSaveButton") == false) {
							component.set("v.controlRecursive", true);

							var jsonData = response.getReturnValue().Group_Attendance__r;
							jsonData.sort(function (a, b) {
								var nameA = a.Patient__r.Name.split(" ")[1].toLowerCase();
								var nameB = b.Patient__r.Name.split(" ")[1].toLowerCase();
								if (nameA < nameB)
									//sort string ascending
									return -1;
								if (nameA > nameB) return 1;
								return 0; //default return value (no sorting)
							});
							component.set("v.lstGroupAttendance", jsonData);
						}

						toastEvent.setParams({
							title: "Success!",
							type: "success",
							message: "The record has been updated successfully.",
						});

						var fromSaveButton = component.get("v.calledFromSaveButton");
						if (fromSaveButton == true) {
							toastEvent.fire();
							$A.get("e.force:closeQuickAction").fire();
							let closeEvent = component.getEvent("closeModalEvent");
							closeEvent.setParam("data", component.get("v.instanceName"));
							closeEvent.fire();
						} else {
							component.set("v.controlRecursive", true);
						}
					} else {
						toastEvent.setParams({
							title: "Error!",
							type: "error",
							message: "There was an error!",
						});
						toastEvent.fire();
					}
				});

				$A.enqueueAction(action);
			}
		}

		helper.hideSpinner(component);
	},

	getParams: function (cmp) {
		let me = this;
		let GroupNote = me.clone(cmp.get("v.objGroupNote"));
		delete GroupNote.Owner;
		delete GroupNote.Group_Attendance__r;
		delete GroupNote.Meeting__r;

		//! ARC-1533: Added Role__c to Group_Attendance__c return value below

		let GroupAttendanceList = me
			.clone(cmp.get("v.lstGroupAttendance"))
			.filter((x) => x.gatt)
			.map((x) => {
				return {
					sobjectType: (x.gatt.sobjectType = "Group_Attendance__c"),
					Id: x.gatt.Id,
					Name: x.gatt.Name,
					Group_Note__c: x.gatt.Group_Note__c,
					Patient__c: x.gatt.Patient__c,
					Attended__c: x.gatt.Attended__c,
					Role__c: x.gatt.Role__c,
					Patient_Contact__c: x.gatt.Patient_Contact__c,
				};
			});

		return { GroupNote, GroupAttendanceList };
	},

	finalizeGroupNote: function (component, event, helper) {
		let me = this;
		helper.showSpinner(component);

		var action = component.get("c.finalizeGroupNoteApex");

		let params = me.getParams(component);
		let objGroupNote = component.get('v.objGroupNote');
		action.setParams({
			objGroupNoteString: JSON.stringify(params.GroupNote),
			lstGroupAttendanceString: JSON.stringify(params.GroupAttendanceList),
		});
		action.setCallback(this, function (response) {
			var state = response.getState();
			var toastEvent = $A.get("e.force:showToast");
			if (state === "SUCCESS") {
				component.set("v.objGroupNote", response.getReturnValue());
				toastEvent.setParams({
					title: "Success!",
					type: "success",
					message: "The record has been finalized successfully.",
				});
				toastEvent.fire();
				// let closeEvent = component.getEvent("closeModalEvent");
				// closeEvent.setParam("data", component.get("v.instanceName"));
				// closeEvent.fire();
				helper.getGroupNote(component, event, helper);
			} else {
				toastEvent.setParams({
					title: "Error!",
					type: "error",
					message: "There was an error!",
				});
				toastEvent.fire();
			}
		});
		$A.enqueueAction(action);

		helper.hideSpinner(component);
	},

	setFilters: function (component) {
		var ownerLookupFilter = [
			{
				fieldName: "IsActive",
				condition: "=",
				value: true,
			},
		];
		component.set("v.ownerLookupFilter", ownerLookupFilter);
	},

	showSpinner: function (component, event, helper) {
		component.set("v.showSpinner", true);
	},
	hideSpinner: function (component, event, helper) {
		component.set("v.showSpinner", false);
	},
	handleShowToast : function(component, event, helper, title, message, variant) 
	{
			if (!title) title = 'Success!';
			if (!message) title = 'The transaction completed successfully';
			if (!title) title = 'success';
			component.find('notifLib').showToast({
					"title": title,
					"message": message,
					"variant": variant
			});
	}
});
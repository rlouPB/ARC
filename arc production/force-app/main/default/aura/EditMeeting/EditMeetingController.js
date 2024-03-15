({
    doInit: function(component, event, helper) {
        helper.loadMeeting(component, event, helper);

        helper.setFilters(component);
        helper.updateShowRecurrenceButton(component);
    },
    handleEditRecurrence: function(component, event, helper) {
        if (!component.get('v.meetingRecord.Id'))
        {
            component.set('v.canEditMeeting', true); //show Save button on recurrence if this is a new meeting
        }
        component.set("v.showEditRecurrenceModal", true);
    },
    handleEditRecurrenceSave: function(component, event, helper) {
		var selectedGroup = component.get("v.selectedGroup");
		var selectedPatient = component.get("v.selectedPatient");
		var chosenMode = component.get("v.meetingRecord.Meeting_Focus__c");
		// console.log("Chosen mode: " + chosenMode);
		// console.log("selectedGroup array length: " + Object.entries(selectedGroup).length);
		// console.log("selectedPatient array length: " + Object.entries(selectedPatient).length);
		if (Object.entries(selectedGroup).length == 0 && (chosenMode == "Patient Group" || chosenMode == "Staff Group"))
		{
			// console.log("No group chosen.");
			component.find('notifLib').showToast({
				"variant": "Please choose a group.",
				"title"  : "No group chosen.",
				"message": "Please choose a group."
			});
		}
		else if (Object.entries(selectedPatient).length == 0 && chosenMode == "Patient")
		{
			// console.log("No group chosen.");
			component.find('notifLib').showToast({
				"variant": "Please choose a patient.",
				"title"  : "No patient chosen.",
				"message": "Please choose a patient."
			});
		}
		else
		{
			var recurrenceModal = component.find("recurrenceModal");
			var isSaved = recurrenceModal.saveRecurrence();
			if(isSaved) {
				component.set("v.showEditRecurrenceModal", false);
				component.set("v.isRecurrence", true);
				// console.log('recurrence saved ' + JSON.stringify(component.get("v.recurrence")));
				var recurrence = component.get("v.recurrence");
				if(recurrence.isDirty) {
					component.set("v.isDirty", true);
				}
			}
			helper.hideSpinner(component);
		}	
    },
    handleEditRecurrenceCancel: function(component, event, helper) {
    	var recurrenceModal = component.find("recurrenceModal");
        recurrenceModal.cancelRecurrence();
        component.set("v.showEditRecurrenceModal", false);
        helper.hideSpinner(component);
    },
    handleSave: function(component, event, helper) 
    {
		var selectedGroup = component.get("v.selectedGroup");
		var selectedPatient = component.get("v.selectedPatient");
		var chosenMode = component.get("v.meetingRecord.Meeting_Focus__c");
		// console.log("Chosen mode: " + chosenMode);
		// console.log("selectedGroup array length: " + Object.entries(selectedGroup).length);
		// console.log("selectedPatient array length: " + Object.entries(selectedPatient).length);
		if (Object.entries(selectedGroup).length == 0 && (chosenMode == "Patient Group" || chosenMode == "Staff Group"))
		{
			// console.log("No group chosen.");
			component.find('notifLib').showToast({
				"variant": "Please choose a group.",
				"title"  : "No group chosen.",
				"message": "Please choose a group."
			});
		}
		else if (Object.entries(selectedPatient).length == 0 && chosenMode == "Patient")
		{
			// console.log("No group chosen.");
			component.find('notifLib').showToast({
				"variant": "Please choose a patient.",
				"title"  : "No patient chosen.",
				"message": "Please choose a patient."
			});
		}
		else
		{
			helper.showSpinner(component);    
			if (helper.validateForm(component)) {
				helper.saveRecord(component);
			}
            else{
                helper.hideSpinner(component);
            }
		}
    },
    handleCancel: function(component, event, helper) {
        // helper.showSpinner(component);
        var isDirty = component.get("v.isDirty");
    	if(isDirty) {
    		component.set("v.showCancelModal", true);
    	} else {
    		helper.closeModal(component, "discard");
        }
        // helper.hideSpinner(component);
    },
    handleDelete: function(component, event, helper) {
        // helper.showSpinner(component);
        component.set("v.showDeleteModal", true);
    	//helper.deleteMeeting(component);
        
        // helper.hideSpinner(component);
    },
    handleConfirmDelete: function(component, event, helper)
    {
        // component.set("v.showDeleteModal", false);
        helper.showSpinner(component);
        helper.deleteMeeting(component);
    },
    handleDiscardChanges: function(component, event, helper) {
        component.set("v.showCancelModal", false);
        helper.closeModal(component, "discard");
    },
    handleBackToMeeting: function(component, event, helper) {
        component.set("v.showDeleteModal", false);
        component.set("v.showCancelModal", false);
        component.set("v.showEditRecurrenceModal", false);
        helper.hideSpinner(component);
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === "CHANGED") {
            // get the fields that are changed for this record
            var changedFields = eventParams.changedFields;
            // console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            // record is changed so refresh the component (or other component logic)
            /*
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Saved",
                "message": "The record was updated."
            });
            resultsToast.fire();
            */
        } else if (eventParams.changeType === "LOADED") {
        	component.set("v.isLoaded", true);
            // record is loaded in the cache
        	var selectedOwner = {
        		value: component.get("v.meetingRecord.Owner.Id"),
        		label: component.get("v.meetingRecord.Owner.Name"),
        		isRecord: true
        	};
        	component.set("v.selectedOwner", selectedOwner);

        	var resource = component.get("v.meetingRecord.Room_Resource__c");
        	if(resource) {
        		var selectedResource = {
        			value: component.get("v.meetingRecord.Room_Resource__r.Id"),
        			label: component.get("v.meetingRecord.Room_Resource__r.Name"),
        			isRecord: true
                }
                component.set('v.originalResourceId', 
                    component.get("v.meetingRecord.Room_Resource__r.Id")
                );
        		component.set("v.selectedResource", selectedResource);
            }
            
            var selectedRecordList = component.get('v.selectedRecordList');
            // console.log('EditMeetingController handleRecordUpdated ' + JSON.stringify(selectedRecordList));
            if(Array.isArray(selectedRecordList)) {
                // console.log('in selectedRecordList');
                var patientContact = component.get("v.patientContact");
                if(patientContact && patientContact.Id && patientContact.Name) {
                    var patientContactFound = selectedRecordList.some(
                        element => element.value === patientContact.Id
                    );
                    if(!patientContactFound) {
                        selectedRecordList.push({
                            type: 'Contact',
                            label: patientContact.Name,
                            value: patientContact.Id,
                            isRecord: true
                        });
                    }

                    var ownerFound = selectedRecordList.some(
                        element => element.value === component.get("v.meetingRecord.Owner.Id")
                    );
                    if(!ownerFound) {
                        selectedRecordList.push({
                            type: 'User',
                            label: component.get("v.meetingRecord.Owner.Name"),
                            value: component.get("v.meetingRecord.Owner.Id"),
                            isRecord: true
                        });
                    }
                }

                // var user = component.get("v.user");
                // console.log('user ' + JSON.stringify(user));
                // if(user && user.Id && user.Name) {
                //     console.log('adding user');
                //     var userFound = selectedRecordList.some(
                //         element => element.value === component.get("v.meetingRecord.Owner.Id")
                //     );
                //     if(!userFound) {
                //         selectedRecordList.push({
                //             type: 'User',
                //             label: user.Name,
                //             value: user.Id,
                //             isRecord: true
                //         });
                //     }
                // }
                
                var hasEmptyLookup = selectedRecordList.some(
                    element => element.value === undefined || element.value === null
                );
                if(!hasEmptyLookup) {
                    selectedRecordList.push({
                        type: 'User'
                    });
                }
                component.set('v.selectedRecordList', selectedRecordList);
            }
        } else if (eventParams.changeType === "REMOVED") {
            // record is deleted and removed from the cache
        } else if (eventParams.changeType === "ERROR") {
            // console.log('Error: ' + component.get("v.error"));
        }
    },
    handleStartDateTimeChange: function(component, event, helper) {
    	var startDateTime = component.get("v.meetingRecord.Start_Date_Time__c");
    	var isLoaded = component.get("v.isLoaded");
    	if(startDateTime && isLoaded) {
            var endDateMoment = moment(startDateTime).add('minutes', 50);
            // var date = new Date(startDateTime);
    		// date.setMinutes(date.getMinutes() + 50);
    		// function pad2(number) {
    		// 	return (number < 10 ? '0' : '') + number
    		// };

    		// function getTime(oldTime) {
			//   let time = new Date(oldTime);
			//   let hours = time.getUTCHours();
			//   let minutes = time.getUTCMinutes();
			//   return hours + ":" + pad2(minutes) + ":" + "00" + "." + "000";
			// }
    		// component.set('v.meetingRecord.End_Date_Time__c', date.getFullYear() + "-" + 
            //     pad2((date.getMonth() + 1)) + "-" + pad2(date.getDate()) +"T" + getTime(date.getTime()) + "Z");
            component.set('v.meetingRecord.End_Date_Time__c', endDateMoment.format());
            var recurrence = component.get("v.recurrence");
            if(recurrence && !recurrence.recurrenceId) {
                //component.set("v.recurrence.startDate", date.getFullYear() + "-" + pad2((date.getMonth() + 1)) + "-" + pad2(date.getDate()));
                //component.set('v.recurrence.startDate', moment(startDateTime).format('YYYY-MM-DD'));
            }
    	}
        var isMeetingUpdateOnly = component.get("v.isMeetingUpdateOnly");
        if(isMeetingUpdateOnly != false) {
            var oldValue = event.getParam("oldValue");
            var newValue = event.getParam("value");
            if(oldValue != null  && typeof oldValue != 'object' && typeof newValue != 'object') {
                component.set("v.isMeetingUpdateOnly", false);
            }
        }
        var today = new Date(startDateTime);
        var weekFromToday = new Date(today);
        weekFromToday.setDate(weekFromToday.getDate() + 7);
        // console.log('today ' + today);
        // console.log('weekFromToday ' + weekFromToday);
        component.set('v.startDateTime', today);
        component.set('v.endDateTime', weekFromToday);
        var scheduleTable = component.find('schedule-table');
        if(scheduleTable) {
            scheduleTable.updateRows();
        }
        helper.updateRecurrenceStartdate(component);
        helper.updateShowRecurrenceButton(component);
    },
    handleEndDateTimeChange: function(component, event, helper) {
        var isMeetingUpdateOnly = component.get("v.isMeetingUpdateOnly");
        if(isMeetingUpdateOnly != false) {
            var oldValue = event.getParam("oldValue");
            var newValue = event.getParam("value");
            if(oldValue != null && typeof oldValue != 'object' && typeof newValue != 'object') {
                component.set("v.isMeetingUpdateOnly", false);
            }
        }
        var startDateTime = moment(component.get('v.meetingRecord.Start_Date_Time__c'));
        var endDateTime = moment(component.get('v.meetingRecord.End_Date_Time__c'));
        if (!(endDateTime.isSameOrAfter(startDateTime))) {
            component.set('v.meetingRecord.End_Date_Time__c', component.get('v.meetingRecord.Start_Date_Time__c'));
        }
    },
    handleAllDayDateChange: function(component, event, helper) {
        var recurrence = component.get("v.recurrence");
        if(recurrence && !recurrence.recurrenceId) {
            component.set('v.recurrence.startDate', moment(component.get('v.meetingRecord.All_Day_Date__c')).format('YYYY-MM-DD'));
            helper.updateRecurrenceStartdate(component);
        }
        helper.updateShowRecurrenceButton(component);
    },
    handleIsDirty: function(component, event, helper) {
    	component.set("v.isDirty", true);
    },
    handleSelectResource: function(component, event, helper) {
        helper.getAvailableResources(component);
        component.set('v.showSelectResourceModal', true);
    },
    handleSelectResourceCancel: function(component, event, helper) {
        component.set('v.showSelectResourceModal', false);
    },
    handleResourceSelected: function(component, event, helper) {
        var resourceId = event.currentTarget.getAttribute('data-id');
        // console.log('resourceId ' + resourceId);
        var availableResources = component.get('v.availableResources');
        var resourceFound = availableResources.find(element => {
            return element.Id === resourceId
        });
        var selectedResource = {
            label: resourceFound.Name,
            value: resourceFound.Id,
            isRecord: true
        }
    	component.set("v.isDirty", true);
        component.set('v.selectedResource', selectedResource);
        component.set('v.meetingRecord.Room_Resource__c', resourceId);
        component.set('v.showSelectResourceModal', false);
    },
    handleRemoveResource: function(component, event, helper) {
    	component.set("v.isDirty", true);
        component.set('v.selectedResource', null);
        component.set('v.meetingRecord.Room_Resource__c', null);
    },
    handleFocusChange : function(component, event, helper)
    {
        var meetingFocus = component.get('v.meetingFocus');
        // console.log('meetingFocus ' + meetingFocus);
	},
	handleGroupSelectionChange : function(component, event, helper)
	{
		var selectedGroup = component.get("v.selectedGroup");
		var selectedRecordList = component.get("v.selectedRecordList");
		var newRecordList = [];
		// console.log("Selected group: " + JSON.stringify(selectedGroup));
		
		var record;
		var addToList = 1;
		for (record in selectedRecordList)
		{
			// console.log("Current record in selectedRecordList: " + JSON.stringify(selectedRecordList[record]));
			if (selectedRecordList[record].value == selectedGroup.value ||
				selectedRecordList[record].value == undefined ||
				selectedRecordList[record].value == null)
			{
				
			} else {
				newRecordList.push(selectedRecordList[record]);
			}
		}

		if (selectedGroup.value != null && selectedGroup.value != undefined)
		{
			newRecordList.push({
				type: "Group",
				label: selectedGroup.label,
				value: selectedGroup.value,
				isRecord: true
			});
		}
		
		newRecordList.push({
			type: 'User'
		});
		
		// console.log("Selected Record List: " + JSON.stringify(selectedRecordList));
		// console.log("New Record List: " + JSON.stringify(newRecordList));
		component.set("v.selectedRecordList", newRecordList);
	},
	
	handleAllDayChange : function(component, event, helper)
	{
		if (component.get("v.showAllDay") == true)
		{
			component.set("v.meetingRecord.All_Day_Meeting__c", true);
			component.set("v.meetingRecord.Start_Date_Time__c", null);
			component.set("v.meetingRecord.End_Date_Time__c", null);
		} else
		{
			component.set("v.meetingRecord.All_Day_Meeting__c", false);
			component.set("v.meetingRecord.All_Day_Date__c", null);
		}
        
        helper.updateShowRecurrenceButton(component);
        helper.updateRecurrenceStartdate(component);
	}
})
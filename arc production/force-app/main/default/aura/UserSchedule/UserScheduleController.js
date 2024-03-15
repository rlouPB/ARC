({
    doInit: function(component, event, helper) {
		helper.loadUser(component);
		helper.setFilters(component);
    },
	loadEvents: function(component, event, helper) {
		var isCalendarLoaded = component.get("v.isCalendarLoaded");
        if(isCalendarLoaded) {
			// helper.getEvents(component);
			
        }
	},
	handleSelectedUserChange: function(component, event, helper) {
		var selectedUser = component.get("v.selectedUser");
		if(selectedUser && selectedUser.value) {
			component.set("v.userId", selectedUser.value);
			helper.getEvents(component);
		}
	},
    handleCalendarDateChangedEvent: function(component, event, helper) {
        var calendarId = event.getParam("calendarId");
        var startDate = event.getParam("startDate");
        var endDate = event.getParam("endDate");
		console.log('handleCalendarDateChangedEvent called');
		console.log('calendarId ' + calendarId);
		console.log('startDate ' + JSON.stringify(startDate));
		console.log('endDate ' + JSON.stringify(endDate));

		if (startDate != component.get('v.viewStartDate') 
				|| endDate != component.get('v.viewEndDate'))
		{
			component.set("v.viewStartDate", startDate);
			component.set("v.viewEndDate", endDate);
			
			helper.getEvents(component);
		}
    },
    handleCalendarEventClickedEvent: function(component, event, helper) {
        var calendarId = event.getParam("calendarId");
        var calendarEvent = event.getParam("calendarEvent");
        
        console.log('handleCalendarEventClickedEvent called');
        console.log('calendarId ' + calendarId);
        console.dir(calendarEvent);
        component.set("v.selectedMeeting", calendarEvent.id);
        if(calendarEvent.isRecurring) {
			component.set("v.isRecurrence", true);
            component.set("v.showRecurrenceModal", true);
        } else {
			component.set("v.isRecurrence", false);
            component.set("v.showEditMeetingModal", true);
        }
    },
    handleCalendarNewMeetingButtonClickedEvent: function(component, event, helper) {
        var calendarId = event.getParam("calendarId");
        console.log('handleCalendarNewMeetingButtonClickedEvent called');
        console.log('calendarId ' + calendarId);
        component.set("v.showCreateMeetingModal", true);
	},
	handleCalendarEventMouseEnterEvent: function(component, event, helper) {
		var calendarEvent = event.getParams();
		console.log('handleCalendarEventMouseEnterEvent');
		console.dir(calendarEvent);
		var startDateTime = calendarEvent.calendarEvent.participant.Meeting__r.Start_Date_Time__c;
		var endDateTime = calendarEvent.calendarEvent.participant.Meeting__r.End_Date_Time__c;

		var textStartDateTime = $A.localizationService.formatDate(startDateTime, "MM/dd/yy, hh:mm a");
		var textEndDateTime = $A.localizationService.formatDate(endDateTime, "MM/dd/yy, hh:mm a");

		component.set('v.hoverEvent', calendarEvent);
		component.set('v.hoverEventStartDateTime', textStartDateTime);
		component.set('v.hoverEventEndDateTime', textEndDateTime);

		var isPopoverOpen = component.get('v.isPopoverOpen');

		if(!isPopoverOpen) {
			var offsetY = 165;
			var offsetX = 5;
			var boundingRect = calendarEvent.jsEvent.currentTarget.getBoundingClientRect();
			component.set('v.popoverTop', boundingRect.top - offsetY + window.pageYOffset);
			component.set('v.popoverLeft', boundingRect.right - offsetX + window.pageXOffset);
			component.set('v.isPopoverOpen', true);
		}
	},
	handleCalendarEventMouseExitEvent: function(component, event, helper) {
		component.set('v.isPopoverOpen', false);
	},
    handleCloseModalEvent: function(component, event, helper) {
		var data = event.getParam("data");
		console.log('data is ' + JSON.stringify(data));
		if(data == 'createMeeting' || data == 'editMeeting') {
			helper.cancelMeeting(component);
		} else if(data == 'recurrence') {
			helper.closeRecurrenceModal(component);
		}
		switch (data.instanceName) {
			case 'createMeeting':
				if(data.type == 'save') {
					component.set('v.showCreateMeetingModal', false);
					helper.getEvents(component);
				} else if (data.type == 'discard') {
					component.set('v.showCreateMeetingModal', false);
				} else {
					helper.cancelMeeting(component);
				}
				break;
			case 'editMeeting':
				if(data.type == 'save') {
					component.set("v.showEditMeetingModal", false);
					helper.getEvents(component);
				} else if(data.type == 'discard') {
					component.set('v.showEditMeetingModal', false);
				} else {
					helper.cancelMeeting(component);
				}
				break;
		}
	},
	handleEditRecurrence: function(component, event, helper) {
		helper.editRecurrence(component);
	},
	handleSave: function(component, event, helper) {
		console.log('calling handleSave in UserScheduleController');
		helper.saveMeeting(component);
	},
	handleCancel: function(component, event, helper) {
		helper.cancelMeeting(component);
	},
	handleRecurrenceOk: function(component, event, helper) {
		helper.openRecurringMeeting(component);
	},
	handleRecurrenceCancel: function(component, event, helper) {
		helper.closeRecurrenceModal(component);
	}
})
({
    doInit : function(component, event, helper)
    {
        console.log("CustomCalendarController.js doInit");
		helper.setupDisplayMode(component, event, helper);
		var displayMode = component.get("v.displayMode");
		if(displayMode != "PatientAttendance")
		{
			var startDate = new Date();
        	component.set("v.viewStartDate", JSON.stringify(startDate));
		}
        helper.initialize(component);
        helper.loadUser(component);
        // component.set("v.viewEndDate", endDate);
		// debugger;
		
    },
    
    handleCurrentViewOptionSetChanged : function(component, event, helper) {
        console.log('handleCurrentViewOptionSetChanged-------------');
        helper.showSpinner(component);
        // console.log("called handleCurrentViewOptionSetChanged");
        
        var currentViewOptionSetParsed = component.get("v.currentViewOptionSet");
        
        //Only reload events if this isn't a change that came from apex
        if (!currentViewOptionSetParsed.changedFromServer)
        {
            var viewOptionSetList = component.get("v.viewOptionSetList");
            var currentViewOptionSetId = component.get('v.currentViewOptionSetId');
            //var isDifferentOptionSet = false;
            if (currentViewOptionSetParsed.optionSetObj.Id != currentViewOptionSetId 
                    || currentViewOptionSetParsed.isDifferentOptionSet)
            {
                //changed to new option set
                component.set('v.currentViewOptionSetId', currentViewOptionSetParsed.optionSetObj.Id);
                if (!currentViewOptionSetParsed.isDifferentOptionSet)
                {
                    currentViewOptionSetParsed.isDifferentOptionSet = true;
                    component.set('v.currentViewOptionSet', currentViewOptionSetParsed);
                }
            }
            var originalViewOptionSetList = component.get('v.originalViewOptionSetList');
            if (!originalViewOptionSetList || originalViewOptionSetList.length == 0)
            {
                component.set('v.originalViewOptionSetList', viewOptionSetList);
            }

            var display = 'calendar';
            var hoverType = 'readOnly';
            var queryType = 'MeetingType';
            var view = component.get('v.defaultView');
            if (currentViewOptionSetParsed.parameters )
            {
                if (currentViewOptionSetParsed.parameters.display)   display = currentViewOptionSetParsed.parameters.display;
                if (currentViewOptionSetParsed.parameters.hoverType) hoverType = currentViewOptionSetParsed.parameters.hoverType;
                if (currentViewOptionSetParsed.parameters.queryType) queryType = currentViewOptionSetParsed.parameters.queryType;
                if (currentViewOptionSetParsed.parameters.view) view = currentViewOptionSetParsed.parameters.view;
            }
            component.set('v.display', display);
            component.set('v.hoverType', hoverType);
            component.set('v.queryType', queryType);
            component.set('v.overrideView', view);
            // console.log('CustomCalendar defaultView = ' + component.get('v.defaultView'));
			// console.log('CustomCalendar overrideView = ' + component.get('v.overrideView'));
			console.log("queryType: " + component.get("v.queryType"));
            if (component.get('v.shouldGetEvents'))
            {
                helper.getEvents(component, event, helper);
            } else
            {
                // component.set('v.shouldGetEvents', true);
            }
        } else
        {
            helper.hideSpinner(component);
        }
        // component.set("v.vfHost", currentViewOptionSetParsed.orgDomainUrl);
		// var vfHost = component.get("v.vfHost");
		// var currentViewOptionSet = JSON.stringify(component.get("v.currentViewOptionSet"));


        // component.set("v.iframeUrl", vfHost + '/apex/PictureBookList' +
			// '?optionSet=' + currentViewOptionSet + searchText);
    },

    handleSelectOptionSet : function(component, event, helper)
    {   
        console.log('handleSelectOptionSet------------------')
        helper.showSpinner(component);
        var currentViewOptionSetParsed = component.get("v.currentViewOptionSet");
        var viewOptionSetList = component.get("v.viewOptionSetList");

        if (currentViewOptionSetParsed.optionSetObj.Title__c == "Therapeutic Community Schedule")
        {
            component.set('v.shouldGetEvents', false);
        }

        // console.log('select event ' + JSON.stringify(event.getParams()));
        
        var newCurrentViewOptionSetId = component.get("v.selectedTabId");
        // if (newCurrentViewOptionSetId
        //     && newCurrentViewOptionSetId != currentViewOptionSetParsed.optionSetObj.Id)
        // {
        var newCurrentViewOptionSet = viewOptionSetList.find(function(element) 
            {
                return element.optionSetObj.Id == newCurrentViewOptionSetId;
            });

        newCurrentViewOptionSet.isDifferentOptionSet = true;
        newCurrentViewOptionSet.changedFromServer = false;
        var selectedTopLevelOptionSet = component.get('v.selectedTopLevelOptionSet');
        if (newCurrentViewOptionSet.optionSetObj.Role__c == 'Group' || newCurrentViewOptionSet.optionSetObj.Role__c == 'Top-level')
        {
            component.set('v.selectedTopLevelOptionSet', newCurrentViewOptionSet);
            var a1 = "should probably put if (Role__c == 'Top-level') in front of this next line"
            if (newCurrentViewOptionSet.optionSetObj.Role__c == 'Top-level')
            {
                component.set('v.currentViewOptionSet', newCurrentViewOptionSet);
            }
            else if (newCurrentViewOptionSet.optionSetObj.Role__c == 'Group')
            {
                var defaultOptionSetLabel = newCurrentViewOptionSet.selectOptionSetRbGroupItem.optionItemObj.Default_Radio_Button__c;
                var defaultOptionSetId = newCurrentViewOptionSet.selectOptionSetRbGroupItem.optionItemObjList.find(function(element)
                {
                    return element.Label__c == defaultOptionSetLabel;
                }).Select_Option_Set__c;
                var newOptionSet = viewOptionSetList.find(function(element) {
                    return element.optionSetObj.Id == defaultOptionSetId;
                });
                newOptionSet.changedFromServer = false;
                component.set('v.currentViewOptionSet', newOptionSet);
                component.set('v.selectedOptionSetButton', defaultOptionSetLabel);
            }
        }
        else
        {
            component.set('v.currentViewOptionSet', newCurrentViewOptionSet);
        }
                
        // }
    },
    handleRefreshButtonClick : function(component, event, helper)
    {
        helper.refreshEvents(component, event, helper);
    },
    loadEvents : function(component, event, helper)
    {
        //var divElements = document.getElementById('print-calendar').innerHTML;
        helper.showSpinner(component);
        // console.log('calendar loaded');
        helper.getEvents(component, event, helper);
    },
    handleCalendarDateChangedEvent : function(component, event, helper)
    {
        helper.showSpinner(component);
        var calendarId = event.getParam("calendarId");
        var startDate = event.getParam("startDate");
        var endDate = event.getParam("endDate");
        
        // console.log('handleCalendarDateChangedEvent called');
        // console.log('calendarId ' + calendarId);
        // console.log('startDate ' + JSON.stringify(startDate));
        // console.log('endDate ' + JSON.stringify(endDate));
		
		var displayMode = component.get("v.displayMode");
		if(displayMode != "PatientAttendance")
		{
			component.set("v.viewStartDate", startDate);
			component.set("v.viewEndDate", endDate);
		}

        component.set('v.shouldGetEvents', true);
        
        helper.getEvents(component, event, helper);
    },
    handleCalendarViewChangedEvent : function(component, event, helper)
    {
        var view = event.getParam("view");
        component.set("v.calendarView", view);
    },
    handleCalendarNewMeetingButtonClickedEvent : function(component, event, helper)
    {
        var calendarId = event.getParam("calendarId");
        // console.log('handleCalendarNewMeetingButtonClickedEvent called');
        // console.log('calendarId ' + calendarId);
        component.set("v.showCreateMeetingModal", true);
    },
    handleCalendarEventClickedEvent : function(component, event, helper)
    {
        var calendarId = event.getParam("calendarId");
        var calendarEvent = event.getParam("calendarEvent");
        
        // console.log('handleCalendarEventClickedEvent called');
        // console.log('calendarId ' + calendarId);
        // console.dir(calendarEvent);
        component.set("v.selectedMeeting", calendarEvent.id);
        component.set("v.selectedMeetingRecord", calendarEvent.meeting);
        // var hasScheduleManager = component.get('v.hasScheduleManager');
        // var currUserId = component.get('v.userId');
        // //var canEditMeeting = (calendarEvent.meeting.OwnerId == currUserId) || hasScheduleManager;
        // var canEditMeeting = hasScheduleManager;
        // component.set("v.canEditMeeting", canEditMeeting);
        if(calendarEvent.isRecurring) {
			component.set("v.isRecurrence", true);
        }
        else {
			component.set("v.isRecurrence", false);
        }    
        component.set("v.showEditMeetingModal", true);
    },
    handleCalendarMeetingLoaded: function(component, event, helper) {
        // debugger;
        var meetingEvent = event.getParams();
        var canEditMeeting = meetingEvent.canEditMeeting;
        component.set("v.canEditMeeting", canEditMeeting);
    },
    handleCalendarEventMouseEnterEvent: function(component, event, helper) {
        // console.log('handle mouse ENTER event');
		var calendarEvent = event.getParams();
		// console.log('handleCalendarEventMouseEnterEvent');
        // console.dir(calendarEvent);
        
        helper.stopPopoverTimer(component);

        var thisMeeting = calendarEvent.calendarEvent.meeting;
        if (!thisMeeting)
        {
            thisMeeting = calendarEvent.calendarEvent.participant.Meeting__r;
        }
        component.set("v.selectedMeeting", thisMeeting.Id);
        var startDateTime = thisMeeting.Start_Date_Time__c;
		var endDateTime = thisMeeting.End_Date_Time__c;

		// var textStartDateTime = $A.localizationService.formatDate(startDateTime, "MM/dd/yy, hh:mm a");
		// var textEndDateTime = $A.localizationService.formatDate(endDateTime, "MM/dd/yy, hh:mm a");

        component.set('v.hoverEvent', calendarEvent);
        var hoverType = component.get('v.hoverType');
        component.set('v.groupNoteId', thisMeeting.Group_Note__c);
        switch(hoverType) 
        {
            case 'edit':
                component.set('v.hoverEventStartDateTime', startDateTime);
                component.set('v.hoverEventEndDateTime', endDateTime);
                break;
            case 'readOnly':
                component.set('v.hoverEventStartDateTime', startDateTime);
                component.set('v.hoverEventEndDateTime', endDateTime);
                break;
        }
        

		var isPopoverOpen = component.get('v.isPopoverOpen');

        // guess-and-check values for positioning, since popovers do not know hovered frame's relative position
        var offsetY = -16;
        //var offsetY = -248;
        var offsetX = -12;
        var estimatedWidth = 320;
        var boundingRect = calendarEvent.jsEvent.currentTarget.getBoundingClientRect();
        component.set('v.popoverLeft', (boundingRect.left - estimatedWidth) + offsetX);
        component.set('v.popoverRight', (window.innerWidth - boundingRect.left) + offsetX);
        //fix hover on list view 210216 JN
        //component.set('v.popoverTop', boundingRect.top + offsetY);
        component.set('v.popoverDirection', 'left');
        if (component.get('v.calendarView') == 'list6Weeks'){
            offsetY += 12;
            //fix hover on list view 210216 JN
            //component.set('v.popoverTop', boundingRect.top + offsetY);
        }
        if (component.get('v.calendarView') == 'listWeek'){
            offsetY += 12;
        }
        component.set('v.popoverTop', boundingRect.top + offsetY);
        if (component.get('v.popoverLeft') < 0){
            // if a left popover would go off screen, do right popover
            component.set('v.popoverDirection', 'right');
            component.set('v.popoverRight', '');
            component.set('v.popoverLeft', boundingRect.right - offsetX);
            if (component.get('v.popoverLeft') + estimatedWidth > window.innerWidth){
                component.set('v.popoverDirection', 'right');
                component.set('v.popoverLeft', (boundingRect.right - estimatedWidth) - offsetX);
            }
        }
        var cutoff = window.innerHeight - component.get('v.popoverTop');
        console.log('cutoff: ' + cutoff);
        component.set('v.popoverUp', false);
        if (cutoff < 300) {
            //fix hover on list view 210216 JN
            //component.set('v.popoverTop', component.get('v.popoverTop') - 230);
            component.set('v.popoverBottom', cutoff - 49);
            component.set('v.popoverTop', null);
            component.set('v.popoverUp', true);
        }
        component.set('v.isPopoverOpen', true);
	},
	handleCalendarEventMouseExitEvent: function(component, event, helper) {
        // console.log('handle mouse EXIT event');
        helper.startPopoverTimer(component);
	},
    handlePopoverMouseEnter: function(component, event, helper)
    {
		console.log('Newest version');
        helper.stopPopoverTimer(component);
    },
    handlePopoverMouseLeave: function(component, event, helper)
    {
        helper.startPopoverTimer(component);
    },
    handleClickPopover : function(component, event, helper)
    {
        helper.stopPopoverTimer(component);
    },
    handleSave: function(component, event, helper) {
		helper.showSpinner(component);
        // console.log('calling handleSave in UserScheduleController');
		helper.saveMeeting(component);
	},
	handleCancel: function(component, event, helper) {
        helper.hideSpinner(component);
		helper.cancelMeeting(component);
    },
    handleRemoveMeeting : function(component, event, helper)
    {
        helper.showSpinner(component);
        helper.removeMeeting(component);
    },
    handleEditRecurrence: function(component, event, helper) {
		helper.editRecurrence(component);
	},
    handleCloseModalEvent: function(component, event, helper) {
		var data = event.getParam("data");
		// console.log('data is ' + JSON.stringify(data));
		if(data == 'createMeeting' || data == 'editMeeting') {
			helper.cancelMeeting(component);
            component.set('v.isRecurrence', false);
            component.set('v.recurrenceSelected','single');
		} else if(data == 'recurrence') {
			helper.closeRecurrenceModal(component);
            component.set('v.isRecurrence', false);
            component.set('v.recurrenceSelected','single');
		} else if(data == 'groupNote') {
			component.set('v.showGroupNoteModal', false);
		}
		switch (data.instanceName) 
        {
			case 'createMeeting':
				if(data.type == 'save') {
					component.set('v.showCreateMeetingModal', false);
                    helper.refreshEvents(component, event, helper);
                    // component.set('v.isRecurrence', false);
                    // component.set('v.recurrenceSelected','single');

				} else if (data.type == 'discard') {
					component.set('v.showCreateMeetingModal', false);
				} else {
					helper.cancelMeeting(component);
				}
                component.set('v.isRecurrence', false);
                component.set('v.recurrenceSelected','single');
                //----------------------------------
                // the following refreshes the events so that changes are visible immediately
                // helper.refreshEvents(component, event, helper);
				break;
			case 'editMeeting':
				if(data.type == 'save') {
					component.set("v.showEditMeetingModal", false);
                    helper.refreshEvents(component, event, helper);
                } else if(data.type == 'discard') {
                    component.set('v.showEditMeetingModal', false);
				} else if(data.type == 'delete') {
                    component.set('v.showEditMeetingModal', false);
                    helper.refreshEvents(component, event, helper);
				} else {
                    helper.cancelMeeting(component);
				}
                component.set('v.isRecurrence', false);
                component.set('v.recurrenceSelected','single');
                if (component.get('v.isRecurrence') == true) {
                    component.set('v.recurrenceSelected', 'series');
                }
				break;
			case 'groupNote':
				component.set("v.showGroupNoteModal", false);
                 
        }
		
    },
    handleEditSeriesClick : function (component, event, helper)
    {
        component.set('v.recurrenceSelected', 'series');
    },
	handleRecurrenceOk: function(component, event, helper) {
		helper.openRecurringMeeting(component);
	},
	handleRecurrenceCancel: function(component, event, helper) {
		helper.closeRecurrenceModal(component);
    },
    handleClickRemoveFromPopover : function(component, event, helper)
    {
        component.set('v.showDeleteMeetingModal', true);

    },
    handleDeleteFromPopoverConfirmation : function(component, event, helper)
    {
        helper.showSpinner(component);
        component.set('v.showDeleteMeetingModal', false);
        helper.deleteMeeting(component, event, helper);
    },
    handleCancelFromPopoverConfirmation : function(component, event, helper)
    {
        component.set('v.showDeleteMeetingModal', false);
    },
    onChangeFromHover : function(component, event, helper)
    {
        // helper.showSpinner(component);
        component.set('v.showHoverSpinner', true);
        console.log('onChangeFromHover ');
        var source = event.getSource();
        var hoverEvent = component.get('v.hoverEvent');
        var meeting = {
            Id: hoverEvent.calendarEvent.meeting.Id
        };
        switch (source.get('v.id'))
        {
            case 'popoverDatetimeInput' :
                meeting.Start_Date_Time__c = source.get('v.value');    
                break;
            case 'popoverAttendanceInput' :
                meeting.Patient_Attendance__c = source.get('v.value');    
                break;
        }
        if (meeting.Patient_Attendance__c != 'Unknown')
        {
            meeting.Recurrence__c = null;
        }
        helper.quickSaveMeeting(component, meeting, helper);
    },
    onRemoveClickFromHover : function (component, event, helper)
    {
        console.log('onRemoveClickFromHover');
    },
    handleClickGroupNote : function (component, event, helper)
    {
        component.set('v.showGroupNoteModal', true);
    },

	closeCustomCalendarModal : function(component, event, helper)
	{
		var cmpEvent = component.getEvent("closeCalendarModalEvent");
		cmpEvent.setParam('data', 'CustomCalendar');
        cmpEvent.fire();
	}
})
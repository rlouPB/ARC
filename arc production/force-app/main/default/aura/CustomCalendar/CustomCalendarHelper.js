({
    loadUser: function(component) {
        var userId = component.get("v.userId");
        if(!userId)
        {
            userId = $A.get("$SObjectType.CurrentUser.Id");
        }
        component.set('v.userId', userId);
        //TODO
        // var action = component.get("c.getUser");
        // action.setParams({'userId': userId});
	    // action.setCallback(this, function(response) {
	    //     var state = response.getState();
	    //     if (component.isValid() && state === "SUCCESS") {
        //         // console.log('load user');
		// 		component.set("v.user", response.getReturnValue());
        //         var user = component.get("v.user");
        //         component.set("v.showUserSelect", user.isScheduleManager);
	    //     }
	    // });
	    // $A.enqueueAction(action);
    },
    
    getEvents: function(component, event, helper) 
    {
        console.log('CustomCalendar getEvents --------------------------======');
        var isCalendarLoaded = component.get("v.isCalendarLoaded");
        var currentViewOptionSet = component.get("v.currentViewOptionSet");
        var display = component.get('v.display');
        var rangeStart = component.get("v.viewStartDate");
		var rangeEnd = component.get("v.viewEndDate");
		var displayMode = component.get("v.displayMode");

        console.log('isCalendarLoaded : ', isCalendarLoaded)
        console.log('currentViewOptionSet : ', currentViewOptionSet)
        console.log('displayMode : ', displayMode)
        console.log('display : ', display)
        console.log('rangeStart : ', rangeStart)
        console.log('rangeEnd : ', rangeEnd)
        if(isCalendarLoaded && (currentViewOptionSet || displayMode == "PatientAttendance") && display == 'calendar' && rangeStart && rangeEnd)
        {
            var queryType = component.get('v.queryType');
            var context = component.get('v.context');
            var aggregatedField = displayMode == "PatientAttendance" ? '' : currentViewOptionSet.parameters.aggregatedField;

            var meetingTypes = [];
            var roomNames = [];
            var personOrGroupIds = [];
            var aggregatedValues = [];
            var excludedValues = [];
            var hasAnyChecked = false;
            if (queryType == 'User')
            {
                personOrGroupIds.push(component.get('v.userId'));
			}
			
			if (queryType == 'PatientFocus')
			{
				personOrGroupIds.push(component.get('v.userId'));
				personOrGroupIds.push(component.get('v.patientId'));
			}
			
			if (displayMode != "PatientAttendance")
			{
				currentViewOptionSet.checkboxItems.forEach(function(item) 
				{
					if (item.checkboxValue)
					{
						hasAnyChecked = true;
						if (queryType == 'MeetingType')
						{
							meetingTypes.push(item.optionItemObj.Label__c);
						} else if (queryType == 'RoomName')
						{
							roomNames.push(item.optionItemObj.Label__c);
						} 
						aggregatedValues.push(item.optionItemObj.Label__c);
					} else
					{
						excludedValues.push(item.optionItemObj.Label__c);
					}
				});
			}
            
            //don't bother calling server if there are no checkboxes checked and this is the same option set
            // && currentViewOptionSet.checkboxItems.length > 0 
            if (displayMode != "PatientAttendance" && !currentViewOptionSet.isDifferentOptionSet && !hasAnyChecked && !currentViewOptionSet.parameters.aggregatedField)
            {
                component.set("v.events", []);
                helper.hideSpinner(component);
                return;
            }
            var options = 
            {
                type: queryType,
                meetingTypes: meetingTypes,
                personOrGroupIds: personOrGroupIds,
                roomNames: roomNames,
                aggregatedField: aggregatedField,
                aggregatedValues: aggregatedValues,
                excludedValues: excludedValues,
                context: context,
                currentViewOptionSetId: displayMode == "PatientAttendance" ? '' : currentViewOptionSet.optionSetObj.Id

            };
            options.rangeStart = JSON.parse(JSON.stringify(component.get("v.viewStartDate")));
			options.rangeEnd = JSON.parse(JSON.stringify(component.get("v.viewEndDate")));
		
            var action = component.get("c.getCalendar");
            action.setParams({'options' : JSON.stringify(options)});
            action.setCallback(this, function(response) 
            {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") 
                {
                    //var calen dar = response.getReturnValue();
                    var calendar = JSON.parse(response.getReturnValue());
                    console.log('calendar ', JSON.stringify(calendar));
                    console.log('events: ', JSON.stringify(calendar.events));
                    component.set("v.events", calendar.events);

                    calendar.events.forEach(function(event){
                        if (event.meeting.Subject__c == 'testw')
                        {
                            console.log('event: ' + JSON.stringify(event));
                        }
                    });
                    
                    
                    //make option items from aggregatedValues
                    if (displayMode != "PatientAttendance" && calendar.options.aggregatedField && calendar.options.aggregatedField != '')
                    {
                        var currentViewOptionSet = component.get('v.currentViewOptionSet');
                        calendar.options.aggregatedValues.sort();
                        var newOptionItems = [];
                        calendar.options.aggregatedValues.forEach(function(aggregatedValue) 
                        {
                            var existingOptionItem = helper.findOptionItem(currentViewOptionSet.checkboxItems, aggregatedValue );
                            var newCheckboxValue = (existingOptionItem) ? existingOptionItem.checkboxValue : true;
                            //build option Item
                            var newOptionItem = 
                            {
                                checkboxValue: newCheckboxValue,
                                optionItemObj: 
                                {
                                    Label__c: aggregatedValue,
                                    Show_Label__c: true,
                                    Id: aggregatedValue
                                }
                            };

                            //add to list
                            newOptionItems.push(newOptionItem);
                        });
                        component.set('v.currentViewOptionSet.changedFromServer', true);
                        component.set('v.currentViewOptionSet.isDifferentOptionSet', false);
                        component.set('v.currentViewOptionSet.checkboxItems', newOptionItems);
                    }
                }
                helper.hideSpinner(component);
            });
            $A.enqueueAction(action);
        } else if (display != 'calendar')
        {
            helper.hideSpinner(component);
        }
    },
    saveMeeting: function(component) {
        var meetingModal = component.find("meetingModal");
        console.log('called saveMeeting form UserScheduleHelper');
        meetingModal.saveMeeting();
    },
    cancelMeeting: function(component) {
        var meetingModal = component.find("meetingModal");
        meetingModal.cancelMeeting();
    },
    removeMeeting: function(component)
    {
        var meetingModal = component.find('meetingModal');
        meetingModal.deleteMeeting();
    },
    editRecurrence: function(component) {
        var meetingModal = component.find("meetingModal");
        meetingModal.editRecurrence();
    },
    openRecurringMeeting: function(component) {
        component.set("v.showRecurrenceModal", false);
        component.set("v.showEditMeetingModal", true);
    },
    closeRecurrenceModal: function(component) {
        component.set("v.showRecurrenceModal", false);
    },
    startPopoverTimer: function(component)
    {   
        // console.log('starting popover timer');
        component.set('v.popoverTimerId',
            window.setTimeout(
                $A.getCallback(function() {
                    component.set('v.isPopoverOpen', false);
                    console.log('callback2');
                }), 1000));
    },
    stopPopoverTimer: function(component)
    {
        var popoverTimerId = component.get('v.popoverTimerId');
        if (popoverTimerId)
        {
            window.clearTimeout(popoverTimerId);
            component.set('v.popoverTimerId',null);
        }
    },
    quickSaveMeeting: function(component, meeting, helper)
    {
        var serializedMeeting = JSON.stringify(meeting);
        console.log('quickSaveMeeting ' + serializedMeeting);

        var action = component.get("c.quickSaveMeeting_ctl");
        action.setParams({'serializedMeeting' : serializedMeeting});
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") 
            {
                component.find('notifLib').showToast({
                    "variant": "success",
                    "title"  : "Successfully Updated"
                });
                //component.set('v.isPopoverOpen', false);
                component.set('v.showHoverSpinner', false);
                helper.getEvents(component, event, helper);
            } else
            {
                component.find('notifLib').showToast({
                    "variant": "error",
                    "title"  : "Error!",
                    "message": response.getReturnValue()
                });
                helper.hideSpinner(component);
                component.set('v.showHoverSpinner', false);
            }
        });
        $A.enqueueAction(action);
    },
    findOptionItem: function(array, value) 
    {
        for (var i = 0; i < array.length; i++) {
            if (array[i].optionItemObj.Label__c === value) {
                return array[i];
            }
        }
        return null;
    },
    refreshEvents : function(component, event, helper){
        helper.showSpinner(component);

        var currentViewOptionSetParsed = component.get("v.currentViewOptionSet");
        if (currentViewOptionSetParsed)
        {
            currentViewOptionSetParsed.isDifferentOptionSet = true;
            currentViewOptionSetParsed.changedFromServer = false;
            component.set('v.currentViewOptionSet', currentViewOptionSetParsed);
        } else
        {
            helper.getEvents(component, event, helper);
        }
    },
    showSpinner: function(component)
    {
        component.set('v.showSpinner', true);
    },
    hideSpinner: function(component)
    {
        component.set('v.showSpinner', false);
        // console.log('hiding spinner ' + component.getName() + ' now ' + component.get('v.showSpinner'));
    },
    deleteMeeting: function(component, event, helper)
    {
        var selectedMeetingId = component.get('v.selectedMeeting');

        var action = component.get("c.deleteMeeting");
        action.setParams({'meetingId' : selectedMeetingId});
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS" && response.getReturnValue() == 'success') 
            {
                component.find('notifLib').showToast({
                    "variant": "success",
                    "title"  : "Successfully Deleted"
                });

                helper.getEvents(component, event, helper);
            } else
            {
                component.find('notifLib').showToast({
                    "variant": "error",
                    "title"  : "Error!",
                    "message": response.getReturnValue()
                });
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);
    },
    navigateToGroupNote : function(component, event, helper)
    {
        var groupNoteId = component.get('v.groupNoteId');
        var navService = cmp.find("navService");
            //open group note page
            var pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Group__c',
                    recordId: groupNoteId,
                    actionName: 'view'
                },
                state: {
                   
                }
            };
            //cmp.set("v.pageReference", pageReference);

            navService.navigate(pageReference);
    },

	setupDisplayMode : function(component, event, helper)
	{
		if (component.get("v.displayMode") == "PatientAttendance")
		{
			component.set("v.displayMode", "PatientAttendance");
			component.set("v.hoverType", "edit");
			component.set("v.queryType", "PatientFocus");
		}

        // DAVE 5/16 - TODO - Call controller and set variable to show group notes.
	},

    initialize: function(cmp){
        let me = this;
        me.apex(cmp,'initializeComponentData').then($A.getCallback(function(data){
            cmp.set('v.hasCalendarShowGroupNote',data.hasCalendarShowGroupNote)
        }))
    },
    apex: function(cmp,actionName,params){
        let me = this
        return new Promise(function(resolve,reject){
            cmp.set('v.showSpinner',true)
            let action = cmp.get(`c.${actionName}`)
            if(params)action.setParams(params)
            action.setCallback(this,function(resp){
                if( resp.getState() == 'SUCCESS'){
                    resolve(resp.getReturnValue())
                }else(
                    reject(resp.getError())
                )
                cmp.set('v.showSpinner',false)
            })
            $A.enqueueAction(action);
        })
    }
})
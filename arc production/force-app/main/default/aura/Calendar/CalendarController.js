({
	doInit: function(component, event, helper) {
		
	},
    jsLoaded: function(component, event, helper) 
    {
        console.log("CalendarController.js jsLoaded event: ", JSON.stringify(event));
        var defaultDate = component.get('v.calendarStartDate');
        if (!defaultDate)
        {
            defaultDate = moment();
        }
        $(document).ready(function() {
            var calendarId = '#' + component.get("v.calendarId");
            $(calendarId).fullCalendar({
                header: false,
                defaultDate: defaultDate,
                defaultView: component.get('v.overrideView'),
                navlinks: true,
                editable: false,
                droppable: false,
                fixedWeekCount: false,
                selectable: false,
                selectHelper: false,
                eventLimit: true,
                events: [],
                eventClick: function(calEvent, jsEvent, view) {
			        helper.handleEventClicked(component, calEvent);
			    },
                eventDataTransform: function(event) {
					var evt;
					// Salesforce Event
					if (event.startDateTime) {
						evt = helper.meetingToEvent(event);
					}
					// Regular Event
					else {
						evt = event;
					}
					return evt;
				},
                eventMouseover: function(calEvent, jsEvent, view) {
					console.log('calEvent: ' + calEvent);
                    helper.handleEventMouseEnter(component, calEvent, jsEvent);
                },
                eventMouseout: function(calEvent, jsEvent, view) {
                    helper.handleEventMouseExit(component, calEvent, jsEvent);
                },
                eventRender: function(calEvent, element)
                {
                    // console.log('render ' + JSON.stringify(calEvent.meeting));
                    if (calEvent.meeting.Patient_Account__c)
                    {
                        element.addClass('patientMeeting');
                    }
                    // element.prepend('PREPENDED');
                },
                height: 'parent',
                timezone: 'America/New_York',
                defaultDate: defaultDate,
                views: 
                {
                    listWeek:
                    {
                        type: 'list',
                        duration: { weeks: 1 },
                        buttonText: 'List Week',
                        listDayFormat: 'dddd, MMMM DD, YYYY',
                        listDayAltFormat: false
                    },
                    list6Weeks: 
                    {
                        type: 'list',
                        duration: { weeks: 6 },
                        buttonText: 'List 6 Weeks',
                        listDayFormat: 'dddd, MMMM DD, YYYY'
                    }
                },
                viewRender: function(view, element) {
                    helper.handleDateChanged(component, view);
                },
                weekends: false
            });
            helper.setCalendarDate(component);
            //helper.setViewDates(component);
            component.set("v.isLoaded", true);
            helper.hideSpinner(component);
        });
    },
    prev: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('prev');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
	},
	next: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('next');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
	},
	today: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('today');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
	},
	month: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('changeView','month');
		component.set('v.view','month');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
        helper.handleViewChanged(component, component.get('v.view'));
	},
	basicWeek: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('changeView','basicWeek');
		component.set('v.view','basicWeek');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
        helper.handleViewChanged(component, component.get('v.view'));
	},
	listWeek: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('changeView','listWeek');
		component.set('v.view','listWeek');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
        helper.handleViewChanged(component, component.get('v.view'));
	},
	basicDay: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('changeView','basicDay');
		component.set('v.view','basicDay');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
        helper.handleViewChanged(component, component.get('v.view'));
	},
	listDay: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('changeView','listDay');
		component.set('v.view','listDay');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
        helper.handleViewChanged(component, component.get('v.view'));
	},
	list6Weeks: function(component, event, helper) {
        var calendarId = '#' + component.get("v.calendarId");
		$(calendarId).fullCalendar('changeView','list6Weeks');
		component.set('v.view','list6Weeks');
		helper.setCalendarDate(component);
        //helper.setViewDates(component);
        helper.handleViewChanged(component, component.get('v.view'));
	},
    overrideViewChange: function(component, event, helper){
        var overrideView = component.get('v.overrideView');
        var calendarId = '#' + component.get("v.calendarId");

        component.set('v.view', overrideView);
        console.log('default view changed to ' + overrideView);
        helper.handleViewChanged(component, overrideView);

        // if (typeof(jQuery) === 'function')
        // {
        //     //console.log('typeof: ' + typeof($(calendarId).fullCalendar));

        //     if (typeof($(calendarId).fullCalendar) === 'function')
        //     {
        //         //$(calendarId).fullCalendar('changeView',overrideView);
        //     }
        // }
    },
    toggleWeekends : function(component, event, helper){
        var showWeekends = component.get('v.showWeekends');
        component.set('v.showWeekends', !showWeekends);
        var calendarId = '#' + component.get('v.calendarId');
        $(calendarId).fullCalendar('option', {weekends : !showWeekends});
    },
    loadEvents: function(component, event, helper) 
    {
        helper.showSpinner(component);
        var oldValue = event.getParam('oldValue');
        var events = component.get('v.events');
        var calendarId = '#' + component.get("v.calendarId");
        if(oldValue.length) {
            $(calendarId).fullCalendar('removeEventSources');
            $(calendarId).fullCalendar('addEventSource', events);
        }
        else {
            $(calendarId).fullCalendar('addEventSource', events);
        }
        helper.hideSpinner(component);
    },
    handleNewMeetingButtonClicked: function(component, event, helper) {
        var calendarId = component.get("v.calendarId");
        var calendarNewMeetingButtonClickedEvent = component.getEvent(
            "calendarNewMeetingButtonClickedEvent"
        );
        calendarNewMeetingButtonClickedEvent.setParams({
            "calendarId": calendarId
        });
        calendarNewMeetingButtonClickedEvent.fire();
    },
    handleRefreshButtonClicked: function(component, event, helper) {
        var event = component.getEvent("calendarEventRefreshButtonClickedEvent");
        event.fire();
    }
})
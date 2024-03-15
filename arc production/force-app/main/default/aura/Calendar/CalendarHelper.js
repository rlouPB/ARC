({
    meetingToEvent: function(meeting) {
        if (meeting.meeting.Subject__c == 'testw')
        {
            console.log('hi');
        }
        console.log('CalendarHelper.js meetingToEvent meeting: ', meeting);
        var event = {};
		event.title = meeting.title;
		event.allDay = meeting.isAllDay;
        console.log("meeting.isAllDay: ", meeting.isAllDay);
		if (meeting.isAllDay)
		{
            console.log("meeting.allDayDate: ", meeting.allDayDate);
			event.start = meeting.allDayDate;
		} else
		{
            console.log("meeting.startDateTime: ", meeting.startDateTime);
			event.start = moment(meeting.startDateTime);
            // event.start.add(event.start._offset, 'm');
            // event.start.add(event.start._offset * -1, 'm');
		}
        console.log("event.start for ", event.title, ": ", event.start);
		event.end = moment(meeting.endDateTime);
		event.id = meeting.id;
        event.participant = meeting.participant;
        event.meeting = meeting.meeting;
		event.isRecurring = meeting.isRecurring;
		event.groupNotes = meeting.groupNotes;
        if (meeting.color && meeting.color != '') event.color = meeting.color;
		if (meeting.textColor && meeting.textColor != '') event.textColor = meeting.textColor;
		return event;
    },
	setCalendarDate: function(component, event, helper) {
		// http://momentjs.com/docs/#/displaying/format/
		var view = component.get('v.view').toLowerCase();
		var calendarId = '#' + component.get("v.calendarId");
		var moment;
		var calendarStartDate = component.get("v.calendarStartDate");
		if (calendarStartDate)
		{
			moment = $.fullCalendar.moment(calendarStartDate);
		} else
		{
			moment = $(calendarId).fullCalendar('getDate');
		}
		
		var headerDate;
        
		if (view.includes('month')) {
			headerDate = moment.format('MMMM YYYY');
		} else if (view.includes('day')) {
			headerDate = moment.format('MMMM DD, YYYY');
		} else if (view.includes('week')) {
			var startDay = moment.startOf('week').format('DD');
			var endDay = moment.endOf('week').format('DD');
            if (view.includes('6')) {
                headerDate = moment.startOf('week').format('MMM ') + startDay + ' – '
            	+ moment.endOf('week').add(5, 'weeks').format('MMM DD') + moment.format(', YYYY');
            }
            else {
                headerDate = moment.startOf('week').format('MMM ') + startDay + ' – '
            	+ moment.endOf('week').format('MMM') + ' ' + endDay + moment.format(', YYYY');
            }
		}
		component.set('v.headerDate',headerDate);
        // helper.showSpinner(component);
	},
    handleDateChanged: function(component, view) {
        var startDate = view.start._d;
        var endDate = view.end._d;
        var calendarId = component.get("v.calendarId");
        var dateChangedEvent = component.getEvent("calendarDateChangedEvent");
        dateChangedEvent.setParams({
            "calendarId": calendarId,
            "startDate": startDate,
            "endDate": endDate
        });
        dateChangedEvent.fire();
    },
    handleViewChanged: function(component, view){
        var viewChangedEvent = component.getEvent("calendarViewChangedEvent");
        viewChangedEvent.setParams({
            "view": view
        });
        viewChangedEvent.fire();
    },
    handleEventClicked: function(component, calEvent) {
        var calendarId = component.get("v.calendarId");
        var eventClickedEvent = component.getEvent("calendarEventClickedEvent");
        eventClickedEvent.setParams({
            "calendarId": calendarId,
            "calendarEvent": calEvent
        });
        eventClickedEvent.fire();
    },
    handleEventMouseEnter: function(component, calEvent, jsEvent) {
        // console.log('jsEvent');
        // console.dir(jsEvent);
        var calendarId = component.get("v.calendarId");
        var calendarEventMouseEnterEvent = component.getEvent("calendarEventMouseEnterEvent");
        calendarEventMouseEnterEvent.setParams({
            "calendarId": calendarId,
            "calendarEvent": calEvent,
            "jsEvent": jsEvent
        });
        calendarEventMouseEnterEvent.fire();
    },
    handleEventMouseExit: function(component, calEvent, jsEvent) {
        var calendarId = component.get("v.calendarId");
        var calendarEventMouseExitEvent = component.getEvent("calendarEventMouseExitEvent");
        calendarEventMouseExitEvent.setParams({
            "calendarId": calendarId,
            "calendarEvent": calEvent,
            "jsEvent": jsEvent
        });
        calendarEventMouseExitEvent.fire();
    },
    showSpinner : function(component)
    {
        component.set('v.showSpinner', true);
    },
    hideSpinner : function(component)
    {
        component.set('v.showSpinner', false);
    }
})
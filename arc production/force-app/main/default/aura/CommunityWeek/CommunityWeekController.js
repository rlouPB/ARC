({
    doInit : function(component, event, helper) 
    {
        console.log('init CommunityWeek');
        helper.showSpinner(component);

        var viewStartDateMoment = moment();
        component.set('v.viewStartDate', viewStartDateMoment);
        helper.getWeekGrid(component, event, helper);
    },
    prev: function(component, event, helper) {
        helper.showSpinner(component);
        var viewStartDateMoment = moment(component.get('v.viewStartDate'));
        viewStartDateMoment.subtract(7, 'days');
        component.set('v.viewStartDate', viewStartDateMoment);
        helper.getWeekGrid(component, event, helper);
	},
	next: function(component, event, helper) {
        helper.showSpinner(component);
        var viewStartDateMoment = moment(component.get('v.viewStartDate'));
        viewStartDateMoment.add(7, 'days');
        component.set('v.viewStartDate', viewStartDateMoment);
        helper.getWeekGrid(component, event, helper);
	},
	today: function(component, event, helper) {
        helper.showSpinner(component);
        var viewStartDateMoment = moment();
        component.set('v.viewStartDate', viewStartDateMoment);
        helper.getWeekGrid(component, event, helper);
    },
    handleOptionSetChange: function(component, event, helper)
    {
        console.log('CommunityWeekController is handling option set change');
        helper.showSpinner(component);
        console.log('handleOptionSetChange');
        helper.getWeekGrid(component, event, helper);
    },
    handleBorderToggle : function(component, event, helper)
    {
        component.set('v.isShowBorder', !component.get('v.isShowBorder'));
    },
    handleMeetingClicked : function(component, event, helper)
    {
        var meeting = {
            id: event.currentTarget.dataset.meeting,
            isRecurring: (event.currentTarget.dataset.recurrence != null)
        };
        var calendarEventClickedEvent = component.getEvent("calendarEventClickedEvent");
        calendarEventClickedEvent.setParams({
            "calendarEvent": meeting
        });
        calendarEventClickedEvent.fire();
    },
    handleNewMeetingButtonClicked: function(component, event, helper)
    {
        var calendarId = component.get("v.calendarId");
        var calendarNewMeetingButtonClickedEvent = component.getEvent(
            "calendarNewMeetingButtonClickedEvent"
        );
        calendarNewMeetingButtonClickedEvent.setParams({
            "calendarId": calendarId
        });
        calendarNewMeetingButtonClickedEvent.fire();
    }

})
({
    loadUser: function(component) {
        var userId = component.get("v.userId");
        if(!userId)
        {
            userId = $A.get("$SObjectType.CurrentUser.Id");
        }
        var action = component.get("c.getUser");
        action.setParams({'userId': userId});
	    action.setCallback(this, function(response) {
	        var state = response.getState();
	        if (component.isValid() && state === "SUCCESS") {
                console.log('load user');
				console.log('user in UserScheduleHelper ', response.getReturnValue());
                component.set("v.user", response.getReturnValue());
                var user = component.get("v.user");
                component.set("v.showUserSelect", user.isScheduleManager);
	        }
	    });
	    $A.enqueueAction(action);
    },
    setFilters: function(component) {
        var userLookupFilter = [
            {
                'fieldName': 'IsActive',
                'condition': '=',
                'value': true
            }
        ];
        component.set("v.userLookupFilter", userLookupFilter);
    },
	getEvents: function(component) {
        var options = {};
        var userId = component.get("v.userId");
        if(!userId)
        {
            userId = $A.get("$SObjectType.CurrentUser.Id");
        }
        options.type = 'User';
        options.personOrGroupIds = [userId];
        options.rangeStart = JSON.parse(JSON.stringify(component.get("v.viewStartDate")));
        options.rangeEnd = JSON.parse(JSON.stringify(component.get("v.viewEndDate")));
		var action = component.get("c.getUserSchedule");
        action.setParams({'options' : JSON.stringify(options)});
	    action.setCallback(this, function(response) {
	        var state = response.getState();
	        if (component.isValid() && state === "SUCCESS") {
				console.log('calendar ', response.getReturnValue());
	            component.set("v.events", response.getReturnValue().events);
	        }
	    });
	    $A.enqueueAction(action);
	},
    editRecurrence: function(component) {
        var meetingModal = component.find("meetingModal");
        meetingModal.editRecurrence();
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
    openRecurringMeeting: function(component) {
        component.set("v.showRecurrenceModal", false);
        component.set("v.showEditMeetingModal", true);
    },
    closeRecurrenceModal: function(component) {
        component.set("v.showRecurrenceModal", false);
    }
})
({
    getDaysHeader: function(component) {
        // console.log('in getDaysHeader');
        var rangeStartDateTime = component.get("v.startDateTime");
        var rangeEndDateTime = component.get("v.endDateTime");
        if(rangeStartDateTime && rangeEndDateTime) {
            var action = component.get("c.getSchedulerHeaders");
            action.setParams({
                'rangeStartDateTime': rangeStartDateTime,
                'rangeEndDateTime': rangeEndDateTime
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    // console.log('days ', JSON.stringify(response.getReturnValue()));
                    component.set("v.days", response.getReturnValue());
                    var days = component.get("v.days");
                    if(days.length) {
                        var hoursPerDay =  moment(days[0].endDateTime).diff(moment(days[0].startDateTime), "hours");
                        var totalWidth = days.length * ((hoursPerDay * 100) + 10);
                        component.set("v.totalWidth", totalWidth);
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },
    getDays: function(component) {
        // console.log('in getDays');
        var recordId = component.get("v.recordId");
        var rangeStartDateTime = component.get("v.startDateTime");
        var rangeEndDateTime = component.get("v.endDateTime");
        var action = component.get("c.getSchedulerDaysById");
        action.setParams({
            'recordId' : recordId,
            'rangeStartDateTime': rangeStartDateTime,
            'rangeEndDateTime': rangeEndDateTime
        });
	    action.setCallback(this, function(response) {
	        var state = response.getState();
	        if (component.isValid() && state === "SUCCESS") {
                // console.log('days in getDays ', JSON.stringify(response.getReturnValue()));
                component.set("v.days", response.getReturnValue());
                var days = component.get("v.days");
                var hoursPerDay =  moment(days[0].endDateTime).diff(moment(days[0].startDateTime), "hours");
                var totalWidth = days.length * ((hoursPerDay * 100) + 10);
                component.set("v.totalWidth", totalWidth);
	        }
	    });
	    $A.enqueueAction(action);
    }
})
({
    getWeekGrid: function(component, event, helper)
    {
        console.log('CommunityWeek getWeekGrid =/=/=/=/=/=/=/=/=/=/=/=/=/=/=/');
        var options = component.get('v.options');
        var rangeStart = moment(component.get('v.viewStartDate'));
        var rangeEnd = moment(component.get('v.viewStartDate')).add(7, 'days');

        options.rangeStart = rangeStart;
        options.rangeEnd = rangeEnd;
        var meetingTypes = [];
        options.checkboxItems.forEach(function(item) 
        {
            if (item.checkboxValue)
            {
                meetingTypes.push(item.optionItemObj.Label__c);
            }
        });
        options.meetingTypes = meetingTypes;
        options.type = 'MeetingType';
        var action = component.get("c.getWeek");
        action.setParams({'options' : JSON.stringify(options)});
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            console.log('callback state ' + state);
            if (component.isValid() && state === "SUCCESS") 
            {
                var calendar = response.getReturnValue();
                console.log('calendar ', JSON.stringify(calendar));
                console.log('timeRows: ', JSON.stringify(response.getReturnValue().timeRows));

                component.set("v.timeRows", response.getReturnValue().timeRows);
                var daynames = response.getReturnValue().dayNames;
                var dates = response.getReturnValue().dates;
                var weekdays = [];
                for (var i = 0; i < daynames.length; i++)
                {
                    weekdays.push({
                        dayName: daynames[i],
                        date: moment(dates[i]),
                        dateEpoch: dates[i]
                    });
                }
                component.set('v.weekdays', weekdays);
                helper.hideSpinner(component);
            } else
            {
                console.log('error ' + JSON.stringify(response.getReturnValue()));
            }
        });
        $A.enqueueAction(action);
    },
    hideSpinner: function(component)
    {
        component.set('v.showSpinner', false);
        component.set('v.isLoaded', true);
        console.log('hiding spinner on ' + component.getName() + ' now ' + component.get('v.showSpinner'));
    },
    showSpinner: function(component)
    {
        console.log('showing spinner on ' + component.getName() + ' was ' + component.get('v.showSpinner'));
        component.set('v.showSpinner', true);
    }
})
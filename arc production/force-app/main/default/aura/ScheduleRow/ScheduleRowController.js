({
    doInit: function(component, event, helper) {
        var startDateTime = component.get("v.startDateTime");
        var endDateTime = component.get("v.endDateTime");
        var today = new Date();
        var weekFromToday = new Date();
        weekFromToday.setDate(weekFromToday.getDate() + 7);
        if(!startDateTime) {
            component.set("v.startDateTime", today);
        }
        if(!endDateTime) {
            component.set("v.endDateTime", weekFromToday);
        }
        var isHeader = component.get("v.isHeader");
        if(isHeader) {
            helper.getDaysHeader(component);
        } else {
            var recordId = component.get("v.recordId");
            if(recordId) {
                helper.getDays(component);
            }
        }
    },
    handleRecordIdChanged: function(component, event, helper) {
        // console.log('recordId changed');
        var isHeader = component.get("v.isHeader");
        if(!isHeader) {
            helper.getDays(component);
        }
    },
    handleUpdateRow: function(component, event, helper) {
        // console.log('called handleUpdateRow');
        var isHeader = component.get("v.isHeader");
        if(!isHeader) {
            helper.getDays(component);
        } else {
            helper.getDaysHeader(component);
        }
    },
    handleShowPopover: function(component, event, helper) {
        var subject = event.currentTarget.dataset.subject;
        var startDateTime = event.currentTarget.dataset.startdatetime;
        var endDateTime = event.currentTarget.dataset.enddatetime;
        var description = event.currentTarget.dataset.description;

		var textStartDateTime = $A.localizationService.formatDate(startDateTime, "MM/dd/yy, hh:mm a");
		var textEndDateTime = $A.localizationService.formatDate(endDateTime, "MM/dd/yy, hh:mm a");

        component.set('v.hoverBlockSubject', subject);
		component.set('v.hoverBlockStartDateTime', textStartDateTime);
        component.set('v.hoverBlockEndDateTime', textEndDateTime);
        if(description) {
            component.set('v.hoverBlockDescription', description);
        } else {
            component.set('v.hoverBlockDescription', '');
        }
        
        var isPopoverOpen = component.get('v.isPopoverOpen');
        if(!isPopoverOpen) {
            var offsetY = 11;
			var offsetX = 54;
			var boundingRect = event.currentTarget.getBoundingClientRect();
			component.set('v.popoverTop', boundingRect.top - offsetY);
			component.set('v.popoverLeft', boundingRect.right - offsetX);
			component.set('v.isPopoverOpen', true);
        }
    },
    handleHidePopover: function(component, event, helper) {
        component.set('v.isPopoverOpen', false);
    }
})
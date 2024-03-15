({
    doInit: function(component, event, helper) {
        var userId = component.get("v.userId");
        if(!userId)
        {
            userId = $A.get("$SObjectType.CurrentUser.Id");
            console.log('setting userId ' + userId);
            component.set("v.userId", userId);
        }

        helper.setFilters(component);
    },
    handleSelectedItemEvent: function(component, event, helper) {
        console.log('handleSelectedItemEvent ScheduleTable');
        var eventObject = event.getParams();
        console.log('eventObject ' + JSON.stringify(eventObject));
        var selectedRecordList = component.get("v.selectedRecordList");
        if(eventObject.sourceInstanceName != null && eventObject.sourceInstanceName != undefined) {
            console.log('current selectedRecordList[eventObject.sourceInstanceName] ' + JSON.stringify(selectedRecordList[eventObject.sourceInstanceName]));
            var selectedRecordType = selectedRecordList[eventObject.sourceInstanceName].type;
            selectedRecordList[eventObject.sourceInstanceName] = eventObject.selectedObj;
            selectedRecordList[eventObject.sourceInstanceName].type = selectedRecordType;
        }
        var hasEmptyLookup = selectedRecordList.some(
            element => element.value === undefined || element.value === null
        );
        if(!hasEmptyLookup) {
            selectedRecordList.push({
                type: 'User'
            });
        }
        component.set("v.selectedRecordList", selectedRecordList);
        console.log('handleSelectedItemEvent selectedRecordList ' + JSON.stringify(component.get("v.selectedRecordList")));
    },
    handleRemovedItemEvent: function(component, event, helper) {
        console.log('handleRemovedItemEvent ScheduleTable');
        var eventObject = event.getParams();
        console.log('eventObject ' + JSON.stringify(eventObject));
        if(eventObject.sourceInstanceName != null && eventObject.sourceInstanceName != undefined) {
			var selectedRecordList = component.get('v.selectedRecordList');
			var newSelectedRecordList = [];
			// selectedRecordList.splice(eventObject.sourceInstanceName, 1);
			selectedRecordList.forEach(
				function(item, index)
				{
					if (index != eventObject.sourceInstanceName)
					{
						if (index == selectedRecordList.length - 1)
						{
							var newRecord = {
								type: item.type,
								searchText: item.searchText
							}
							newSelectedRecordList.push(newRecord);
						} else
						{
							newSelectedRecordList.push(item);
						}
					}
				}
			);
            component.set('v.selectedRecordList', newSelectedRecordList);
        }

        var meetingChangedEvent = component.getEvent("meetingChangedEvent");
        meetingChangedEvent.fire();
    },
    handleSelectedRecordListChange: function(component, event, helper) {
        console.log('handleSelectedRecordListChange');
        var selectedRecordList = component.get("v.selectedRecordList");
		console.log('handleSelectedRecordListChange selectedRecordList ' + JSON.stringify(selectedRecordList));
    },
    handleUpdateRows: function(component, event, helper) {
        helper.updateHeaderRow(component);
        helper.updateScheduleRows(component);
    }
})
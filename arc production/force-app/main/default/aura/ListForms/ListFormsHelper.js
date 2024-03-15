({
	getLabels : function(component, event, helper)
	{
		let action = component.get("c.getLabelsByAPI");
		action.setParams({
			"fieldList" : component.get("v.fieldList")
		});
		action.setCallback(this, response=>{
			if (response.getState() ==  "SUCCESS")
			{
				let returnVal = response.getReturnValue();
				var fieldMap = JSON.parse(returnVal);

				var index;
				var fieldList = component.get("v.fieldList");
				
				var index;
				var labelList = [];
				for (index in fieldList)
				{
					var header = fieldMap[fieldList[index]];
					var object = {};

					if (fieldList[index].includes("Date"))
					{
						object.header = header;
						object.size = 3;
					} else if (fieldList[index].includes("disco__Form_Template_Name__c"))
					{
						object.header = "Form";
						object.size = 3;
					} else
					{
						object.header = header;
						object.size = 4;
					}

					labelList.push(object);
				}
				component.set("v.labelList", labelList);
			}
			else if (response.getState() == "ERROR")
			{
				console.log("getLabels method failed");
			}
		});
		$A.enqueueAction(action);
	},

	getData : function(component, event, helper)
	{
		let action = component.get("c.refreshFormList");
		action.setParams({
			"context" : component.get("v.context"),
			"fieldList" : component.get("v.fieldList")
		});
		action.setCallback(this, response=>{
			if (response.getState() ==  "SUCCESS")
			{
				let returnVal = response.getReturnValue();
				component.set("v.formRecords", returnVal);

				var index;
				var formList = [];
				for (index in returnVal)
				{
					formList.push(returnVal[index].Id);
				}
				component.set("v.formList", formList);
			}
			else if (response.getState() == "ERROR")
			{
				console.log("getData method failed");
			}
		});
		$A.enqueueAction(action);

		helper.resetPollCounters(component, event, helper);
		helper.startPolling(component, event, helper);
		helper.pollServer(component, event, helper);
	},

	refreshList : function(component, event, helper)
	{
		helper.getData(component, event, helper);

		var listRowCmp = component.find("listRow");

		if ($A.util.isArray(listRowCmp))
		{
			listRowCmp.forEach(myRefreshFunction);

			function myRefreshFunction(item, index)
			{
				item.refreshRow();
			}
		} else
		{
			listRowCmp.refreshRow();
		}
	},
    
	sortBy : function(component, field, sortDirection)
	{
        var sortAsc = component.get("v.sortAsc"),
            sortField = component.get("v.sortField"),
			records = component.get("v.formRecords");
        if (sortDirection)
        {
            //explicitly set direction
            sortAsc = (sortDirection == "ASC" ? true : false);
        } else
        {
            //sortAsc true if changing columns or if current sortAsc is false, otherwise true
            sortAsc = sortField != field || sortAsc == false; 
		}

		var labelList = component.get("v.labelList");
		var fieldList = component.get("v.fieldList");
		var sortByField;
		labelList.forEach(function (value, index)
		{
			if (value.header == field)
			{
				sortByField = fieldList[index];
			}
		});

        records.sort(function(a,b){
            var t1 = a[sortByField] == b[sortByField],
                t2 = (a[sortByField] && !b[sortByField]) || (a[sortByField] < b[sortByField]);
            return t1 == true ? 0 : (sortAsc?-1:1)*(t2?1:-1);
		});
		
		var index;
		var formList = [];
		for (index in records)
		{
			formList.push(records[index].Id);
		}

        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", field);
		component.set("v.formList", formList);
	},
	
	startPolling : function(component, event, helper)
	{
		if (!component.get("v.timeoutId"))
        {
			component.set("v.timeoutId", 
                window.setInterval(
                    $A.getCallback(function() {
                        helper.pollServer(component, event, helper);
					}), 1000 * component.get("v.pollingInterval")));
		}
	},

	stopPolling : function(component, event, helper)
	{
		var timeoutId = component.get("v.timeoutId");
		window.clearInterval(timeoutId);
		component.set("v.timeoutId", "");
	},

	resetPollCounters : function(component, event, helper)
	{
		component.set("v.secondsSinceLastActivity", 0);
		component.set("v.latestModifiedDate", null);
	},

	pollServer : function(component, event, helper)
	{
		if (component.get("v.secondsSinceLastActivity") >= component.get("v.maximumSecondsToPoll"))
		{
			helper.stopPolling(component, event, helper);
		} else
		{
			let action = component.get("c.getLastModifiedFormDateTime");
			action.setParams({
				"context" : component.get("v.context")
			});
			action.setCallback(this, response=>{
				if (response.getState() ==  "SUCCESS")
				{
					let returnVal = response.getReturnValue();
					// Set lastestModifiedDate on first poll.
					if (!component.get("v.latestModifiedDate"))
					{
						component.set("v.latestModifiedDate", returnVal);
					} else
					{
						if (returnVal > component.get("v.latestModifiedDate"))
						{
							helper.refreshList(component, event, helper);
						}

						let currentSeconds = component.get("v.secondsSinceLastActivity");
						component.set("v.secondsSinceLastActivity", currentSeconds + component.get("v.pollingInterval"));
					}
				}
				else if (response.getState() == "ERROR")
				{
					console.log("pollServer method failed");
				}
			});
			$A.enqueueAction(action);
		}
	}
})
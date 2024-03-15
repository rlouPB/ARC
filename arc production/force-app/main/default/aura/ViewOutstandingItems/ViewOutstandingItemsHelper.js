({
	getResults: function(component) {
		var action = component.get("c.getResult");
        var selectedUser = component.get("v.selectedUserRecord");
		action.setParams({ selectedUserID : selectedUser.value });
		
		console.log("Selected User: " + selectedUser);
        
        action.setCallback(this, function(actionResult) 
		{
            var state = actionResult.getState();
            if (component.isValid() && state === "SUCCESS") 
			{
				var outstandingResult = actionResult.getReturnValue();
				component.set("v.openItemTagWrappers", outstandingResult.outstandingWrappers);
				var allOptions = [];
				var x;
				for (x of outstandingResult.categories) 
				{
					allOptions.push({label:x, value:x});
				}
				component.set("v.categories", allOptions);
				component.set("v.selectedCategories", outstandingResult.categories);
				component.set("v.selectedUserRecord.label", outstandingResult.currentUserName);
				component.set("v.hasManagerPermission", outstandingResult.hasManagerPermission);
            } else {
				var errors = actionResult.getError();
				if (errors) {
					console.log("Error: " + errors[0].message);
				} else {
					console.log("Unknown error");
				}
			}
			this.sortBy(component, component.get("v.sortField"), component.get("v.sortAsc"));
        });
        $A.enqueueAction(action);
	},

	initialSort: function(component) {
		
	},

	getFilteredResults: function(component) {
		console.log("categories: " + component.get("v.selectedCategories"));
		var action = component.get("c.getFilteredResult");
        var selectedUser = component.get("v.selectedUserRecord");
        var selectedCategories = component.get("v.selectedCategories");
		action.setParams({ selectedUserID : selectedUser.value, chosenCategories : selectedCategories });

        action.setCallback(this, function(actionResult) 
		{
            var state = actionResult.getState();
			var outstandingResult = actionResult.getReturnValue();
            if (component.isValid() && state === "SUCCESS") 
			{
				component.set("v.openItemTagWrappers", outstandingResult.currentWrappers);
            } else 
			{
				var errors = actionResult.getError();
				if (errors) {
					console.log("Error: " + errors[0].message);
				} else {
					console.log("Unknown error");
				}
			}
        });
        $A.enqueueAction(action);
	},
    
    sortBy: function(component, field, sortDirection) {
        var sortAsc = component.get("v.sortAsc"),
            sortField = component.get("v.sortField"),
            records = component.get("v.openItemTagWrappers");
        if (sortDirection)
        {
            //explicitly set direction
            sortAsc = (sortDirection == "ASC" ? true : false);
        } else
        {
            //sortAsc true if changing columns or if current sortAsc is false, otherwise true
            sortAsc = sortField != field || sortAsc == false; 
        }
        records.sort(function(a,b){
            var t1 = a[field] == b[field],
                t2 = (a[field] && !b[field]) || (a[field] < b[field]);
            return t1 == true ? 0: (sortAsc?-1:1)*(t2?1:-1);
        });
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", field);
        component.set("v.openItemTagWrappers", records);
    }
})
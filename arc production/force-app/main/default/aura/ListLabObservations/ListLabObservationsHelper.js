({
	saveSelectedBundledTests: function(component, event, helper){
		var selectedTests = component.find("bundleContent");
		var listOfTests = selectedTests.getSelectedRows();
		var testIds = listOfTests.map(x=>x.sfid);
		var recordId = component.get("v.recordId");
		var action = component.get("c.saveLabObservationFromBundle");
		action.setParams({
			"poId":recordId,
			"selectedEntryIds": JSON.stringify(testIds)
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
            console.log("called getLabObservations");
			if (state === "SUCCESS")
			{
				let labs = response.getReturnValue();
				component.set("v.labObservations", labs);
				component.set('v.showBundleContent', false);
			}
		});
		$A.enqueueAction(action);
	},
	loadData : function(component, event, helper)
	{
		//helper.showSpinner(component, 'Loading');
		component.set('v.loaded', false);
		
		var recordId = component.get("v.recordId");
		console.log("recordId: " + recordId);
		var action = component.get("c.loadLabObservationData");
		action.setParams({
			"procedureOrderId":recordId
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
            console.log("called getLabObservations");
			if (state === "SUCCESS")
			{
                let labs = response.getReturnValue().labObservations;
				component.set("v.isActive", response.getReturnValue().isActive);
                if(labs.length > 0) {
                    component.set("v.labObservations", labs);
                    console.log(JSON.stringify(labs));
                    component.set("v.showLabObservations",true);
                } else {
                    component.set("v.showLabObservations",false);
                }
				let allBundles = response.getReturnValue().allBundles;
				let bundleOptions =Object.keys(allBundles).sort().map(k => ({'label': k, 'value' :k}));
				console.log(bundleOptions);
				component.set("v.allBundles",allBundles);
				component.set("v.bundleOptions",bundleOptions);
                
			} else
			{
				component.set("v.labObservations",[]);
				console.log("getLabObservations failed");
				component.find('notifLib').showToast({
					"title": "Error",
					"variant": "error",
					"message": JSON.stringify(response.getError())
				});
			}
			//this.sortBy(component, component.get("v.sortField"), "DESC");
        	// helper.hideSpinner(component);
			component.set('v.loaded', true);
        });
		$A.enqueueAction(action);
	},
    
	sortBy: function(component, field, sortDirection)
	{
        var sortAsc = component.get("v.sortAsc"),
            sortField = component.get("v.sortField"),
			records = component.get("v.assignedClinicians");
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
            return t1 == true ? 0 : (sortAsc?-1:1)*(t2?1:-1);
        });
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", field);
        component.set("v.assignedClinicians", records);
    }
})
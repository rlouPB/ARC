({
	doInit : function(component, event, helper)
	{
		helper.loadData(component, event, helper);
		//helper.subscribe(component, event);
		component.set('v.bundledTestColumns', [
            {label: 'Test Name', fieldName: 'testName', type: 'text'},
            {label: 'Test Code', fieldName: 'code', type: 'text'},
			{label: 'Category', fieldName: 'category', type: 'text'},
        ]);

	},
	reloadData : function(component, event, helper)
	{
		helper.loadData(component, event, helper);
	},
    
	sortByName : function(component, event, helper)
	{
        let target = event.currentTarget;
		let columnName = target.getAttribute("data-columnName")
        //helper.sortBy(component, columnName);
	},

	handleShowManageModal : function(component, event, helper)
	{
		console.log("Setting v.showManageModal to true");
        component.set('v.showManageModal', true);
    },

	hideManageModal : function(component, event, helper)
	{
		console.log("Setting v.showManageModal to false");
        component.set('v.showManageModal', false);
    },

	handleCloseModalEvent : function(component, event, helper)
	{
		// console.log("called handleCloseModalEvent from ListAssignedClinicians");
		// component.find('overlayLib').notifyClose();

		console.log("Setting v.showManageModal to false");
		helper.loadData(component, event, helper);
		component.set('v.showManageModal', false);
	},

	handleRefreshButtonClick: function(component, event, helper) 
	{
		helper.loadData(component, event, helper);
	},

	//something else on the Lightning page updated the Admission
	handleRefreshPatient: function(component, event, helper) 
	{
        var eventParams = event.getParams();
        console.log('ListAssignedClinicians event fired ' + JSON.stringify(event.getParams()));
        // if(eventParams.changeType === "LOADED") {
        //     component.set("v.isRecordLoaded",true);
        //     // window.setTimeout($A.getCallback(function() {
        //     //     helper.toggleSpinner(component, 0);  
        //     // }),1000);
        // } else 
		if (eventParams.changeType === 'CHANGED') 
        {
        	//reload when any of these three records is updated
        	component.find('recordLoader').reloadRecord(true);
        	// helper.toggleSpinner(component, 0);
        }
    },

	saveLabObservationsFromBundle : function(component, event, helper)
	{
		helper.saveSelectedBundledTests(component, event, helper);
	},
	saveLabObservations : function(component, event, helper)
	{
		var childCmp = component.find("manageLabObservations");
		childCmp.saveLabObservations();
	},
	bundleSelected : function(component, event, helper) {
		var selectedOptionValue = event.getParam("value");
		var testMap = component.get("v.allBundles");
		var testList = testMap[selectedOptionValue];
		var selectedList = testList.map(x=>x.code);
		component.set('v.bundledTests', testList);
		component.set('v.showBundleContent', true);
		//ARC-2522 Lab bundles - start off with all unchecked
		//component.set('v.selectedBundledTest', selectedList);
	},
	closeShowBundleContent : function(component, event, helper) {
		component.set('v.showBundleContent', false);
	},
	closeBundledModal : function(component, event, helper) {
		component.set('v.showBundleContent', false);
	}
})
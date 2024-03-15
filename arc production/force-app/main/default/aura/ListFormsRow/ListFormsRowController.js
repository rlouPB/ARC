({
	doInit : function(component, event, helper)
	{
		// component.set('v.subscription', null);
		// helper.subscribe(component, event, helper);
	},

	viewForm : function(component, event, helper)
	{
		var auraPubsub = component.find('auraPubsub');
		var payload = {
			formId: component.get("v.formId"),
			isFormDetail: true
		};
		auraPubsub.fireEvent('yFormSelected', payload);
	},

	editForm : function(component, event, helper)
	{
		var auraPubsub = component.find('auraPubsub');
		var payload = {
			formId: component.get("v.formId"),
			isFormDetail: false
		};
		auraPubsub.fireEvent('yFormSelected', payload);
	},

	recordUpdated : function(component, event, helper)
	{
		// console.log("recordUpdated called by force:recordData");
		helper.refreshList(component, event, helper);
	},

	refreshListRow : function(component, event, helper)
	{
		// console.log("refreshRow called to update force record data");
		component.find('formRecordData').reloadRecord(true);
	}
})
({
	handleCloseModal : function(component, event, helper)
	{
		let closeEvent = component.getEvent('closeModalEvent');
		closeEvent.setParam('data', component.get('v.instanceName'));
		closeEvent.fire();
	}
})
({
    doInit : function(component, event, helper) {
        helper.showSpinner(component);
        component.set("v.columns", helper.getColumnDefinitions());
        helper.getInterventions(component, event, helper, false);
    },
    handleShowDiscontinuedInterventions : function(component, event, helper) {
        helper.showSpinner(component);
        let value = event.getParam('value');
        if(value == 'All'){
            helper.getInterventions(component, event, helper, true);
        }else{
            helper.getInterventions(component, event, helper, false);
        }
        
    },
    handleCloseViewInterventions : function(component, event, helper) {
		let closeEvent = component.getEvent('closeModalEvent');
		closeEvent.setParam('data', component.get('v.instanceName'));
		closeEvent.fire();
    }
})
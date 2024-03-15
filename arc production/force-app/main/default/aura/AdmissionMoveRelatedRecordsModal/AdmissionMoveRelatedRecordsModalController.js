({
	handleClick : function(component, event, helper) {
		helper.displayModal(component);
	},

	removeComponent : function(component, event) {
		component.set("v.showModal", false);
		/*
        //Get the parameter(modal) you defined in the event, and destroy the component
        var component = event.getParam("component");      
        component.destroy();
        */
    }
})
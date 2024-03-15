({
	doInit: function(component, event, helper) {
		var objectName = component.get("v.objectName");
		var fieldName = component.get("v.fieldName");
		if(objectName && fieldName) {
			helper.getMultiSelectPicklist(component, helper, objectName, fieldName);
		}
	},
	handleChange: function(component, event, helper) {
		var selectedOptions = event.getParam("value");
		component.set("v.selectedOptions", selectedOptions);
		var selectedOptionsString = selectedOptions.join(';');
		component.set("v.selectedOptionsString", selectedOptionsString);
	}
})
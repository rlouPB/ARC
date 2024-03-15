({
	getMultiSelectCheckbox : function(component, helper, objectName, fieldName) {
		var action = component.get("c.getMultiSelectCheckboxOptions");
        action.setParams({
            objectName: objectName,
            fieldName: fieldName
        });
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
            	var responseValue = response.getReturnValue();

            	var options = [];
            	for (var i = 0; i < responseValue.length; i++) {
                    options.push({
                        label: responseValue[i].label,
                        value: responseValue[i].value
                    });
                }
                component.set("v.options", options);
                helper.updateMultiSelectCheckboxOptions(component);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
	},
    updateMultiSelectCheckboxOptions: function(component) {
        let selectedOptionsString = component.get("v.selectedOptionsString");
        if(selectedOptionsString) {
            let selectedOptions = selectedOptionsString.split(';');
            component.set("v.value", selectedOptions);
            /*
            var availableOptions = component.get("v.availableOptions");
            availableOptions = availableOptions.filter(val => {
                return selectedOptions.find(element => {
                    return element != val.label;
                });
            });*/
        }
    }
})
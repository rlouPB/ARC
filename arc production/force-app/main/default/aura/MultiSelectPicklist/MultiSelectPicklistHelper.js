({
	getMultiSelectPicklist: function(component, helper, objectName, fieldName) {
		var action = component.get("c.getMultiSelectPicklistOptions");
        action.setParams({
            objectName: objectName,
            fieldName: fieldName
        });
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
            	var responseValue = response.getReturnValue();
            	console.log('responseValue ' + JSON.stringify(responseValue));

            	var availableOptions = [];
            	for (var i = 0; i < responseValue.length; i++) {
                    availableOptions.push({
                        label: responseValue[i].label,
                        value: responseValue[i].value
                    });
                }
                component.set("v.availableOptions", availableOptions);
                helper.updateMultiSelectPicklistOptions(component);
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
    updateMultiSelectPicklistOptions: function(component) {
        var selectedOptionsString = component.get("v.selectedOptionsString");
        if(selectedOptionsString) {
            var selectedOptions = selectedOptionsString.split(';');
            component.set("v.selectedOptions", selectedOptions);

            var availableOptions = component.get("v.availableOptions");
            availableOptions = availableOptions.filter(val => {
                return selectedOptions.find(element => {
                    return element != val.label;
                });
            });
        }
    }
})
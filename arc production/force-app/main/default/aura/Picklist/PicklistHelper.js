({
    getPicklist : function(component, objectName, fieldName) {
        let me = this;
        return new Promise($A.getCallback((resolve)=>{
            var action = component.get("c.getPicklistOptions");
            action.setParams({
                objectName: objectName,
                fieldName: fieldName
            });
            action.setCallback(me, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var responseValue = response.getReturnValue();
                    console.log('responseValue ' + JSON.stringify(responseValue));
                    let selectedValue = component.get('v.selectedValue');
                    var availableOptions = [];
                    for (var i = 0; i < responseValue.length; i++) {
                        let option = {
                            label: responseValue[i].label,
                            value: responseValue[i].value,
                            selected: false
                        };
                        if(!$A.util.isEmpty(selectedValue)){
                            if(responseValue[i].value == selectedValue){
                                option.selected = true;

                                console.log('PicklistHelper picklist value:'+component.get('v.selectedValue'));
                            }
                        }
                        availableOptions.push(option);                        
                    }
                    component.set("v.options", availableOptions);
                    resolve();
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
        }));
	}
})
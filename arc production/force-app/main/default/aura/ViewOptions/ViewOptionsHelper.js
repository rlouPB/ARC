({
	loadViewOptions : function(component) {
		var context = component.get("v.context");
        var action = component.get("c.getViewOptionSets");
        action.setParams({
            "context": context
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var viewOptionSetList = response.getReturnValue();
                // console.log('viewOptionSetList: ' + JSON.stringify(viewOptionSetList));
                component.set("v.viewOptionSetList", viewOptionSetList);
                var defaultViewOptionSet = viewOptionSetList.find(function(element) {
                	return element.optionSetObj.Is_Default__c == true;
                });

                // console.log('defaultViewOptionSet ' + JSON.stringify(defaultViewOptionSet));
                if(defaultViewOptionSet) {
                    if (defaultViewOptionSet.optionSetObj.Role__c == 'Group') {
                        component.set('v.selectedTopLevelOptionSet', defaultViewOptionSet);
                        var defaultOptionSetRbGroupItem = defaultViewOptionSet.selectOptionSetRbGroupItem.rbOptions.find(function(element) {
                            return element.label == defaultViewOptionSet.selectOptionSetRbGroupItem.optionItemObj.Default_Radio_Button__c;
                        });
                        component.set('v.selectedOptionSetButton', defaultOptionSetRbGroupItem.label);
                        var defaultOptionSetId = defaultOptionSetRbGroupItem.selectOptionSet;
                        var defaultOptionSet = viewOptionSetList.find(function(element) {
                            return element.optionSetObj.Id == defaultOptionSetId;
                        });
                        component.set('v.currentViewOptionSet', defaultOptionSet);
                    }
                    else {
                        component.set("v.currentViewOptionSet", defaultViewOptionSet);
                    }
                }

            } else if (state === 'ERROR'){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log('Something went wrong, Please check with your admin');
            }
            this.checkAllSelected(component);
        });
        $A.enqueueAction(action);
	},
    checkAllSelected : function(component)
    {
        var currentViewOptionSet = component.get('v.currentViewOptionSet');
        if (!currentViewOptionSet) return;
        
        var checkboxItems  = currentViewOptionSet.checkboxItems;
        if (!checkboxItems)
        {
            component.set('v.currentViewOptionSet.checkboxItems', []);
        } else
        {
            for (var item of checkboxItems)
            {
                if (!item.checkboxValue)
                {
                    component.set('v.allSelected', false);
                    return;
                }
            }
        }
        component.set('v.allSelected', true);
    }
})
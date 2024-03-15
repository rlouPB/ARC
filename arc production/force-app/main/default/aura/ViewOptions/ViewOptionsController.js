({
	doInit : function(component, event, helper) {
		helper.loadViewOptions(component);
	},
	handleChange : function(component, event, helper) {
		var changeValue = event.getParam("value");
		var name = event.getSource().get("v.name");
		// console.log('name : value ' + name + ' : ' + changeValue);
		// console.log('currentViewOptionSet ' + JSON.stringify(component.get("v.currentViewOptionSet")));
		if (name == 'selectOptionSet')
        {
            // set currentViewOptionSet
            var topLevelOptionSet = component.get('v.selectedTopLevelOptionSet');
            // get option set id
            var newOptionSetId = topLevelOptionSet.selectOptionSetRbGroupItem.rbOptions.find(function(element) {
                return element.label == changeValue;
            }).selectOptionSet;
            // find option set with that id in viewOptionSetList
            var viewOptionSetList = component.get('v.viewOptionSetList');
            var newOptionSet = viewOptionSetList.find(function(element) {
                return element.optionSetObj.Id == newOptionSetId;
            });
            newOptionSet.changedFromServer = false;
            component.set('v.currentViewOptionSet', newOptionSet);
        }
        else
        {
            var currentViewOptionSet = component.get("v.currentViewOptionSet");
            currentViewOptionSet.changedFromServer = false;
            component.set("v.currentViewOptionSet", currentViewOptionSet);
            helper.checkAllSelected(component);
        }
	},
    selectAllClicked : function(component, event, helper){
        helper.checkAllSelected(component);
        var currentViewOptionSet = component.get('v.currentViewOptionSet');
        var checkboxItems  = currentViewOptionSet.checkboxItems;
        for (var item of checkboxItems){
            item.checkboxValue = !component.get('v.allSelected');
        }
        currentViewOptionSet.changedFromServer = false;
        component.set('v.currentViewOptionSet', currentViewOptionSet);
        component.set('v.allSelected', !component.get('v.allSelected'));
    }
})
({
	doInit : function(component, event, helper) {
		console.log('MultiSelectCheckbox doInit');
		var objectName = component.get("v.objectName");
		var fieldName = component.get("v.fieldName");
		if(objectName && fieldName) {
			helper.getMultiSelectCheckbox(component, helper, objectName, fieldName);
		}
	},
	handleChange : function(component, event, helper) {
		let selectedValueArray = event.getParam("value");
		var selectedValues = '';
		if(!$A.util.isEmpty(selectedValueArray)){
			if(selectedValueArray.length == 1){
				selectedValues = selectedValueArray[0];
			}else{
				selectedValues = selectedValueArray.join(";");
			}
		}
		console.log('selectedValueArray:'+selectedValues);
		component.set("v.selectedOptionsString", selectedValues);
		/*
		let fieldName = component.get("v.fieldName");
        component.set("v.changedFields",[{field:fieldName,value:selectedValues}]);
        helper.fireNoteChangedEvent(component, event, helper);*/
	}
})
({
    doInit : function(component, event, helper) {
		let objectName = component.get("v.objectName");
		let fieldName = component.get("v.fieldName");
		if(objectName && fieldName) {
			helper.getPicklist(component, objectName, fieldName).then($A.getCallback(()=>{
				let options = component.get('v.options');
				let required = component.get('v.required');
				if(required == true && options.filter(x=>x.selected==true).length == 0 ){
					component.set('v.selectedValue', options[0].value );
				}
			}));
		}
	},
})
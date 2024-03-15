({
	doInit : function(component, event, helper) {
		var record = component.get("v.record");
        var field = component.get("v.field");
        var value = '';
        
        if(field.name && field.type == "REFERENCE") {
            var refNameStr = field.referenceName;
            var refNames = refNameStr.split(".");
            var obj = record[refNames[0]] || {};
            console.log('obj', obj);
            if(obj) {
                value = obj[refNames[1]] ||'';
            }
            
            console.log('record', field.name, field.referenceName, record, field, value);
        } else if(field.name){
            value = record[field.name] || ''
        }
        component.set("v.value", value);
        
	}
})
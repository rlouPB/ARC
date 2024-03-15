({
	doInit : function(component, event, helper) {
        component.set("v.showSpinner", true);
		var action = component.get("c.getHistory");

        action.setParams({
            "objectAPIName" : component.get("v.sObjectName"),
            "recordId" : component.get("v.recordId")
        });
        
        action.setCallback(this, function(a){
            
            if (a.getState() === "SUCCESS") {
                var data = JSON.parse(a.getReturnValue());            

                _.forEach(data.results, function(value, key){
                    data.results[key].createdByName = data.userMap[value.CreatedById].Name;    
                    data.results[key].CreatedDate = new Date(data.results[key].CreatedDate);           
                });
                component.set("v.histories", data.results);
                component.set("v.showSpinner", false);
                component.set("v.objectLabel", data.ObjectName);

            } else if (a.getState() === "ERROR"){ //fires toasts with any issues
                console.log(a);
                var appEvent = $A.get("e.c:handleCallbackError");
                appEvent.setParams({
                    "errors" : a.getError(),
                    "errorComponentName" : "LightningHistory"
                });
                appEvent.fire();
            } 
            
            
        });
        
        $A.enqueueAction(action);
	}
})
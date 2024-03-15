({
	roleChanged : function(component, event, helper) {
        console.log("old value: " + event.getParam("oldValue"));
        console.log("current value: " + event.getParam("value"));
        if(event.getParam("oldValue") != 'undefined' && event.getParam("oldValue") != '' && event.getParam("oldValue")){
            var caseTeamRoleChanged = component.getEvent("CaseTeamRelatedListRoleChanged");
            caseTeamRoleChanged.fire();
        }

	},
 
    
    
})
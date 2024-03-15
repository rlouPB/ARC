({
    setUpdateInterval : function(component, event, helper){
        if (!component.get("v.update_id")){
            component.set("v.update_id",
            	window.setInterval(
                    $A.getCallback(function(){
                        helper.refresh(component, event, helper);
                    }), component.get("v.refresh_interval")));
        }
    },
	refresh : function(component, event, helper) {
        //console.log('refreshing...');
        var getWhiteboard = component.get("c.getWhiteboard");
        var requirements = component.get("v.admissions_requirements");
        getWhiteboard.setParams({ requirements : requirements });
        getWhiteboard.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var whb = response.getReturnValue();
                console.log(whb.AccountRequirementRows);
                component.set("v.account_requirement_rows", whb.AccountRequirementRows);
                component.set("v.accounts_in_active_done", whb.ActiveDoneAccounts);
                component.set("v.accounts_in_waitlist", whb.WaitlistAccounts);
            }
        });
        $A.enqueueAction(getWhiteboard);
	}
})
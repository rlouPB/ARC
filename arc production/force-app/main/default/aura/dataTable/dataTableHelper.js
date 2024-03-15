({
	loadRelatedContacts: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        // Load Related Contacts from Salesforce    
        var action = component.get("c.getRelContacts");
        action.setParams({
            "accountId": component.get("v.accntId")
        });
        // Add callback behavior for when response is received
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.relContact", response.getReturnValue());                
                component.set("v.filterRelCon", response.getReturnValue());                
            }
            else {
                console.log("Failed with state: " + state);
            }
            helper.hideSpinner(component, event, helper);
        });
        // Send action off to be executed
        $A.enqueueAction(action);
        
    },
    showSpinner: function(component, event, helper)
    {
        component.set('v.isRefreshing', true);
    },
    hideSpinner: function(component, event, helper)
    {
        component.set('v.isRefreshing', false);
    },
    toggleSpinner: function(component, event, helper)
    {
        component.set('v.isRefreshing', !component.get('v.isRefreshing'));
    }

})
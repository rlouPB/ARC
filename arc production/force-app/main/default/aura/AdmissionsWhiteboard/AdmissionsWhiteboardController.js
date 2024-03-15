({
    doInit : function(component, event, helper) {
        // this is stuff we want to do when the component loads
        console.log('doInit is happening');
        helper.setUpdateInterval(component, event, helper);
        helper.refresh(component, event, helper);
    },
    handleClick : function(component, event, helper) {
        window.open('/' + event.currentTarget.dataset.id);
        return;
        //below is the old handler, does not open in new tab
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.currentTarget.dataset.id
        });
        navEvt.fire();
	},
    navigateToRecord : function(component, event, helper){
        window.open('/' + event.getParam('recordId'));
    },
    handleButtonClick : function(cmp){
        var action = cmp.get("c.getActiveInquiryAccounts");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                cmp.set("v.accounts_in_active_inquiry", response.getReturnValue());
            }
            else{
                alert("Error returning " + response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})
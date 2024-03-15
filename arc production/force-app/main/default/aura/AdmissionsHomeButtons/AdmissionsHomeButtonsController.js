({
    doInit : function(component, event, helper) {
        var action = component.get("c.getOrCreateAdmission");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var admission = response.getReturnValue();
                component.set('v.admission', admission.Id);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error("Error: " + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    handleClick : function(component, event, helper) {
        var admission = component.get('v.admission');
        let urlval = '/apex/SDOC__SDCreate1?id=' + admission + '&Object=Admission__c&doclist=Consultation Pending %26 Waitlist&autoopen=1';
        window.open(urlval, "_blank");
    },

    handleNewVarianceButtonClick : function(component, event, helper) {
        let urlval = '/lightning/o/Variance__c/new?count=2&nooverride=1&useRecordTypeCheck=1';
        window.open(urlval);
    }
})
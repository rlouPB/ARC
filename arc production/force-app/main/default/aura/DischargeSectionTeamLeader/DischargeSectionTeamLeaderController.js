({
    doInit:function(component, event, helper)
    {
        var responsiblePersonFilter = [
            {
                'fieldName': 'Name',
                'condition': '=',
                'value': 'User'
            }    
        ];
		component.set("v.instanceName","Team Leader");
	},
    handleSectionActionEvent:function(component,event,helper)
    {
        var dischargeSection=component.get("v.dischargeSection");
        var action=event.getParam("action");
        switch(action){
            case "completed":
                dischargeSection.dischargeSectionObj.Status__c='Completed';
                helper.saveDischargeSection(component,event,helper,dischargeSection);
                break;
            case "save":
                helper.saveDischargeSection(component,event,helper,dischargeSection);
                break;
            case "reopen":
                helper.reopenDischargeSection(component,event,helper,dischargeSection);
                break;
        }
    },
    /**
     * Users must have either referral selected or "No Separate Referral Required" checked.
     */
    handleNoSeparateReferralRequired:function(component,event,helper)
    {
        var dischargeSection=component.get("v.dischargeSection");
        helper.validateReferral(component,event,helper,dischargeSection);
    },

    /**
     * Users must have either referral selected or "No Separate Referral Required" checked.
     */
    handleReferralChanged:function(component,event,helper)
    {
        var dischargeSection=component.get("v.dischargeSection");
        helper.validateReferral(component,event,helper,dischargeSection);
    }
})
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
        var referralListMap=component.get("v.referralListMap");
        if($A.util.isEmpty(referralListMap))
        {
            referralListMap={
                "ResidentialDayTreatmentProgramReferrals":[],
                "CouplesFamilyTherapyReferrals":[],
                "GroupTherapySelfHelpReferrals":[]
            };
            component.set("v.referralListMap",referralListMap);
        }
		component.set("v.instanceName","Social Worker");
        helper.splitList(component,event,helper);
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
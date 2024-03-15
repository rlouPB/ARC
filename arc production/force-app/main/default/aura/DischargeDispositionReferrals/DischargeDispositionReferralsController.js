({
    doInit:function(component, event, helper)
    {
        var referralList=component.get("v.referralList");
        var section=component.get("v.section");
        var grouping=component.get("v.grouping");
        if($A.util.isEmpty(referralList) &&
          section.dischargeSectionObj.Status__c=='Draft')
        {
            helper.addNewReferral(component,event,helper);
        }
    },
    /**
	 * TODO If the referral changed is last one on list THEN:
	 * 1. When a referral is changed from blank to have value, if it is at the end of the list, add new blank referral to end of the list
	 * 2. When a referral is changed from value to blank and if referral is NOT last one on list
	 * remove itself from list and add new blank referral at the end of the list
     */
    handleReferralChanged:function(component, event, helper)
    {
        // Stop bubble up to different referral sub-list component.
        var isLoading=component.get("v.isLoading");
        var action=event.getParam("action");
        if(isLoading==false)
        {
            event.stopPropagation();
            if(action=='remove')
            {
                helper.removeReferral(component,event,helper);
            }
            else
            {
                helper.addNewReferral(component,event,helper);
            }
        }
	},
    handleChangedReferralList:function(component, event, helper)
    {
        var isLoading=component.get("v.isLoading");
        var grouping=component.get("v.grouping");
        if(isLoading==false)
        {
            var section=component.get("v.section");
            var sectionId=event.getParam("sectionId");
            if(sectionId==section.dischargeSectionObj.Id)
            {
                helper.addNewReferral(component,event,helper);
            }
        }
        else
        {
            var referralList=component.get("v.referralList");
            component.set("v.numReferral",referralList.length);
        }
    },
    addNewReferral:function(component,event,helper)
    {
        helper.addNewReferral(component,event,helper);
    }
})
({
    doInit:function(component, event, helper)
    {
        var referralFilterList=[];
        var mode=component.get("v.mode");
        if(mode=='individual')
        {
            var referralFilter=
                {
                    'fieldName': 'RecordType.DeveloperName',
                    'condition': '=',
                    'value': 'Professional'
                };
            referralFilterList.push(referralFilter);
        }
        else if(mode=='institution')
        {
            var referralFilter=
                {
                    'fieldName': 'RecordType.DeveloperName',
                    'condition': '=',
                    'value': 'Medical_Institution'
                };
            referralFilterList.push(referralFilter);
        }
        component.set("v.referralFilter", referralFilterList);
        var referral=component.get("v.referral");
        if((!$A.util.isEmpty(referral.dischargeReferralObj.Clinician__c) || 
        !$A.util.isEmpty(referral.dischargeReferralObj.Institution__c)))
        {
            component.set("v.referralName",referral.referralName);
            component.set("v.selectedReferral",{
                "label":referral.referralName,
                "value":(mode=='individual'?referral.dischargeReferralObj.Clinician__c:referral.dischargeReferralObj.Institution__c),
                "isRecord":true
            });
        }
	},
    /**
     * When selected referral is changed, it will notify referal list to recalculate.
     */
    handleSelectedReferralChange:function(component, event, helper)
    {
        var isLoading=component.get("v.isLoading");
        var grouping=component.get("v.grouping");
        if(isLoading==false)
        {
            var oldValue=event.getParam("oldValue");
            var value=event.getParam("value");
            var index=component.get("v.index");
            var referral=component.get("v.referral");
            var selectedReferral=component.get("v.selectedReferral");
            var mode=component.get("v.mode");
            if(!$A.util.isEmpty(value)){
                helper.getReferralPhone(component,event,helper,mode,selectedReferral.value);
                if(mode=='individual')
                {
                    referral.dischargeReferralObj.Clinician__c=selectedReferral.value;
                }
                else
                {
                    referral.dischargeReferralObj.Institution__c=selectedReferral.value;
                }
                component.set("v.referral",referral);
                var referralChangedEvent=component.getEvent("referralChanged");
                referralChangedEvent.setParams({
                    "index":index,
                    "referral":referral,
                    "selectedReferral":selectedReferral,
                    "grouping":grouping,
                    "action":"select"
                });
                referralChangedEvent.fire();
            }
            else
            {
                if(mode=='individual')
                {
                    referral.dischargeReferralObj.Clinician__c=null;
                }
                else
                {
                    referral.dischargeReferralObj.Institution__c=null;
                }
                component.set("v.referral",referral);
                component.set("v.referralPhone",null);
            }
        }
        else
        {
            console.log('handleSelectedReferralChange '+grouping+' for isLoading:'+isLoading);
        }
    },
    handleSelectedItemEvent:function(component, event, helper)
    {
        var isLoading=component.get("v.isLoading");
    },
    handleRemoveReferral:function(component, event, helper)
    {
        var index=component.get("v.index");
        var referral=component.get("v.referral");
        var grouping=component.get("v.grouping");
        var referralChangedEvent=component.getEvent("referralChanged");
        referralChangedEvent.setParams({
            "index":index,
            "referral":referral,
            "selectedReferral":null,
            "grouping":grouping,
            "action":"remove"
        });
        referralChangedEvent.fire();
    }
})
({
    addNewReferral:function(component,event,helper) {
        var selectedReferral=event.getParam("selectedReferral");
        var referralList=component.get("v.referralList");
        var grouping=component.get("v.grouping");
        var numReferral=component.get("v.numReferral");
        if(referralList==null || referralList==undefined)
        {
            referralList=[];
        }
        if(referralList.length<3)
        {
            if(referralList.length==0 || (!$A.util.isEmpty(referralList[referralList.length-1].dischargeReferralObj.Clinician__c) ||
                                          !$A.util.isEmpty(referralList[referralList.length-1].dischargeReferralObj.Institution__c)))
            {
                var dischargeDispositionId=component.get("v.dischargeDispositionId");
                var section=component.get("v.section");
                var referral={
                    "dischargeReferralObj":{
                        "sobjectType":"Discharge_Referral__c",
                        "Discharge_Disposition__c":dischargeDispositionId,
                        "Section__c":section.dischargeSectionObj.Id,
                        "Grouping__c":grouping,
                        "Is_Primary__c":(referralList.length==0?true:false),
                        "Referral_Notes__c":null,
                        "Clinician__c":null,
                        "Institution__c":null
                    }
                };
                referralList.push(referral);
            }
        }
        console.log('referral list:'+JSON.stringify(referralList));
        component.set("v.numReferral",referralList.length);
        component.set("v.referralList",referralList);
	},
    removeReferral:function(component,event,helper)
    {
        var index=event.getParam("index");
        var referral=event.getParam("referral");
        var referralList=component.get("v.referralList");
        if(!$A.util.isEmpty(referral.dischargeReferralObj.Id))
        {
            var removeReferralList=component.get("v.removeReferralList");
            if(removeReferralList==null || removeReferralList==undefined)
            {
                removeReferralList=[];
            }
            removeReferralList.push(referral);
            component.set("v.removeReferralList",removeReferralList);
        }
        referralList.splice(index,1);
        component.set("v.numReferral",referralList.length);
        component.set("v.referralList",referralList);
    }
})
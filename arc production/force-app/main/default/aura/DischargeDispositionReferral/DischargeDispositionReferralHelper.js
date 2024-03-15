({
    getReferralPhone:function(component,event,helper,mode,referralId)
    {
        helper.callApexMethod(
            component,
            "getReferralPhone",
            {"mode":mode,"referralId":referralId},
            function (result)
            {
                if(result)
                {
                    console.log('referral phone result:'+JSON.stringify(result));
                    var referral=component.get("v.referral");
                    referral.referralPhone=result;
                    component.set("v.referral",referral);
                }
            },
            null,
            false
        );
    }
})
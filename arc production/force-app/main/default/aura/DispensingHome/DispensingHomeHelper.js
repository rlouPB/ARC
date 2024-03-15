({
    apex: function(cmp,actionName,params){
        let me = this
        return new Promise(function(resolve,reject){
            cmp.set('v.loading',true)
            let action = cmp.get(`c.${actionName}`)
            if(params)action.setParams(params)
            action.setCallback(this,function(resp){
                if( resp.getState() == 'SUCCESS'){
                    resolve(resp.getReturnValue())
                }else(
                    reject(resp.getError())
                )
                cmp.set('v.loading',false)
            })
            $A.enqueueAction(action);
        })
    },
    initialize: function(cmp, currentTab){
        let me = this;
        cmp.set('v.todaysDate', $A.localizationService.formatDate(new Date(), "EEEE, MM/DD/YYYY") )
        
        me.apex(cmp,'getUserProfileName').then($A.getCallback(function(profileName){
            if(profileName == 'RiggsPharmacist') {
                cmp.set('v.currentTab',currentTab || "pharmacy")
            } else {
                cmp.set('v.currentTab',currentTab || "patients")
            }
        }))
        
        
        me.apex(cmp,'initializeComponentData').then($A.getCallback(function(data){
            cmp.set('v.showPharmacyTab',data.hasDispensingScriptsToProcessTab)
            cmp.set('v.showBulletinBoardTab', data.hasBulletinBoardTab)
            cmp.set('v.showScheduleTab', data.hasScheduleTab)
            cmp.set("v.showVarianceTab", "true");
        }))
    },
})
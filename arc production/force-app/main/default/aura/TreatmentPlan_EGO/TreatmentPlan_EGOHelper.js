({
    // Get Treatment Plan by ID
    getTreatmentPlanById:function(component,event,helper,treatmentPlanId) {
        helper.callApexMethod(
            component,
            "getTreatmentPlanById",
            { "treatmentPlanId" : treatmentPlanId },
            function (result) {
                if(result) {
                    component.set("v.treatmentPlan",result);
                    component.set("v.loading",false);
                }
            },
            null,
            true
        );
    },
    // This is for read only mode only.
    getTreatmentPlanByEGOId : function(component,event,helper,egoId) {
        let action = component.get("c.getTreatmentPlanByEGOId");
        action.setParams({
            "egoId" : egoId
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === "SUCCESS"){
                let result = response.getReturnValue();
                console.log("treatment plan:"+JSON.stringify(result));
                if(result) {
                    component.set("v.treatmentPlan",result);
                    component.set("v.loading",false);
                }
            }else if(state === "ERROR"){
                let errors = response.getError();
                if(errors != null && errors[0] != null){
                    console.log("errors:"+JSON.stringify(errors));
                }
            }
                    component.set("v.loading",false);
        });
        $A.enqueueAction(action);
        /*
        helper.callApexMethod(
            component,
            "getTreatmentPlanByEGOId",
            { "egoId" : egoId },
            function (result) {
                if(result) {
                    component.set("v.treatmentPlan",result);
                    component.set("v.loading",false);
                }
            },
            null,
            true
        );*/
    },
    // Conduct EGO / EGO-R
    conductEGO:function(component,event,helper,treatmentPlanId) {
        helper.callApexMethod(
            component,
            "conductEGO",
            { "treatmentPlanId" : treatmentPlanId },
            function (result) {
                if(result) {
                    /*
                    console.log('loaded treatmentplan:'+JSON.stringify(result));
                    var saveEGOButton = component.find("SaveEGOButton");
                    if(result.isEGOR == true){
                        if(!$A.util.isUndefined(saveEGOButton)){
                            saveEGOButton.set("v.label", "Save EGO-R");
                        }
                    }*/
                    console.log('loaded treatmentplan:'+JSON.stringify(result));
                    component.set("v.treatmentPlan",result);
                    component.set("v.loading",false);
                }
            },
            null,
            true
        );
    },
    // Save draft EGO
    saveDraftEGO:function(component,event,helper,treatmentPlan) {
        console.log('Ready to call saveDraftEGO:'+JSON.stringify(treatmentPlan));
        helper.callApexMethod(
            component,
            "saveDraftEGO",
            { "tPlan" : treatmentPlan },
            function (result) {
                console.log('Result:'+result);
                if(result=='SUCCESS') {
                    helper.showToast({
                        "title":"Save Successful",
                        "type":"success",
                        "message":"The EGO is saved successfully."
                    });
                    let treatmentPlan=component.get("v.treatmentPlan");
                    let urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/"+treatmentPlan.ego.Current_Treatment_Plan__c
                    });
                    
                    urlEvent.fire();
                }else{
                    var errorMap=JSON.parse(result);
                    for(var error in errorMap){
                        helper.showToast({
                            "title":"Error",
                            "type":"error",
                            "message":error
                        });
                    }
                    component.set("v.loading", false);
                }
            },
            null,
            true
        );
    },
    finalizeEGO:function(component,event,helper,treatmentPlan)
    {
        console.log('Ready to call savePlan:'+JSON.stringify(treatmentPlan));
        helper.callApexMethod(
            component,
            "finalizeEGOToDraftTreatmentPlan",
            { "tPlan" : treatmentPlan },
            function (resultJSON) {
                let result = JSON.parse(resultJSON);
                if(!$A.util.isUndefined(result.status)){
                    if(result.status === 'SUCCESS'){
                        helper.showToast({
                            "title":"Save Successful",
                            "type":"success",
                            "message":"Draft Treatment Plan Created."
                        });
                        var treatmentPlan=component.get("v.treatmentPlan");
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            // "url": "/"+treatmentPlan.ego.Current_Treatment_Plan__c
                            "url": "/"+treatmentPlan.ego.Id
                        });                        
                        urlEvent.fire();
                        //$A.get('e.force:refreshView').fire();
                    }
                }else{
                    var errorMap=JSON.parse(result);
                    for(var error in errorMap){
                        helper.showToast({
                            "title":"Error",
                            "type":"error",
                            "message":error
                        });
                    }
                    component.set("v.loading", false);
                }
            },
            null,
            true
        );
    }
})
({
    getTreatmentPlan:function(component,event,helper){
        let recordId= component.get("v.recordId");
        helper.callApexMethod(
            component,
            "getTreatmentPlan",
            { "caseId" : recordId },
            function (result) {
                if(result) {
                    component.set("v.treatmentPlan",result);
                    component.set("v.loading",false);
                    console.log('ViewTreatmentPlanHelper.getTreatmentPlan:Treatment Plan:',JSON.parse(JSON.stringify(result)));
                }
            },
            null,
            true
        );
    },
    // ARC-861, create draft treatment plan (team edit) without going through EGO
    createDraftTreatmentPlan : function (component, event, helper){
        let recordId= component.get("v.recordId");
        console.log("Create Draft Treatment Plan Record Id:"+recordId);
        helper.callApexMethod(
            component,
            "createDraftTreatmentPlanTeamEdit",
            { "currentTreatmentPlanId" : recordId },
            function (resultJSON) {
                console.log("result:"+resultJSON);
                let result = JSON.parse(resultJSON);
                console.log("result2:"+result.status);
                if(!$A.util.isUndefined(result.status)){
                    if(result.status === 'SUCCESS'){
                        var navEvt = $A.get("e.force:navigateToURL");
                        navEvt.setParams({
                            "url": "/"+result.draftTreatmentPlanId,
                            "isredirect":true
                        });
                        navEvt.fire();
                    }
                }else{
                    console.log('Create Draft Treatment Plan Stack Trace...');
                    let messages = '';
                    Object.keys(result).forEach(function(errorMessage){
                        messages += errorMessage + '\n';
                        console.log(result[errorMessage]);
                    });
                    helper.hideSpinner(component);
                }
            },
            null,
            true
        );
    },
    redirectOrRefresh: function(recordId){
        //$A.get("e.force:refreshView").fire();
        if( recordId ){
            $A.get("e.force:navigateToURL").setParams({ 
                "url": `/${recordId}`,
                "isredirect":true
             }).fire();
        }else{
            $A.get("e.force:refreshView").fire();
        }
    },

    // dannyDebug: function(debugObj){
    //     if ($A.get("$SObjectType.CurrentUser.Id") == '0052i000002THbpAAG'){
    //         alert(JSON.stringify(debugObj));
    //     }
    // },

    saveTreatmentPlan:function(component,event,helper)
    {
        let me = this;
        var draftTreatmentPlan=component.get("v.treatmentPlan");
        let draftTreatmentPlanString=JSON.stringify(draftTreatmentPlan);
        console.log('Draft Treatment Plan:'+draftTreatmentPlanString);
        helper.callApexMethod(
            component,
            "saveTreatmentPlan",
            { "draftTreatmentPlanString" : draftTreatmentPlanString },
            function (result) {
                if(result == 'SUCCESS') {
                    // var navEvt = $A.get("e.force:navigateToURL");
                    // navEvt.setParams({
                    //     "url": "/"+draftTreatmentPlan.currentTreatmentPlan.Id,
                    //     "isredirect":true
                    // });
                    //----------------me.dannyDebug({ log_title:'saveTreatmentPlan - Success Results', result });
                    // var navEvt = $A.get("e.force:navigateToSObject");
                    // navEvt.setParams({
                    //     "recordId": result.currentTreatmentPlanId
                    // });
                    // navEvt.fire();
                    let isEdit = component.get('v.edit');
                    if (isEdit ){
                        me.redirectOrRefresh();
                        component.set('v.edit',false);
                    }else{
                        let currentTreatmentPlanId = component.get('v.treatmentPlan.currentTreatmentPlan.Id');
                        let redirectId = result.currentTreatmentPlanId || currentTreatmentPlanId;
                        me.redirectOrRefresh( redirectId );
                    }                    
                } else //received a map of errors
                {
                    var resultMap = JSON.parse(result);
                    var msgText = '';

                    for (var key in resultMap)
                    {
                        msgText += 'Error:\n' + key + '\n\nStackTrace:\n' + resultMap[key];
                    }
                    var params = 
                    {
                        'title':    'Problem saving Treatment Plan',
                        'type':     'error',
                        'message':  msgText,
                        'mode':     'sticky'
                    };
                    helper.showToast(params);
                    component.set("v.loading", false);
                    //helper.hideSpinner(component);
                }
            },
            null,
            true
        );
    },
    saveTreatmentPlanAsComplete:function(component,event,helper)
    {
        let me = this;
        var draftTreatmentPlan=component.get("v.treatmentPlan");
        draftTreatmentPlan.Status='Completed';
        var draftTreatmentPlanString=JSON.stringify(draftTreatmentPlan);
        helper.callApexMethod(
            component,
            "saveTreatmentPlan",
            { "draftTreatmentPlanString" : draftTreatmentPlanString },
            function (result) {
                //me.dannyDebug({ log_title:'saveTreatmentPlanAsComplete', result });
                if(result) {
                    var navEvt = $A.get("e.force:navigateToURL");
                    navEvt.setParams({
                        "url": "/"+draftTreatmentPlan.currentTreatmentPlan.Id,
                        "isredirect":true
                    });
                    navEvt.fire();
                }
            },
            null,
            true
        );
    },
    finalizeTreatmentPlan:function(component,event,helper)
    {
        let me = this;
        component.set("v.loading",true);
        component.set("v.showFinalizeModal",false);
        var draftTreatmentPlan=component.get("v.treatmentPlan");
        
        // delete draftTreatmentPlan.therapist;

        var draftTreatmentPlanString=JSON.stringify(draftTreatmentPlan);
        helper.callApexMethod(
            component,
            "finalizeTreatmentPlan",
            { "draftTreatmentPlanString" : draftTreatmentPlanString },
            function (resultJSON) {
                console.log("resultJSON:"+resultJSON);
                let result = JSON.parse(resultJSON);
                console.log("result2:"+result.status);

                //me.dannyDebug({ log_title:'finalizeTreatmentPlan - Success Result', result });

                if(!$A.util.isUndefined(result.status)){
                    if(result.status === 'SUCCESS'){
                        // var navEvt = $A.get("e.force:navigateToURL");
                        // navEvt.setParams({
                        //     "url": "/"+result.currentTreatmentPlanId,
                        //     "isredirect":true
                        // });
                        // navEvt.fire();

                        let isEdit = component.get('v.edit');
                        console.log('isEdit : ' + isEdit);
                        if ( isEdit ){
                            me.redirectOrRefresh();
                            component.set('v.edit',false);
                        }else{
                            // me.redirectOrRefresh( result.currentTreatmentPlanId );
                            console.log('redirecting to result.draftTreatmentPlanId : ' + result.draftTreatmentPlanId);
                            me.redirectOrRefresh(result.draftTreatmentPlanId);
                        }     
                    }
                } else{
                    console.log('Finalize Draft Treatment Plan Stack Trace...');
                    let messages = '';
                    Object.keys(result).forEach(function(errorMessage){
                        messages += errorMessage + '\n';
                        console.log(result[errorMessage]);
                    });
                    helper.hideSpinner(component);
                }
            },
            null,
            false
        );
    },
    validate: function(component, event, helper) {
        var isAllValid=true;
        var treatmentPlan=component.get("v.treatmentPlan");
        domainLoop:
        for(var domain in treatmentPlan.domains)
        {
            var goals=treatmentPlan.domains[domain].goals;
            console.log('Goals');
            if(!$A.util.isEmpty(goals))
            {
                for(var goal in goals)
                {
                    goals[goal].isLabelEmpty=false;
                    if($A.util.isEmpty(goals[goal].goalObj.Label__c))
                    {
                        goals[goal].isLabelEmpty=true;
                        isAllValid=false;
                    }
                    var objectives=goals[goal].objectives;
                    if(!$A.util.isEmpty(objectives))
                    {
                        for(var objective in objectives)
                        {
                            objectives[objective].isLabelEmpty=false;
                            if($A.util.isEmpty(objectives[objective].objectiveObj.Label__c))
                            {
                                objectives[objective].isLabelEmpty=true;
                                isAllValid=false;
                            }
                        }
                    }
                }
            }
        }
        if(!isAllValid)
        {
            helper.showToast({
                'title':'Incomplete Input Error',
                'message':'There seems to be something incompete.  Please check for messages in red.',
                'type':'error'
            });
            component.set("v.loading",false);
        }
        return isAllValid;
    },

    loadLatestFinalized : function(cmp, helper){        
        helper.callApexMethod( cmp, "getLatestFinalized",{ "caseId" : cmp.get('v.recordId') },function (results) {
            if(results){
                cmp.set('v.latestFinalized', results);
            }
        });
    },
})
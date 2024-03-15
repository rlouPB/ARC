({
    doInit : function(component, event, helper)
    {
		//helper.setParameterByName(component , event);
        let conductEGO = component.get('v.conductEGO');
        console.log('conductEGO:'+conductEGO);
        if(conductEGO == true){
            let parentRecordId = component.get('v.parentRecordId');
            console.log('treatmentPlanid:'+parentRecordId);
            helper.conductEGO(component,event,helper,parentRecordId);
        }else{
            let recordId = component.get('v.recordId');
            console.log('recordId:'+recordId);
            helper.getTreatmentPlanByEGOId(component, event, helper, recordId);
        }
    },
    handleSaveEGO : function(component, event, helper){
        console.log("TreatmentPlan_EGOController.js handleSaveEGO");
        component.set("v.loading", true);
        let treatmentPlan=component.get('v.treatmentPlan');
        helper.saveDraftEGO(component,event,helper,treatmentPlan);
    },
    handleIsDirty:function(component, event, helper)
	{
    	component.set("v.isDirty", true);
    },
    handleSaveEGO : function(component, event, helper){
        component.set("v.loading", true);
        var treatmentPlan=component.get('v.treatmentPlan');
        helper.saveDraftEGO(component,event,helper,treatmentPlan);
    },
    handleEGOAction : function(component, event, helper){
        console.log('In TreatmentPlan_EGOController - handleEGOAction');
        let eventAction = event.getParam("action");
        if(!$A.util.isEmpty(eventAction)){
            if(eventAction == "Finalize"){
                console.log('eventAction : ' + eventAction);
                component.set("v.loading", true);
                let treatmentPlan=component.get('v.treatmentPlan');
                helper.finalizeEGO(component,event,helper,treatmentPlan);
            }
        }
    }
    /* Moved to sidebar - TreatmentPlan_EGO_Header

    ,handleSaveEGO : function(component, event, helper){
        component.set("v.loading", true);
        var treatmentPlan=component.get('v.treatmentPlan');
        helper.saveDraftEGO(component,event,helper,treatmentPlan);
    },
    finalizeEGO : function(component, event, helper){
        component.set("v.loading", true);
        component.set("v.showFinalizeModal", true);
        component.set("v.loading", false);
    },
    handleBackToDraftTreatmentPlan : function(component, event, helper){
        component.set("v.loading", true);
        component.set("v.showFinalizeModal", false);
        component.set("v.loading", false);
    },
    handleConfirmFinalizeEGO:function(component, event, helper)
    {
        component.set("v.loading", true);
        var saveEGOEvent=$A.get("e.c:SaveEGOEvent");
        saveEGOEvent.fire();
        var treatmentPlan=component.get('v.treatmentPlan');
        var isAllValid=true;
        domainLoop:
        for(var domain in treatmentPlan.domains)
        {
            var goals=treatmentPlan.domains[domain].goals;
            console.log('Goals');
            if(!$A.util.isEmpty(goals))
            {
                for(var goal in goals)
                {
                    console.log('Goal:'+goals[goal].goalObj.Id+', rating:'+goals[goal].rating);
                    if(treatmentPlan.isEGOR && !$A.util.isEmpty(goals[goal].goalObj.Id) &&
                       $A.util.isEmpty(goals[goal].rating))
                    {
                        console.log('is Goal rating Invalid');
                        isAllValid=false;
                        break domainLoop;
                    }
                    if($A.util.isEmpty(goals[goal].goalObj.Label__c))
                    {
                        console.log('is Goal label Invalid');
                        isAllValid=false;
                        break domainLoop;
                    }
                    var objectives=goals[goal].objectives;
                    if(!$A.util.isEmpty(objectives))
                    {
                        for(var objective in objectives)
                        {
                            if(treatmentPlan.isEGOR && !$A.util.isEmpty(objectives[objective].objectiveObj.Id) &&
                              $A.util.isEmpty(objectives[objective].rating))
                            {
                        console.log('is objective rating Invalid');
                                isAllValid=false;
                                break domainLoop;
                            }
                            if($A.util.isEmpty(objectives[objective].objectiveObj.Label__c))
                            {
                        console.log('is objective label Invalid');
                                isAllValid=false;
                                break domainLoop;
                            }
                        }
                    }
                }
            }
        }
        if(isAllValid)
        {
            helper.finalizeEGO(component,event,helper,treatmentPlan);
        }
        else
        {
            helper.showToast({
                'title':'Incomplete Input Error',
                'message':'There seems to be something incompete.  Please check for messages in red.',
                'type':'error'
            });
            component.set("v.loading", false);
        }
    },
    cancel : function(component, event, helper)
	{
        // helper.showSpinner(component);
        var isDirty = component.get("v.isDirty");
    	if(isDirty) {
    		component.set("v.showCancelModal", true);
        } else {
            let closeEvent = component.getEvent('closeModalEvent');
            closeEvent.fire();
        }
	},
    handleIsDirty:function(component, event, helper)
	{
    	component.set("v.isDirty", true);
	},
    handleDiscardChanges: function(component, event, helper) {
        component.set("v.showCancelModal", false);
        let closeEvent = component.getEvent('closeModalEvent');
        closeEvent.fire();
    },
    handleBackToEGO: function(component, event, helper) {
        component.set("v.showCancelModal", false);
    }*/
})
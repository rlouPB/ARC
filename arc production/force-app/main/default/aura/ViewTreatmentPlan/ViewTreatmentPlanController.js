({
    doInit : function(component, event, helper) {
        component.set('v.loading', true);
		helper.getTreatmentPlan(component,event,helper);
        helper.loadLatestFinalized(component, helper);
    },
    finalize: function(cmp, event, helper) {

    }, 
    edit: function(cmp, event, helper) {
        cmp.set('v.edit', true); 
    },
        // This only save the plan with changes with changing Case status to "Completed"
    saveAsComplete:function(component,event,helper){
        //TODO - Save all and changing the status to complete
        var treatmentPlan=component.get("v.treatmentPlan");
        treatmentPlan.currentTreatmentPlan.Status='Completed';
        component.set("v.treatmentPlan",treatmentPlan);
        helper.saveTreatmentPlan(component,event,helper);
    },
    cancel: function(cmp, event, helper) {
        cmp.set('v.edit', false); 
    },
    addGoal: function(cmp, event, helper) {

        let id = event.getSource().get("v.value")

        let domains = cmp.get('v.domains');
        let domainGoals = domains.map(domain => {
            console.log(domain, id); 
            if(domain.domain == id) {
                domain.newGoal = true; 
            }

            return domain;

        }); 

        cmp.set('v.domains', domainGoals);

    },
    handleTreatmentPlanEdit: function(component, event, helper) {
        let action=event.getParam("action");
        switch(action){
            case "createDraftTreatmentPlanTeamEdit":
                component.set("v.showCreateDraftTreatmentPlanTeamEditModal", true);
                break;
            case "save":
                component.set("v.loading",true);
                if(helper.validate(component,event,helper))
                {
                    helper.saveTreatmentPlan(component,event,helper);
                }
                break;
            case "saveAsComplete":
                component.set("v.loading",true);
                if(helper.validate(component,event,helper))
                {
                    component.set("v.showSaveAsCompleteModal", true);
                    component.set("v.loading",false);
                }
                break;
            case "finalizeTreatmentPlan":
                component.set("v.loading",true);
                if(helper.validate(component,event,helper))
                {
                    component.set("v.showFinalizeModal", true);
                    component.set("v.loading",false);
                }
                break;
            case "cancelEdit":
                var draftTreatmentPlan=component.get("v.treatmentPlan");    
                var navEvt = $A.get("e.force:navigateToURL");
                navEvt.setParams({
                    "url": "/"+draftTreatmentPlan.currentTreatmentPlan.Id,
                    "isredirect":true
                });
                navEvt.fire();
                break;
        }
    },
            handleConfirmSaveAsComplete:function(component,event,helper)
            {
                helper.saveTreatmentPlanAsComplete(component,event,helper);
            },
            handleConfirmFinalize:function(component,event,helper)
            {
                helper.finalizeTreatmentPlan(component,event,helper);
            },
            handleConfirmCreateTreatmentPlanTeamEdit : function (component, event, helper){
                helper.showSpinner(component);
                // component.set("v.showCreateDraftTreatmentPlanTeamEditModal", false);
                helper.createDraftTreatmentPlan(component, event, helper);
            },
            handleBackToDraftTreatmentPlan:function(component,event,helper)
            {
                component.set("v.showSaveAsCompleteModal", false);
                component.set("v.showFinalizeModal", false);
            },
            handleCancelCreateDraftTreatmentPlanTeamEdit : function(component,event,helper)
            {
                component.set("v.showCreateDraftTreatmentPlanTeamEditModal", false);
            }
})
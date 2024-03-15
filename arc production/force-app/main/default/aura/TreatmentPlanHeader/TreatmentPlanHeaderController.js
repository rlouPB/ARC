({
    onGoalChange: function(cmp, event, helper) {
        var id = event.getSource().get('v.name');
        let val = cmp.get('v.treatment.Goal__c');

        let e = $A.get("e.c:TreatmentPlanEditEvent");

        e.setParams({
            "id": id, 
            "sObject": 'Case',
            "field": 'Goal__c',
            "value": val
        });

        e.fire(); 
    },
    save:function(component,event,helper)
    {
        var unsaved = component.find("unsaved");
        unsaved.setUnsavedChanges(false);
        let planAction=component.getEvent("treatmentPlanEditEvent");
        planAction.setParams({
            "action":"save"
        });
        planAction.fire();
    },
    saveAsComplete:function(component,event,helper)
    {
        var unsaved = component.find("unsaved");
        unsaved.setUnsavedChanges(false);
        let planAction=component.getEvent("treatmentPlanEditEvent");
        planAction.setParams({
            "action":"saveAsComplete"
        });
        planAction.fire();
    },
    finalizeTreatmentPlan:function(component,event,helper)
    {
        let planAction=component.getEvent("treatmentPlanEditEvent");
        planAction.setParams({
            "action":"finalizeTreatmentPlan"
        });
        planAction.fire();
    },
    cancelEdit:function(component, event, helper)
    {
        component.set('v.showCancelEditModal', true);
    },
    editGoalsAndObjectives:function(component,event,helper)
    {
    	var isEdit = component.get("v.edit");
        if(!isEdit) {
            var unsaved = component.find("unsaved");
            unsaved.setUnsavedChanges(true, { label: 'the Treatment Plan' });
        }
        component.set("v.edit",true);
    },
    handleDiscardEditChanges: function(component, event, helper)
    {
        var unsaved = component.find("unsaved");
        unsaved.setUnsavedChanges(false);
        let planAction=component.getEvent("treatmentPlanEditEvent");
        planAction.setParams({
            "action":"cancelEdit"
        });
        planAction.fire();
    },
    handleBackToEditing: function(component, event, helper)
    {
        component.set('v.showCancelEditModal', false);
    },
    handleDiscardEGOChanges:function(component,event,helper)
    {
        var unsaved = component.find("unsaved");
        unsaved.setUnsavedChanges(false);
        helper.handleDiscardEGOChanges(component,event,helper);
    },
    handleBackToEGO: function(component, event, helper)
    {
        component.set('v.showCancelModal', false);
    },
    conductEGO:function(component,event,helper)
    {
        let treatmentPlan=component.get("v.treatmentPlan");
        treatmentPlan.isCreateDraftTreatmentPlanTeamEditAllowed = false;
        component.set("v.treatmentPlan", treatmentPlan);
        component.set("v.showConductEGOModal",true);
    },
    handleCreateDraftTreatmentPlan : function (component, event, helper){
        let planAction=component.getEvent("treatmentPlanEditEvent");
        planAction.setParams({
            "action":"createDraftTreatmentPlanTeamEdit"
        });
        planAction.fire();
    },
    onCloseViewInterventionsHandler: function(cmp){
        cmp.set("v.showInterventionsModal",false);
    },
    handleCloseModal:function(component,event,helper)
    {
        /*
        var instanceName=event.getParam("data");
        console.log('instance name:'+instanceName);
        if(instanceName=='ConductEGOModal'){
            var egoComponent=component.find("EGO");
            egoComponent.cancel();
        }else{
            component.set("v.showConductEGOModal",false);
        }*/
        $A.get('e.force:refreshView').fire();
        var data = event.getParam('data');
        var instanceName = data;
        if (data.instanceName)
        {
            instanceName = data.instanceName;
        }
        console.log('instance name:'+instanceName);
        if(instanceName=='ConductEGOModal')
        {
            if (data.isDirty === false)
            {
                helper.handleDiscardEGOChanges(component,event,helper);
            } else
            {
                component.set("v.showCancelModal",true);
            }
        }else if(instanceName == 'ViewInterventionsModal'){
            component.set("v.showInterventionsModal",false);
        }else if (instanceName = 'cancelEGO')
        {
            component.set('v.showCancelModal', false);
        }
    },
    handleReviewDraftTreatmentPlan:function(component,event,helper)
    {
        var treatmentPlan=component.get("v.treatmentPlan");
        console.log('draft treatment plan ID:'+treatmentPlan.unfinalizedDraftTreatmentPlanId);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/"+treatmentPlan.unfinalizedDraftTreatmentPlanId,
            " isredirect":true
        });
        urlEvent.fire();
    },
    handleViewIntervnetions:function(component,event,helper)
    {
        component.set("v.showInterventionsModal",true);
    },
    handleOnClickEditOverallGoal:function(component,event,helper)
    {
        component.set("v.isOverallGoalDisable",false);
    },

    printEgo : function (component, event, helper) {
        // let treatmentPlan = JSON.parse(JSON.stringify(component.get("v.treatmentPlan")));
        let treatmentPlan = component.get("v.treatmentPlan");
        console.log("#### treatmentPlan ----> ", treatmentPlan);

        if (treatmentPlan.currentTreatmentPlan.Status !== "Finalized") {
            let saveEGOEvent=$A.get("e.c:SaveEGOEvent");
            saveEGOEvent.fire();
        }

        // var urlEvent = $A.get("e.force:navigateToURL");
        // urlEvent.setParams({
        //   "url": "/apex/SDOC__SDCreate1?id="+ treatmentPlan.ego.Id +"&Object=EGO__c&doclist=EGO_PDF&autoopen=0"
        // });
        // urlEvent.fire();

        // let urlval = "/apex/SDOC__SDCreate1?id="+ treatmentPlan.ego.Id +"&Object=EGO__c&doclist=EGO_PDF&autoopen=0";
        
        //let urlval = "/apex/SDOC__SDCreate1?id="+ treatmentPlan.currentTreatmentPlan.Id +"&Object=Case&doclist=TreatmentPlanHTML&autoopen=0";

        let urlval = treatmentPlan.currentTreatmentPlan.Print_Link__c.split('"')[1].replaceAll(
            "&amp;",
            "&"
          );
        window.open(urlval, '_blank');
    }
})
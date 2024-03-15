({
	handleDiscardEGOChanges:function(component,event,helper)
    {
        var treatmentPlan=component.get("v.treatmentPlan");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/"+treatmentPlan.currentTreatmentPlan.Id
        });
        
        console.log('TreatmentPlanHeaderController.cancel: treatment plan ID:'+treatmentPlan.currentTreatmentPlan.Id);
        urlEvent.fire();
    },
})
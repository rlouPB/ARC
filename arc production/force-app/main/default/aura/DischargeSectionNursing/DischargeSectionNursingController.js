({
    doInit:function(component, event, helper)
    {
		component.set("v.instanceName","Nursing");
	},
    handleSectionActionEvent:function(component,event,helper)
    {
        var dischargeSection=component.get("v.dischargeSection");
        var action=event.getParam("action");
        switch(action){
            case "completed":
                dischargeSection.dischargeSectionObj.Status__c='Completed';
                helper.saveDischargeSection(component,event,helper,dischargeSection);
                break;
            case "save":
                helper.saveDischargeSection(component,event,helper,dischargeSection);
                break;
            case "reopen":
                helper.reopenDischargeSection(component,event,helper,dischargeSection);
                break;
        }
    }
})
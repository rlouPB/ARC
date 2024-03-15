({
    doInit:function(component, event, helper)
    {
        var startTime=Date.now();
        component.set("v.loading",true);
        var responsiblePersonFilter = [
            {
                'fieldName': 'Name',
                'condition': '=',
                'value': 'User'
            }    
        ];
        var dischargeSection=component.get("v.dischargeSection");
        helper.calculatePermission(component,event,helper);
        console.log(dischargeSection.dischargeSectionObj.Role__c+' from start Time until now:'+((Date.now()-startTime)/1000+'s'));
        helper.setFilters(component,event,helper);
        component.set("v.loading",false);
	},
    handleChangeResponsiblePerson:function(component, event, helper)
    {
        // component.set("v.loading",true);
        var dischargeSection=component.get("v.dischargeSection");
        dischargeSection.dischargeSectionObj.OwnerId=null;
        component.set("v.dischargeSection",dischargeSection);
        component.set("v.isResponsiblePersonChangeClicked",true);
        component.set("v.loading",false);
	},
    handleUpdateResponsiblePerson:function(component, event, helper)
    {
        component.set("v.loading",true);
        component.set("v.isLoading",true);
        component.set('v.hideReferrals', true);
        var dischargeSection=component.get("v.dischargeSection");
        var selectedResponsiblePerson=component.get("v.selectedResponsiblePerson");
        dischargeSection.responsiblePerson = selectedResponsiblePerson.label;
        if(!$A.util.isEmpty(selectedResponsiblePerson))
        {
            dischargeSection.dischargeSectionObj.OwnerId=selectedResponsiblePerson.value;
            
            component.set("v.isResponsiblePersonChanged",true);
            component.set("v.dischargeSection",dischargeSection);
            helper.saveDischargeSection(component,event,helper,dischargeSection);
        }
        else
        {
            dischargeSection.dischargeSectionObj.OwnerId=null;
            component.set("v.dischargeSection",dischargeSection);
            component.set("v.loading", false);
            component.set("v.isLoading", false);
            component.set('v.hideReferrals', false);
        }
	},
    handleSaveDischargeSection:function(component, event, helper)
    {
        component.set("v.isLoading",true);
        component.set("v.loading",true);
        var dischargeSection = component.get('v.dischargeSection');
		//helper.fireActionEvent(component,event,helper,"save");
        helper.saveDischargeSection(component,event,helper,dischargeSection);
	},
    handleReopenDischargeSection:function(component, event, helper)
    {
        component.set("v.isLoading",true);
        component.set("v.loading",true);
		helper.fireActionEvent(component,event,helper,"reopen");
	},
    handleMarkSectionComplete:function(component, event, helper)
    {
        component.set("v.showMarkCompleteModal", true);
	},
    handleConfirmMarkAsComplete:function(component, event, helper)
    {
        component.set("v.showMarkCompleteModal", false);
        if(helper.validateReferral(component,event,helper))
        {
            component.set("v.isLoading",true);
            component.set("v.loading",true);
            helper.fireActionEvent(component,event,helper,"completed");
        }
    },
    handleBackToSection:function(component, event, helper)
    {
        component.set("v.showMarkCompleteModal", false);
    }
})
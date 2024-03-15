({
	doInit:function(component,event,helper)
    {
        component.set("v.isLoading",true);
        component.set("v.loading",true);
        var recordId = component.get("v.recordId");
        // helper.setFilters(component,event,helper);
        if($A.util.isEmpty(recordId))
        {
            var value = helper.getParameterByName(component , event, 'inContextOfRef');
            if(value) {
                var context = JSON.parse(window.atob(value));
                if(!$A.util.isEmpty(context.attributes.recordId))
                {
                    component.set("v.parentRecordId", context.attributes.recordId);
                    helper.getPatient(component,event,helper);
                }
                // var responsibleSocialWorkerFilter=[
                //     {
                //         'fieldName': 'TeamRole.Name',
                //         'condition': '=',
                //         'value': 'Social Worker'
                //     }];
                //     component.set("v.responsibleSocialWorkerFilter", responsibleSocialWorkerFilter);
                // component.set("v.isLoading",false);
                // component.set("v.loading",false);
                // helper.setFilters(component,event,helper);
            }
        }
        else
        {   
            helper.getDischargeDisposition(component,event,helper,recordId);
        }
	},
    // handleDischargeTypeChange:function(component,event,helper)
    // {
    //     component.set("v.loading",true);
    //     helper.createDischargeDisposition(component,event,helper);
    // },
    handleDischargeDispositionAction: function(component,event,helper) {
        var actionType = event.getParam("actionType");
        switch(actionType) {
            case "Cancel":
                component.set("v.showCancelModal", true);
                break;
            case "Save":
                component.set("v.loading",true);
                helper.saveDischargeDisposition(component,event,helper);
                break;
            case "Finalize":
                helper.handleFinalizeDischarge(component,event,helper);
                break;
            case "Print":
                helper.handlePrintDischarge(component,event,helper);
                break;
            case "PrintDraft":
                helper.handlePrintDraftDischarge(component,event,helper);
                break;
            case "Refresh":
                helper.refreshDischargeDisposition(component, event, helper);
                break;
            case "ReOpen":
                helper.handleReOpenDischargeDisposition(component, event, helper);
                break;
          }
    },
    handleCancelDischarge:function(component,event,helper)
    {
        component.set("v.showCancelModal", true);
    },
    
    handleSaveDischarge:function(component,event,helper)
    {
        component.set("v.loading",true);
        helper.saveDischargeDisposition(component,event,helper);
    },
    handleDischargeSectionReopend:function(component,event,helper)
    {
        var dischargeSection=event.getParam("dischargeSection");
        var dischargeDisposition=component.get("v.dischargeDisposition");
        console.log("handleDischargeSectionReopend, dischargeDisposition.dischargeSectionList:"+(JSON.stringify(dischargeDisposition.dischargeSectionList)));
        console.log("handleDischargeSectionReopend, discharge section index:"+dischargeSection.sectionDisplayIndex);
        dischargeDisposition.dischargeSectionList[dischargeSection.sectionDisplayIndex]=dischargeSection;
        component.set("v.dischargeDisposition",dischargeDisposition);
    },
    handleConfirmReOpen:function(component, event, helper) {
        component.set("v.loading",true);
        component.set("v.showReOpenModal", false);
        helper.reopenDischargeDisposition(component,event,helper);
    },
    handleFinalizeDischarge:function(component,event,helper)
    {
        component.set("v.loading",true);
        var dischargeDisposition=component.get("v.dischargeDisposition");
        if(!$A.util.isEmpty(dischargeDisposition.dischargeSectionList))
        {
            var hasIncompletedSection=false;
            for(var dischargeSection in dischargeDisposition.dischargeSectionList)
            {
                console.log(dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Role__c+' status:'+dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Status__c);
                //var isEditable = component.find(dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Role__c).get("v.isEditable");
                //if(isEditable && dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Status__c!='Completed')
                if(dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Status__c!='Completed')
                {
                    hasIncompletedSection=true;
                    break;
                }
            }
            if(hasIncompletedSection)
            {
                helper.showToast({
                    "title":"Incomplete Sections",
                    "message":"Discharge Disposition cannot be finalized until all sections are completed.",
                    "type":"warning"
                });
                component.set("v.loading",false);
            }
            else
            {
                component.set("v.showFinalizeModal", true);
                component.set("v.loading",false);
            }
        }
    },
    handleConfirmCancel:function(component, event, helper) {
        component.set("v.loading",true);
        component.set("v.showCancelModal", false);
        helper.cancelDischargeDisposition(component,event,helper);
    },
    handleConfirmFinalize:function(component, event, helper) {
        component.set("v.loading",true);
        component.set("v.showFinalizeModal", false);
        helper.finalizeDischargeDisposition(component,event,helper);
    },
    handleBackToDischargeDisposition:function(component, event, helper) {
        component.set("v.showCancelModal", false);
        component.set("v.showFinalizeModal", false);
    },
    handleConfirmPrintDraft:function(component, event, helper) {
        var selectedValue=  component.find("purpose").get("v.value");
        var recordId = component.get("v.recordId");
        window.open('/apex/PrintDraftDDR?Id=' + recordId + '&isDraft=true&purpose='+selectedValue, "_self");
        component.set("v.showPrintDraftModal", false);
    },
    
})
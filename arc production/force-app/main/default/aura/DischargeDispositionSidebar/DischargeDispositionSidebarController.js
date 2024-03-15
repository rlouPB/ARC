({
    doInit:function(component, event, helper) {

    },
    handleCancelDischarge: function(component, event, helper) {
        var compEvent = component.getEvent("DischargeDispositionActionEvent");
        compEvent.setParams({
            actionType: "Cancel"
        });
        compEvent.fire();
    },
    handleSaveDischarge: function(component, event, helper) {
        var compEvent = component.getEvent("DischargeDispositionActionEvent");
        compEvent.setParams({
            actionType: "Save"
        });
        compEvent.fire();
    },
    handleFinalizeDischarge: function(component, event, helper) {
        var compEvent = component.getEvent("DischargeDispositionActionEvent");
        compEvent.setParams({
            actionType: "Finalize"
        });
        compEvent.fire();
    },
    handlePrintDischarge: function(component, event, helper) {
        var compEvent = component.getEvent("DischargeDispositionActionEvent");
        compEvent.setParams({
            actionType: "Print"
        });
        compEvent.fire();
    },
    handlePrintDraftDischarge: function(component, event, helper) {
        var compEvent = component.getEvent("DischargeDispositionActionEvent");
        compEvent.setParams({
            actionType: "PrintDraft"
        });
        compEvent.fire();
    },
    
    handleReOpenDischarge: function(component, event, helper) {
        debugger;
        var compEvent = component.getEvent("DischargeDispositionActionEvent");
        compEvent.setParams({
            actionType: "ReOpen"
        });
        compEvent.fire();
    },
    
    
})
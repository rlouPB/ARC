/* eslint-disable no-unused-expressions */
({
    doInit: function(component, event, helper) {
        helper.loadData(component, event, helper);
    },

    reloadData: function(component, event, helper) {
        helper.loadData(component, event, helper);
    },

    sortByName: function(component, event, helper) {
        let target = event.currentTarget;
        let columnName = target.getAttribute("data-columnName");
        helper.sortBy(component, columnName);
    },

    handleShowManageModal: function(component, event, helper) {
        component.set("v.showManageModal", true);
    },

    hideManageModal: function(component, event, helper) {
        component.set("v.showManageModal", false);
    },

    handleCloseModalEvent: function(component, event, helper) {
        // component.find('overlayLib').notifyClose();

        helper.loadData(component, event, helper);
        component.set("v.showManageModal", false);
    },

    handleRefreshButtonClick: function(component, event, helper) {
        helper.loadData(component, event, helper);
    },

    //something else on the Lightning page updated the Admission
    handleRefreshPatient: function(component, event, helper) {
        var eventParams = event.getParams();

        // if(eventParams.changeType === "LOADED") {
        //     component.set("v.isRecordLoaded",true);
        //     // window.setTimeout($A.getCallback(function() {
        //     //     helper.toggleSpinner(component, 0);
        //     // }),1000);
        // } else
        if (eventParams.changeType === "CHANGED") {
            //reload when any of these three records is updated
            component.find("recordLoader").reloadRecord(true);
            // helper.toggleSpinner(component, 0);
        }
    },

    handleActiveDietician: function(component, event, helper) {
        let checked = event.getParam("checked");
        helper.updateDietician(component, checked);
    },

    handleActiveSUS: function(component, event, helper) {
        let checked = event.getParam("checked");
        helper.updateSUS(component, checked);
    },

    saveAssignedClinicians: function(component, event, helper) {
        var childCmp = component.find("manageClinicians");
        childCmp.saveClinicians();
    }
});
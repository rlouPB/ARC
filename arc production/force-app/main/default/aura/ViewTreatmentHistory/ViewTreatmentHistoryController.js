/* eslint-disable vars-on-top */
/* eslint-disable no-unused-vars */
/* eslint-disable no-unused-expressions */
({
    doInit: function(component, event, helper) {
        let columns = [
            // {label : "Type", fieldName : "type", type : "text", hideDefaultActions: true, "sortable": true},
            {
                label: "Date",
                fieldName: "itemDate",
                type: "date",
                typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    timeZone: "UTC"
                },
                sortable: true
            },
            {
                label: "Details",
                fieldName: "details",
                type: "text",
                wrapText: true,
                sortable: true
            },
            {
                label: "Recorded By",
                fieldName: "recorded",
                type: "text",
                sortable: true
            },
            {
                label: "Link",
                fieldName: "URL",
                type: "url",
                typeAttributes: {
                    label: { fieldName: "urlLabel" },
                    target: "_blank"
                },
                sortable: true
            },
            {
                label: "FInalized Date",
                fieldName: "finalizedDateTime",
                type: "date",
                typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    timeZone: "UTC"
                },
                sortable: true
            }
        ];
        // {label : "Item", fieldName : "item", type : "text"},
        component.set("v.columns", columns);
        helper.hideSpinner(component);
    },
    handleViewTreatmentHistoryModal: function(component, event, helper) {
        component.set("v.showViewTreatmentHistoryModal", true);
        helper.showSpinner(component);
        helper.getTreatmentHistory(component, event, helper, 0);
    },
    handleRecordSelection: function(component, event, helper) {
        let selectedItem = event.currentTarget;
        let selectedRecordId = selectedItem.dataset.recordId;
        let selectedRecordObjectName = selectedItem.dataset.recordName;
        component.set("v.selectedRecordId", selectedRecordId);
        component.set("v.selectedRecordObjectName", selectedRecordObjectName);
    },
    handleSelectOptionSet: function(component, event, helper) {
        helper.showSpinner(component);
        var currentViewOptionSetParsed = component.get("v.currentViewOptionSet");
        var viewOptionSetList = component.get("v.viewOptionSetList");
        var newCurrentViewOptionSetId = event.getSource().get("v.value");
        var newCurrentViewOptionSet = viewOptionSetList.find(function(element) {
            return element.optionSetObj.Id == newCurrentViewOptionSetId;
        });

        newCurrentViewOptionSet.isDifferentOptionSet = true;
        newCurrentViewOptionSet.changedFromServer = false;
        component.set("v.currentViewOptionSet", newCurrentViewOptionSet);
    },
    handleRefreshButtonClick: function(component, event, helper) {
        helper.showSpinner(component);

        var currentViewOptionSetParsed = component.get("v.currentViewOptionSet");
        currentViewOptionSetParsed.isDifferentOptionSet = true;
        currentViewOptionSetParsed.changedFromServer = false;
        component.set("v.currentViewOptionSet", currentViewOptionSetParsed);
    },
    handleDateChange: function(component, event, helper) {
        helper.clearSelection(component, event, helper);
        component.set("v.selectedDateRange", "Custom");
        helper.getTreatmentHistory(component, event, helper, 0);
    },
    handleDateRangeSelection: function(component, event, helper) {
        helper.clearSelection(component, event, helper);
        helper.getTreatmentHistory(component, event, helper, 0);
    },
    handleMoveRangeBackMonth: function(component, event, helper) {
        console.log("moving back");
        helper.clearSelection(component, event, helper);
        component.set("v.selectedDateRange", "Custom");
        helper.getTreatmentHistory(component, event, helper, -1);
    },
    handleMoveRangeForwardMonth: function(component, event, helper) {
        console.log("moving forward");
        helper.clearSelection(component, event, helper);
        component.set("v.selectedDateRange", "Custom");
        helper.getTreatmentHistory(component, event, helper, 1);
    },
    handleSelectedOptionItem: function(component, event, helper) {
        helper.clearSelection(component, event, helper);
        let currentViewOptionSet = component.get("v.currentViewOptionSet");
        console.log(
            "handleSelectedOptionItem currentViewOptionSet:" +
            JSON.stringify(currentViewOptionSet)
        );
        helper.getTreatmentHistory(component, event, helper, 0);
    },
    handleCloseModal: function(component, event, helper) {
        let instanceName = event.getParam("data");
        console.log("instanceName:" + instanceName);
        if (instanceName == "ViewTreatmentHistoryModal") {
            component.set("v.selectedRecordId", null);
            let selectedRecordForm = component.find("selectedRecordForm");
            if (!$A.util.isEmpty(selectedRecordForm)) {
                selectedRecordForm.set("v.objectApiName", "");
            }
            component.set("v.showViewTreatmentHistoryModal", false);
        }
    },
    handleRowSelection: function(component, event, helper) {
        let selectedRows = event.getParam("selectedRows");
        console.log("selectedRows:" + JSON.stringify(selectedRows));
        if (!$A.util.isEmpty(selectedRows) && !$A.util.isEmpty(selectedRows[0])) {
            let selectedRow = selectedRows[0];
            let historyItemIdMap = component.get("v.historyItemIdMap");
            let historyItem = historyItemIdMap[selectedRow.Id];
            console.log(
                "selectedRow:" +
                JSON.stringify(selectedRow) +
                ", history Item:" +
                JSON.stringify(historyItem)
            );
            if (!$A.util.isEmpty(historyItem)) {
                component.set("v.selectedRecordId", selectedRow.Id);
                component.set(
                    "v.selectedRecordObjectName",
                    historyItem.definition.Sobject__c
                );
                let treatmentHistorySelectedEvent = $A.get(
                    "e.c:TreatmentHistorySelectedEvent"
                );
                let componentName = null;
                if (historyItem.definition.Display_Component_Name__c) {
                    componentName = historyItem.definition.Display_Component_Name__c;
                }
                let componentParameters = null;
                if (historyItem.definition.Display_Component_Parameters__c) {
                    componentParameters = JSON.parse(
                        historyItem.definition.Display_Component_Parameters__c
                    );
                }
                let queryFields = historyItem.definition.Query_Fields__c;

                treatmentHistorySelectedEvent.setParams({
                    selectedRecordId: selectedRow.Id,
                    selectedRecordObjectName: historyItem.definition.Sobject__c,
                    componentName: componentName,
                    componentParameters: componentParameters,
                    queryFields: queryFields
                });
                console.log(
                    "Firing treatmentHistorySelectedEvent:" +
                    treatmentHistorySelectedEvent
                );
                treatmentHistorySelectedEvent.fire();
            } else {
                // TODO - Error Message that the history item is not found, reload
            }
        }
    },
    handleCollapseExpand: function(component, event, helper) {
        component.set("v.sidebarExpanded", !component.get("v.sidebarExpanded"));
    },
    handleSort: function(cmp, e, h) {
        h.handleSort(cmp, e);
    }
});
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
    clearSearch: function(component, helper) {
        // console.log("LookupComponentHelper clearSearch...");
        helper.showSearchIcon(component);
        helper.showInput(component);
        helper.hidePill(component);

        var instanceName = component.get("v.instanceName");
        var selectedRecord = component.get("v.selectedRecord");

        var compEvent = component.getEvent("removedItemEvent");
        compEvent.setParams({
            sourceInstanceName: instanceName,
            selectedObj: selectedRecord
        });
        compEvent.fire();

        component.set("v.SearchKeyWord", null);
        component.set("v.listOfSearchRecords", null);
        component.set("v.lookupFieldName", null);
        component.set("v.selectedRecord", {});
    },

    closeMenu: function(component) {
        // console.log("LookupComponentHelper closeMenu...");
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, "slds-is-close");
        $A.util.removeClass(forclose, "slds-is-open");
    },

    //It create component on Additional option's click.
    createAdditionalOptionComponent: function(component, componentName, attr) {
        // console.log("LookupComponentHelper createAdditionalOptionComponent...");
        $A.createComponent(
            componentName,
            attr,
            function(newCmp, status, errorMessage) {
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    component.find("optionComponent").set("v.body", newCmp);

                    //component.set("{!v.body}", newAssessment);
                } else if (status === "INCOMPLETE") {
                    // Show offline error
                } else if (status === "ERROR") {
                    // Show error message
                }
            }
        );
    },

    fillPill: function(component, selectedObj, helper) {
        // console.log("LookupComponentHelper fillPill...");
        if (selectedObj) {
            if (!selectedObj.value) {
                selectedObj.value = "";
            }
            var fillPillOnSelect = component.get("v.fillPillOnSelect");
            if (!fillPillOnSelect) {
                selectedObj.isRecord = false;
                component.set("v.SearchKeyWord", selectedObj.value);
            }
        }
        component.set("v.lookupFieldName", selectedObj.value);
        component.set("v.selectedRecord", selectedObj);

        let valError = component.get("v.validationError");
        valError.show = false;
        component.set("v.validationError", valError);

        helper.showInput(component);

        this.fillPillOnly(component, selectedObj, helper);
    },

    fillPillOnly: function(component, selectedObj, helper) {
        // console.log("LookupComponentHelper fillPillOnly...");
        helper.closeMenu(component);
        helper.hideSearchIcon(component);

        var fillPillOnSelect = component.get("v.fillPillOnSelect");
        if (fillPillOnSelect) {
            helper.showPill(component);
            helper.hideInput(component);
        } else {
            helper.hidePill(component);
            helper.showInput(component);
        }
    },

    fireAdditionalOptionEvent: function(component, eventName, attr) {
        // console.log("LookupComponentHelper fireAdditionalOptionEvent...");
        var evt = $A.get("e." + eventName);
        evt.setParams(attr);
        evt.fire();
    },

    // Gets the existing record
    getExistingRecord: function(
        component,
        event,
        objName,
        dispField,
        dispFieldVal,
        existingId
    ) {
        // console.log("LookupComponentHelper getExistingRecord...");
        var helper = this;
        var action = component.get("c.getRecord");
        action.setParams({
            objectName: objName,
            displayField: dispField,
            displayFieldValue: dispFieldVal,
            currentRecordId: existingId
        });

        // set a callBack
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.loading", false);
                var selectedObj = JSON.parse(response.getReturnValue());
                if (selectedObj && selectedObj.isRecord === true) {
                    this.fillPill(component, selectedObj, helper);
                    event.stopPropagation();
                }
            } else {
                var message = this.stringifyErrors(response);
                alert(
                    "An unexpected error occured while getting the existing record. Error: " +
                    message
                );
                component.set("v.loading", false);
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    },

    hideInput: function(component) {
        // console.log("LookupComponentHelper hideInput...");
        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, "slds-hide");
        $A.util.removeClass(lookUpTarget, "slds-show");
    },

    hidePill: function(component) {
        // console.log("LookupComponentHelper hidePill...");
        var pillTarget = component.find("lookup-pill");
        $A.util.addClass(pillTarget, "slds-hide");
        $A.util.removeClass(pillTarget, "slds-show");
    },

    hideSearchIcon: function(component) {
        // console.log("LookupComponentHelper hideSearchIcon...");
        var searchIcon = component.find("searchIcon");
        $A.util.addClass(searchIcon, "slds-hide");
        $A.util.removeClass(searchIcon, "slds-show");
    },

    noPillStartSearch: function(component, helper) {
        // console.log("LookupComponentHelper noPillStartSearch...");
        helper.hidePill(component);
        helper.showSearchIcon(component);
        helper.showInput(component);
    },

    openMenu: function(component) {
        // console.log("LookupComponentHelper openMenu...");
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, "slds-is-open");
        $A.util.removeClass(forclose, "slds-is-close");
    },

    //Used for fetch records
    searchHelper: function(component, event, getInputkeyWord, helper) {
        // console.log("LookupComponentHelper searchHelper...");
        // call the apex class method
        var action = component.get("c.fetchRecords");
        var filters = component.get("v.filters");
        let serializedFilters = JSON.stringify(filters);
        var filterStr = "";

        for (var i = 0; i < filters.length; i++) {
            if (filters[i].fieldName && filters[i].condition && filters[i].value) {
                let filterValue = filters[i].value;
                if (
                    filterValue === true ||
                    filterValue === false ||
                    filters[i].condition.toUpperCase() == "IN"
                ) {
                    //no quotes for literal Booleans or IN SET
                } else {
                    filterValue = "'" + filterValue + "'";
                }

                if (filterStr === "") {
                    filterStr =
                        filters[i].fieldName +
                        " " +
                        filters[i].condition +
                        " " +
                        filterValue;
                } else {
                    filterStr =
                        filterStr +
                        " AND " +
                        filters[i].fieldName +
                        " " +
                        filters[i].condition +
                        " " +
                        filterValue;
                }
            }
        }
        // set param to method

        component.set("v.loading", true);
        action.setParams({
            searchKeyWord: getInputkeyWord,
            objectName: component.get("v.objectName") || "",
            fieldsToSearch: component.get("v.fieldsToSearch") || "",
            lookupFieldName: component.get("v.lookupFieldName") || "",
            displayField: component.get("v.displayField") || "",
            displayFieldValue: component.get("v.displayFieldValue") || "",
            // 'filterStr' : filterStr,
            serializedFilters: serializedFilters,
            //'filters' : filters,
            splitSearchTextBySeperator: component.get("v.splitSearchTextBySeperator") || false,
            maxRows: component.get("v.maxQuickSearchRows"),
            specialSearchOptions: component.get("v.specialSearchOptions"),
            orderByClause: component.get("v.orderByClause")
        });
        // set a callBack
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.loading", false);
                var storeResponse = JSON.parse(response.getReturnValue());
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.
                if (storeResponse.length == 0) {
                    component.set("v.Message", "No Result Found...");
                } else {
                    component.set("v.Message", "");
                }
                //remove dulplicated entries with the same value
                var storeResponse = storeResponse.filter((c, index) => {
                    for (var i = 0; i < storeResponse.length; i++) {
                        if (storeResponse[i].value == c.value) {
                            if (i == index) {
                                return true;
                            } else {
                                return false;
                            }
                        }
                    }
                });

                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);

                helper.openMenu(component);
                helper.hidePill(component);
            } else {
                var message = this.stringifyErrors(response);
                alert("An unexpected error occured. Error: " + message);
                component.set("v.loading", false);
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    },

    showInput: function(component) {
        // console.log("LookupComponentHelper showInput...");
        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, "slds-show");
        $A.util.removeClass(lookUpTarget, "slds-hide");
    },

    showPill: function(component) {
        // console.log("LookupComponentHelper showPill...");
        var pillTarget = component.find("lookup-pill");
        $A.util.addClass(pillTarget, "slds-show");
        $A.util.removeClass(pillTarget, "slds-hide");
    },

    showSearchIcon: function(component) {
        // console.log("LookupComponentHelper showSearchIcon...");
        var searchIcon = component.find("searchIcon");
        $A.util.addClass(searchIcon, "slds-show");
        $A.util.removeClass(searchIcon, "slds-hide");
    },

    stringifyErrors: function(response) {
        // console.log("LookupComponentHelper stringifyErrors...");
        let errors = response.getError();
        let message = "Unknown error"; // Default error message
        // Retrieve the error message sent by the server
        if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
        }
        // Display the message
        console.error(message);
        return message;
    }
});
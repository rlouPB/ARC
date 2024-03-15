/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
    doInit: function(component, event, helper) {
        // console.log("LookupComponentController doInit...");
        let objName = component.get("v.objectName");
        let dispField = component.get("v.displayField");
        let dispFieldVal = component.get("v.displayFieldValue");
        let existingId = component.get("v.lookupFieldName");
        let selectedRecord = component.get("v.selectedRecord");
        if (selectedRecord && selectedRecord.value) {
            helper.fillPillOnly(component, selectedRecord, helper);
        } else if (existingId && existingId.length == 18) {
            helper.getExistingRecord(
                component,
                event,
                objName,
                dispField,
                dispFieldVal,
                existingId
            );
        } //if(!existingId)
        else {
            component.set("v.SearchKeyWord", existingId);
        }
    },

    // function for clear the Record Selection
    clear: function(component, event, helper) {
        // console.log("LookupComponentController clear...");
        helper.clearSearch(component, helper);
    },

    //closeModal event handler for close the modal.
    handleCloseModal: function(component, event, helper) {
        // console.log("LookupComponentController handleCloseModal...");
        var data = event.getParam("data");
        // console.log('data ' + data);
        component.find("optionComponent").set("v.body", []);

        if (data) {
            component.set("v.selectedRecord", data);
            component.set("v.lookupFieldName", data.value);
            // console.log('lookupFieldName###', data.value);

            // var forclose = component.find("lookup-pill");
            // $A.util.addClass(forclose, 'slds-show');
            // $A.util.removeClass(forclose, 'slds-hide');
            helper.showPill(component);

            // var forclose = component.find("searchRes");
            // $A.util.addClass(forclose, 'slds-is-close');
            // $A.util.removeClass(forclose, 'slds-is-open');
            helper.closeMenu(component);

            // var lookUpTarget = component.find("lookupField");
            // $A.util.addClass(lookUpTarget, 'slds-hide');
            // $A.util.removeClass(lookUpTarget, 'slds-show');
            helper.hideInput(component);

            // var searchIcon = component.find("searchIcon");
            // $A.util.addClass(searchIcon, 'slds-hide');
            // $A.util.removeClass(searchIcon, 'slds-show');
            helper.hideSearchIcon(component);
        }
        event.stopPropagation();
    },

    handleRunSearch: function(component, event, helper) {
        // console.log("LookupComponentController handleRunSearch...");
        var searchKeyWord = component.get("v.SearchKeyWord");
        var minimumSearchTextLength = component.get("v.minimumSearchTextLength");

        var doSearch =
            minimumSearchTextLength == 0 ||
            (searchKeyWord && searchKeyWord.length >= minimumSearchTextLength);

        if (doSearch) {
            helper.searchHelper(component, event, searchKeyWord, helper);
            // helper.openMenu(component);
        }
    },

    // This function call when the end User Select any record from the result list.
    handleSelectedItemEvent: function(component, event, helper) {
        // console.log("LookupComponentController handleSelectedItemEvent...");
        var selectedObjGetFromEvent = event.getParam("selectedObj");
        // console.log('selected option', JSON.stringify(selectedObjGetFromEvent));

        if (selectedObjGetFromEvent && selectedObjGetFromEvent.isRecord == true) {
            helper.fillPill(component, selectedObjGetFromEvent, helper);
            if (component.get("v.externalFieldPill")) {
                helper.clearSearch(component, helper);
            }

            /* var instanceName = component.get("v.instanceName");
			 var compEvent = component.getEvent("selectedItemEvent");
			 compEvent.setParams({
				"sourceInstanceName": instanceName,
				"selectedObj" : selectedObjGetFromEvent
			});

			compEvent.fire();*/
        } else {
            if (selectedObjGetFromEvent.componentName) {
                var cmpName = selectedObjGetFromEvent.componentName || "";
                var attr = selectedObjGetFromEvent.attr || {};
                if (cmpName != "") {
                    // if (cmpName == 'c:NewBasicContact' || cmpName == 'c:newRelatedContactRecord' ||)
                    // {
                    attr.searchText = component.get("v.SearchKeyWord");
                    // }
                    helper.createAdditionalOptionComponent(component, cmpName, attr);
                }
            } else if (selectedObjGetFromEvent.eventName) {
                var eventName = selectedObjGetFromEvent.eventName;
                var attr = selectedObjGetFromEvent.attr || {};
                helper.fireAdditionalOptionEvent(component, eventName, attr);
            }
        }
        // console.log('Obj selected');
        var allowPropagation = component.get("v.allowPropagation");
        if (!allowPropagation) {
            event.stopPropagation();
        }
    },

    keyPressController: function(component, event, helper) {
        // console.log("LookupComponentController keyPressController...");
        // get the search Input keyword
        // check if getInputKeyWord size id at least minimum then open the lookup result List and
        // call the helper
        // else close the lookup result List part.
        //event.getParam
        let eventType = event.getName();
        // var getInputkeyWord = component.get("v.SearchKeyWord");
        let minimumSearchTextLength = component.get("v.minimumSearchTextLength");
        var getInputkeyWord = event.getSource().get("v.value");
        component.set("v.lookupFieldName", getInputkeyWord);
        let doSearch, clearRecords, openMenu;
        if (eventType == "keyup" || minimumSearchTextLength == 0) {
            //search if keyup and enough characters to search or auto-search (minimum 0)
            doSearch =
                minimumSearchTextLength == 0 ||
                (getInputkeyWord && getInputkeyWord.length >= minimumSearchTextLength);
            clearRecords = !doSearch;
            openMenu = true;
        } else if (eventType == "focus") {
            openMenu = true;
        }
        // console.log(event.getName() + ' -' + getInputkeyWord + '-');
        if (doSearch) {
            helper.searchHelper(component, event, getInputkeyWord, helper);
        } else {
            // component.set("v.listOfSearchRecords", null );
            component.set("v.loading", false);
        }
        if (clearRecords) {
            component.set("v.listOfSearchRecords", null);
        }
        var fillPillOnSelect = component.get("v.fillPillOnSelect");

        if (openMenu) {
            if (!fillPillOnSelect) {
                helper.noPillStartSearch(component, helper);
            }
            helper.openMenu(component);
        } else {
            // component.set("v.listOfSearchRecords", null );
            helper.closeMenu(component);
        }
    },

    //It will close lookup list on blur
    onBlurHandler: function(component, event, helper) {
        // console.log("LookupComponentController onBlurHandler...");
        var allowFreeText = component.get("v.allowFreeText");
        var getInputkeyWord = component.get("v.SearchKeyWord");
        var lookupFieldName = component.get("v.lookupFieldName");

        setTimeout(
            $A.getCallback(function() {
                // if we allow free text, update the attributes
                if (allowFreeText == true && getInputkeyWord && !lookupFieldName) {
                    component.set("v.lookupFieldName", getInputkeyWord);
                }

                // always close after blur
                helper.closeMenu(component);
            }),
            400
        );
    },

    postRender: function(component, event, helper) {
        // console.log("LookupComponentController postRender...");
        let selectedRecord = component.get("v.selectedRecord");
        var fillPillOnSelect = component.get("v.fillPillOnSelect");

        if (fillPillOnSelect && selectedRecord && selectedRecord.value) {
            helper.fillPillOnly(component, selectedRecord, helper);
        }
        // if (!fillPillOnSelect)
        // {
        //		 component.find('searchTextInput').focus();
        // }
    },

    //Aura method handler for set free text from Parant component.
    setLookupFieldNameHandler: function(component, event, helper) {
        // console.log("LookupComponentController setLookupFieldNameHandler...");
        var params = event.getParam("arguments");
        if (params) {
            var lookupFieldName = params.lookupFieldName;
            // console.log('lookupFieldName ', lookupFieldName);
            component.set("v.SearchKeyWord", lookupFieldName);
        }
    },

    //Aura method handler for set pill from parent component.
    setSelectedRecordHandler: function(component, event, helper) {
        // console.log("LookupComponentController setSelectedRecordHandler...");
        var params = event.getParam("arguments");
        if (params && params.SelectedRecord) {
            var SelectedRecord = params.SelectedRecord;
            helper.fillPill(component, SelectedRecord, helper);
        }
    }
});
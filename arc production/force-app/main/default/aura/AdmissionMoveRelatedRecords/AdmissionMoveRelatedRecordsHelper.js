({
    applyCSS : function(component, event) {
        var modal = component.find('modal');
        var modalBackdrop = component.find('modalBackdrop');
        //$A.util.addClass(modal, 'slds-fade-in-open');
        //$A.util.addClass(modalBackdrop, 'slds-backdrop--open');
    },
    
    removeComponent : function(component, event) {
        //get event and set the parameter of Aura:component type, as defined in the event above.
        var removeComponentEvent = component.getEvent("removeComponent");
        removeComponentEvent.setParams({
            "component" : component
        });
        removeComponentEvent.fire();
    },

    loadAvailableAdmissions : function(component) {
        /*
        var selectedSourceObject = component.get("v.selectedSourceObject");
        var selectedTargetObject = component.get("v.selectedTargetObject");
        var selectedSourceObjectId = '';
        var selectedTargetObjectId = '';

        if(selectedSourceObject.value) {
            selectedSourceObjectId = selectedSourceObject.value;
        }

        if(selectedTargetObject.value) {
            selectedTargetObjectId = selectedTargetObject.value;
        }
        */
        var accountId = component.get("v.recordId");
        var action = component.get("c.getAdmissions");
        action.setParams({
            "accountId": accountId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var admissionList = response.getReturnValue();
                console.log('admissionList ' + JSON.stringify(admissionList));
                component.set("v.admissionList", admissionList);
            } else if (state === 'ERROR'){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log('Something went wrong, Please check with your admin');
            }
        });
        $A.enqueueAction(action);
    },

    updateRequestItemFilters : function(component, selectedSourceObject) {
        if(selectedSourceObject) {
            var requestItemFilters = component.get("v.requestItemFilters");
            requestItemFilters.push({
                'fieldName': 'Admissions_Requirement__r.Admission__c',
                'operator': '=',
                'value': selectedSourceObject.value
            });
            component.set("v.requestItemFilters", requestItemFilters);
        } else {
            component.set("v.requestItemFilters", []);
        }
    },

    loadRelatedObjectDatatables : function(component) {
        var selectedSourceObject = component.get("v.selectedSourceObject");
        var admissionId = selectedSourceObject.value;
        console.log('admissionId ' + admissionId);
        if(admissionId) {
            var action = component.get("c.getMoveRecordsData");
            action.setParams({
                "admissionId": admissionId
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === 'SUCCESS'){
                    var moveRecordsData = JSON.parse(response.getReturnValue());
                    console.log('moveRecordsData ' + JSON.stringify(moveRecordsData));
                    // let id2SelectedMap = {};//component.get('v.id2SelectedMap');
                    Object.keys(moveRecordsData).forEach(function(key) {
                        
                        if(moveRecordsData[key].length > 0) {
                            for(var i = 0; i < moveRecordsData[key].length; i++) {
                                var id = moveRecordsData[key][i].Id;
                                console.log('id ' + id);
                                // id2SelectedMap[id] = false;
                                moveRecordsData[key][i].Is_Selected = false;
                                // function add(id) {
                                //     var found = relatedRecords[key].find(function (obj) {
                                //         if(obj.Id == id) {
                                //             console.log('obj ' + JSON.stringify(obj));
                                //             return obj;
                                //         }
                                //     });
                                //     if(found) {
                                //         moveRecordsData[key].push(found);
                                //     }
                                // }
                                // add(id);
                            }
                        }
                    });
                    // component.set('v.id2SelectedMap', id2SelectedMap);
                    
                    component.set("v.relatedRecords", moveRecordsData);
                    component.set('v.showRelatedLists', true);
                } else if (state === 'ERROR'){
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                } else {
                    console.log('Something went wrong, Please check with your admin');
                }
            });
            $A.enqueueAction(action);
        }
    },

    updateSelectedRows : function(component, eventId, checked, name) {
        //selectedRowIds
        //add to or remove from list of relevant selectedRowIds
        var selectedRowsObject = component.get("v.selectedRowsObject");
        var array = selectedRowsObject[name];
        var index = array.indexOf(eventId);
        if(checked) {
            if(index < 0) {
                array.push(eventId);
            }
        } else {
            if(index > -1) {
                array.splice(index, 1);
            }
        }
        selectedRowsObject[name] = array;
        console.log('selectedRowsObject updated ' + JSON.stringify(selectedRowsObject));
        component.set("v.selectedRowsObject", selectedRowsObject);
    },

    selectAllRows : function(component, checked, name) {
        //selectedRowIds
        //add to or remove from list of relevant selectedRowIds
        var selectedRowsObject = component.get("v.selectedRowsObject");
        let selectedArray = [];
        var relatedRecords = component.get("v.relatedRecords");
        var array = relatedRecords[name];
        array.forEach(function(row) {
            row.Is_Selected = checked;
            if (checked) selectedArray.push(row.Id);
        });

        selectedRowsObject[name] = selectedArray;
        console.log('selectedRowsObject updated ' + JSON.stringify(selectedRowsObject));
        
        component.set("v.selectedRowsObject", selectedRowsObject);
        component.set("v.relatedRecords", relatedRecords);
    },

    moveSelectedRecords : function(component, helper) {
        var moveRecordsData = {"requestItems": [], "admissionMedications": [], "forms": [], "baseNotes":[]};
        var relatedRecords = component.get("v.relatedRecords");
        var selectedRowsObject = component.get("v.selectedRowsObject");
        Object.keys(selectedRowsObject).forEach(function(key) {
            console.log('object ' + key, selectedRowsObject[key]);
            console.log('length ' + selectedRowsObject[key].length);

            if(selectedRowsObject[key].length > 0) {
                for(var i = 0; i < selectedRowsObject[key].length; i++) {
                    var id = selectedRowsObject[key][i];
                    console.log('id ' + id);
                    
                    function add(id) {
                        var found = relatedRecords[key].find(function (obj) {
                            if(obj.Id == id) {
                                console.log('obj ' + JSON.stringify(obj));
                                return obj;
                            }
                        });
                        if(found) {
                            delete found.Is_Selected;
                            moveRecordsData[key].push(found);
                        }
                    }
                    add(id);
                }
            }
        });

        console.log('moveRecordsData ' + JSON.stringify(moveRecordsData));

        var selectedTargetObject = component.get("v.selectedTargetObject");
        var targetAdmissionId = null;
        if(selectedTargetObject) {
            targetAdmissionId = selectedTargetObject.value;
        }
        
        console.log('targetAdmissionId ' + targetAdmissionId);
        if(targetAdmissionId) {
            var action = component.get("c.saveRecords");
            action.setParams({
                "targetAdmissionId": targetAdmissionId,
                "serializedData": JSON.stringify(moveRecordsData)
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === 'SUCCESS'){
                    var saveRecordsResponse = response.getReturnValue();
                    console.log('saveRecordsResponse ' + saveRecordsResponse);

                    if(saveRecordsResponse) {
                        /*
                        this.showToast({
                            type: "error",
                            title: "Move Selected Records",
                            message: "The following error occured : " + saveRecordsResponse
                        });
                        */
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Move Selected Records",
                            "message": "The following error occurred : " + saveRecordsResponse
                        });
                        toastEvent.fire();
                    } else {
                        /*
                        this.showToast({
                            "type": "success",
                            "title": "",
                            "message": "Successfully moved Selected Records."
                        });
                        */
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "success",
                            "title": "Move Selected Records",
                            "message": "Successfully moved Selected Records."
                        });
                        toastEvent.fire();
                        $A.get('e.force:refreshView').fire();
                        helper.removeComponent(component);
                        // component.find("sourceObjectLookup").closePill();
                        // component.find("targetObjectLookup").closePill();
                    }
                } else if (state === 'ERROR'){
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                            /*
                            this.showToast({
                                type: "error",
                                title: "Move Selected Records",
                                message: "The following error occured : " + errors[0].message
                            });
                            */
                            var toastEvent = $A.get("e.force:showToast");
                            console.log('toastEvent ' + toastEvent);
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Move Selected Records",
                                "message": "The following error occurred : " + errors[0].message
                            });
                            toastEvent.fire();
                        }
                    } else {
                        console.log("Unknown error");
                    }
                } else {
                    console.log('Something went wrong, Please check with your admin');
                }
                helper.hideSpinner(component);
            });
            $A.enqueueAction(action);
        }
    },

    buildLookupFilters : function(component, event, helper)
    {
        //build source and target filters
        var grandParentId = component.get("v.recordId");
        var grandparentLookupFieldName = 'Patient_Account__c';

        let selectedTargetObject = component.get('v.selectedTargetObject');
        let selectedSourceObject = component.get('v.selectedSourceObject');
        
        var lookupFilters = {'source': [], 'target': []};
        
        lookupFilters.source.push({
            'fieldName': grandparentLookupFieldName,
            'condition': '=',
            'value': grandParentId
        });
        if (selectedTargetObject && selectedTargetObject.value)
        {
            lookupFilters.source.push({
                'fieldName': 'Id',
                'condition': '!=',
                'value': selectedTargetObject['value']
            });
        }

        lookupFilters.target.push({
            'fieldName': grandparentLookupFieldName,
            'condition': '=',
            'value': grandParentId
        });
        if (selectedSourceObject && selectedSourceObject.value)
        {
            lookupFilters.target.push({
                'fieldName': 'Id',
                'condition': '!=',
                'value': selectedSourceObject['value']
            });
        }
        component.set('v.lookupFilters', lookupFilters);
    }
})
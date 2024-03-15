/* eslint-disable no-unused-expressions */
({
    onRefreshView: function(cmp, e, h) {
        let patientDiagnoses = cmp.find("patientDiagnoses");
        if (patientDiagnoses && patientDiagnoses.initialize) {
            $A.getCallback(function() {
                console.info("INITIALIZING...");
                patientDiagnoses.initialize();
            })();
        }
    },
    init: function(component, event, helper) {
        helper.retrieveSimplifiedViewConfiguration(component).then(
            $A.getCallback(function(result) {
                var tabs = [{
                        title: "Patient",
                        id: "patient",
                        isSelected: true,
                        sequence: 10,
                        show: true
                    },
                    {
                        title: "Shift Items",
                        id: "shiftItems",
                        isSelected: false,
                        sequence: 15,
                        show: false
                    },
                    {
                        title: "Treatment Plan",
                        id: "treatmentPlan",
                        isSelected: false,
                        sequence: 20,
                        show: true
                    },
                    {
                        title: "Medications",
                        id: "medications",
                        isSelected: false,
                        sequence: 30,
                        show: true
                    },
                    {
                        title: "Create New",
                        id: "createnew",
                        isSelected: false,
                        sequence: 40,
                        show: true
                    },
                    {
                        title: "Treatment History",
                        id: "treatmentHistory",
                        isSelected: false,
                        sequence: 50,
                        show: true
                    },
                    {
                        title: "Drafts",
                        id: "drafts",
                        isSelected: false,
                        sequence: 60,
                        show: true
                    },
                    {
                        title: "Open Items",
                        id: "openItems",
                        isSelected: false,
                        sequence: 70,
                        show: true
                    },
                    {
                        title: "Pre-Admission",
                        id: "preAdmission",
                        isSelected: false,
                        sequence: 75,
                        show: true
                    },
                    // Modified by Dave Solsberry 06/02/2022 for ARC-2046 to change param "show" to false
                    {
                        title: "Correspondence",
                        id: "correspondence",
                        isSelected: false,
                        sequence: 80,
                        show: false
                    },
                    // Modified by Dave Solsberry 06/02/2022 for ARC-2046 to change param "show" to false
                    {
                        title: "Requirements",
                        id: "requirements",
                        isSelected: false,
                        sequence: 90,
                        show: false
                    }
                    // JN Removed for deployment with IOP Hotfix 211201
                    // ,
                    // {
                    //     'title': 'Requirements',
                    //     'id': 'requirements',
                    //     'isSelected': false
                    // },
                ];

                var cards = [{
                        name: "flaggedNotesLwc",
                        show: true
                    },
                    {
                        name: "ListAssignedClinicians",
                        show: true
                    },
                    {
                        name: "patientAllergiesTable",
                        show: true
                    },
                    {
                        name: "patientDiagnoses",
                        show: true
                    }
                ];
                // let showNursing = result.CurrentAppName == 'Nursing';
                // if( showNursing ){
                //     tabs.splice(1, 0, {
                //         'title': 'Shift Items',
                //         'id': 'shiftItems',
                //         'isSelected': false
                //     });
                // }
                //let viewObj = JSON.parse(result.ViewConfig);
                //let tabs = JSON.parse(viewObj.Tabs__c);
                //const filteredTabs = tabs.filter(value => !result.HideTabs.includes(value.id));
                tabs = tabs.map((item) => {
                    let item2 = result.HideTabs.find((i2) => i2 == item.id);
                    if (item2) {
                        item.show = false;
                    }
                    return item;
                });
                tabs = tabs.map((item) => {
                    let item2 = result.ShowTabs.find((i2) => i2 === item.id);
                    if (item2) {
                        item.show = true;
                    }
                    return item;
                });
                tabs = tabs.filter((value) => value.show == true);
                component.set("v.tabs", tabs);
                helper.getSummaryInfo(component);
                //Begin Modified by Roy Lou 12/02/2021 for ARC-1237
                //console.log(cards);
                cards = cards.map((item) => {
                    let item2 = result.HideComponents.find((i2) => i2 === item.name);
                    if (item2) {
                        item.show = false;
                    }
                    return item;
                });
                let displayPermissions = cards.reduce(function(map, obj) {
                    map[obj.name] = obj.show;
                    return map;
                }, {});
                component.set("v.displayPermissions", displayPermissions);
                //End Modified by Roy Lou 12/02/2021 for ARC-1237

                helper.getPostRenderConfig(component);
            })
        );

        //Get Open Items Summary

        // var patientNotefilters =
        // [
        //     {
        //         'fieldName': 'Admission__c',
        //         'operator': '=',
        //         'value': component.get('v.record.Current_Admission__c')
        //     }
        // ];
        // component.set('v.patientNotefilters', patientNotefilters);

        // component.set('v.taskFilters', patientNotefilters);
        
    },
    handleButtonClick: function(component, event, helper) {
        console.log("clicked " + event.currentTarget.dataset.id);
        helper.setDisplay(component, event.currentTarget.dataset.id);
    },
    collapseButtons: function(component, event, helper) {
        component.set("v.buttonsCollapsed", !component.get("v.buttonsCollapsed"));
    },
    handleClickLogCorrespondence: function(component, event, helper) {
        var fields = {
            Status: "Completed",
            WhatId: component.get("v.recordId")
        };
        var args = {
            actionName: "Account.Log_Correspondence",
            entityName: "Account",
            targetFields: fields
        };
        helper.callActionApi(component, args);
    },
    handleDisplayNewTab: function(component, event, helper) {
        var selectedTabId = component.get("v.selectedTabId");
        switch (
            selectedTabId
            // case 'patientNotes':
            //     var patientNoteFlow = component.find('patientNoteFlow');
            //     var inputVariables = [
            //         {
            //             name : 'accountId',
            //             type : 'String',
            //             value : component.get('v.recordId')
            //         }
            //         ];
            //         console.log('patientNoteFlow: ', patientNoteFlow);
            //         console.log('Build_Patient_Note: ', inputVariables);
            //         patientNoteFlow.startFlow("Build_Patient_Note", inputVariables);

            //     break;
        ) {}
    },
    handleFlowStatusChange: function(component, event, helper) {
        console.log("event: ", event);
        var outputVariables = event.getParam("outputVariables");
        var flowName = outputVariables[0].flowName;
        console.log(
            "flow status change " + flowName + " status " + event.getParam("status")
        );

        switch (event.getParam("status")) {
            case "FINISHED":
                // if (flowName == 'Build_Patient_Note')
                // {
                //     for(var i = 0; i < outputVariables.length; i++)
                //     {
                //         let outputVar = outputVariables[i];
                //         //if(outputVar.name === "newPatientNoteId")
                //         //{
                //             //deal with creation of new Note: refresh related list and/or open new Note?
                //         //}
                //     }
                // }
                break;
        }
    }
});
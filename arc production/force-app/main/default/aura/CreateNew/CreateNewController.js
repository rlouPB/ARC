/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
    onCategorySelected: function(cmp, e, h) 
    {
        // console.log("CreateNewController onCategorySelected...");
        var preventDuplicateDocTypes = 
        [
            'Away Medication Order',
            'Medication Self-Administration (MSA) Order',
            'Discharge Disposition and Recommendations',
            'Initial Case Abstract',
            'Re-Presentation Case Abstract'
        ];
    
        let params = e.getParams();
        let modal = cmp.find("modal");

        // Modified by Dave Solsberry 04/18/2022 for ARC-1741 to prepopulate contactDate on the patient note
        // Begin date logic referred to in ARC-1764 comments, possibly impacted by time zone
        let defaultDate = new Date();
        defaultDate.setHours(0, 0, 0, 0);

        let lastDayPrevMonth = new Date(
            defaultDate.getFullYear(),
            defaultDate.getMonth(),
            1
        );

        if (params.docType.Name__c.includes("Monthly")) {
            defaultDate.setDate(lastDayPrevMonth.getDate() - 1);
        }

        cmp.set("v.contactDate", defaultDate);
        // End date logic referred to in ARC-1764 comments, possibly impacted by time zone

        var checkForDuplicateDrafts = preventDuplicateDocTypes.find(docTypeName => {
            return docTypeName == params.docType.Name__c;
        });
        // console.log('checkForDuplicateDrafts on ' + params.docType.Name__c + ': ' + checkForDuplicateDrafts);
        // these first 2 logic branches could be combined with the 3rd, since 'c.checkBlockedDuplicates' also checks Away and MSA
        // if ("Away Medication Order" === params.docType.Name__c) {
        //     let action = cmp.get("c.getDraftAwayOrdersForPatient");

        //     action.setParams({
        //         accountId: cmp.get("v.recordId")
        //     });

        //     action.setCallback(this, function(response) {
        //         var state = response.getState();
        //         if (state === "SUCCESS") {
        //             var draftAwayOrdersList = response.getReturnValue();

        //             if (draftAwayOrdersList.length > 0) {
        //                 var toastEvent = $A.get("e.force:showToast");
        //                 toastEvent.setParams({
        //                     title: "Error!",
        //                     message: "The patient already has a draft Away Medication Order. Please update this under Drafts.",
        //                     duration: 2000,
        //                     type: "error"
        //                 });
        //                 toastEvent.fire();
        //             } else {
        //                 modal
        //                     .confirm(
        //                         "Are you sure you want to create a new <strong>" +
        //                         params.docType.Name__c +
        //                         "</strong> for <strong>" +
        //                         params.recordName +
        //                         "</strong>?"
        //                     )
        //                     .then(
        //                         $A.getCallback(function(confirmed) {
        //                             if (confirmed) {
        //                                 cmp.set("v.showmodal", true);
        //                                 let flow = cmp.find("flow");
        //                                 let flowName = params.docType.Flow_Name__c;
        //                                 let inputParams = [{
        //                                         name: "accountId",
        //                                         type: "String",
        //                                         value: cmp.get("v.recordId")
        //                                     },
        //                                     {
        //                                         name: "docTypeName",
        //                                         type: "String",
        //                                         value: params.docType.DeveloperName
        //                                     },
        //                                     {
        //                                         name: "docTypeId",
        //                                         type: "String",
        //                                         value: params.docType.Id
        //                                     },
        //                                     {
        //                                         name: "contactDate",
        //                                         type: "Date",
        //                                         value: defaultDate
        //                                     }
        //                                 ];
        //                                 if (flowName) {
        //                                     flow.startFlow(flowName, inputParams);
        //                                 } else {
        //                                     cmp.set("v.showmodal", false);
        //                                     modal.alert("No FLow Name Found");
        //                                 }
        //                             }
        //                         })
        //                     );
        //             }
        //         } else if (state === "ERROR") {
        //             var errors = response.getError();
        //             if (errors) {
        //                 if (errors[0] && errors[0].message) {
        //                     console.log("Error message: " + errors[0].message);
        //                 }
        //             } else {
        //                 console.log("Unknown error");
        //             }
        //         } else {
        //             console.log("Something went wrong, Please check with your admin");
        //         }
        //     });
        //     $A.enqueueAction(action);
        // } else if ("Medication Self-Administration (MSA) Order" === params.docType.Name__c) {
        //     let action = cmp.get("c.getDraftMSAOrdersForPatient");

        //     action.setParams({
        //         accountId: cmp.get("v.recordId")
        //     });

        //     action.setCallback(this, function(response) {
        //         var state = response.getState();
        //         if (state === "SUCCESS") {
        //             var draftMSAOrdersList = response.getReturnValue();

        //             if (draftMSAOrdersList.length > 0) {
        //                 var toastEvent = $A.get("e.force:showToast");
        //                 toastEvent.setParams({
        //                     title: "Error!",
        //                     message: "The patient already has a draft Medication Self Administration (MSA) Order. Please update this under Drafts.",
        //                     duration: 2000,
        //                     type: "error"
        //                 });
        //                 toastEvent.fire();
        //             } else {
        //                 modal
        //                     .confirm(
        //                         "Are you sure you want to create a new <strong>" +
        //                         params.docType.Name__c +
        //                         "</strong> for <strong>" +
        //                         params.recordName +
        //                         "</strong>?"
        //                     )
        //                     .then(
        //                         $A.getCallback(function(confirmed) {
        //                             if (confirmed) {
        //                                 cmp.set("v.showmodal", true);
        //                                 let flow = cmp.find("flow");
        //                                 let flowName = params.docType.Flow_Name__c;
        //                                 let inputParams = [{
        //                                         name: "accountId",
        //                                         type: "String",
        //                                         value: cmp.get("v.recordId")
        //                                     },
        //                                     {
        //                                         name: "docTypeName",
        //                                         type: "String",
        //                                         value: params.docType.DeveloperName
        //                                     },
        //                                     {
        //                                         name: "docTypeId",
        //                                         type: "String",
        //                                         value: params.docType.Id
        //                                     },
        //                                     {
        //                                         name: "contactDate",
        //                                         type: "Date",
        //                                         value: defaultDate
        //                                     }
        //                                 ];
        //                                 if (flowName) {
        //                                     flow.startFlow(flowName, inputParams);
        //                                 } else {
        //                                     cmp.set("v.showmodal", false);
        //                                     modal.alert("No FLow Name Found");
        //                                 }
        //                             }
        //                         })
        //                     );
        //             }
        //         } else if (state === "ERROR") {
        //             var errors = response.getError();
        //             if (errors) {
        //                 if (errors[0] && errors[0].message) {
        //                     console.log("Error message: " + errors[0].message);
        //                 }
        //             } else {
        //                 console.log("Unknown error");
        //             }
        //         } else {
        //             console.log("Something went wrong, Please check with your admin");
        //         }
        //     });
        //     $A.enqueueAction(action);
        // } else 
        if (checkForDuplicateDrafts) 
        {
            let action = cmp.get("c.checkBlockedDuplicates");

            action.setParams({
                accountId: cmp.get("v.recordId"),
                docTypeName: params.docType.Name__c,
                sObjectType: params.docType.SObject_Name__c
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                var errorMessage;
                if (state === "SUCCESS") {
                    var dupResult = response.getReturnValue();

                    if (dupResult.allowCreate == 'false')
                    {
                        errorMessage = dupResult.errorMessage;
                        // var toastEvent = $A.get("e.force:showToast");
                        // toastEvent.setParams({
                        //     title: "Error!",
                        //     message: dupResult.errorMessage,
                        //     duration: 2000,
                        //     type: "error"
                        // });
                        // toastEvent.fire();
                    } else {
                        h.confirmCreate(cmp, e, h, params, modal);
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            errorMessage = errors[0].message;
                        }
                    } else {
                        console.log("Unknown error");
                        errorMessage = 'Unknown error';
                    }
                } else {
                    console.log("Something went wrong, Please check with your admin");
                }
                if (errorMessage)
                {
                    var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error!",
                            message: errorMessage,
                            duration: 2000,
                            type: "error"
                        });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        } else {
            h.confirmCreate(cmp, e, h, params, modal);
            // modal
            //     .confirm(
            //         "Are you sure you want to create a new <strong>" +
            //         params.docType.Name__c +
            //         "</strong> for <strong>" +
            //         params.recordName +
            //         "</strong>?"
            //     )
            //     .then(
            //         $A.getCallback(function(confirmed) {
            //             if (confirmed) {
            //                 cmp.set("v.showmodal", true);
            //                 let flow = cmp.find("flow");
            //                 let flowName = params.docType.Flow_Name__c;
            //                 if (flowName) {
            //                     let inputParams = [{
            //                             name: "accountId",
            //                             type: "String",
            //                             value: cmp.get("v.recordId")
            //                         },
            //                         {
            //                             name: "docTypeName",
            //                             type: "String",
            //                             value: params.docType.DeveloperName
            //                         },
            //                         {
            //                             name: "docTypeId",
            //                             type: "String",
            //                             value: params.docType.Id
            //                         }
            //                         // {
            //                         // 	name: "contactDate",
            //                         // 	type: "Date",
            //                         // 	value: cmp.get("v.contactDate"),
            //                         // },
            //                     ];

            //                     if (flowName == "Build_Patient_Note_With_Params") {
            //                         // set default date

            //                         inputParams = [{
            //                                 name: "accountId",
            //                                 type: "String",
            //                                 value: cmp.get("v.recordId")
            //                             },
            //                             {
            //                                 name: "docTypeName",
            //                                 type: "String",
            //                                 value: params.docType.DeveloperName
            //                             },
            //                             {
            //                                 name: "docTypeId",
            //                                 type: "String",
            //                                 value: params.docType.Id
            //                             },
            //                             {
            //                                 name: "contactDate",
            //                                 type: "Date",
            //                                 value: cmp.get("v.contactDate")
            //                             }
            //                         ];
            //                     }
            //                     flow.startFlow(flowName, inputParams);
            //                 } else {
            //                     cmp.set("v.showmodal", false);
            //                     modal.alert("No FLow Name Found");
            //                 }
            //             }
            //         })
            //     );
        }
    },
    onCloseModalHandler: function(cmp, e, h) {
        console.log("CreateNewController onCloseModalHandler...");
        cmp.set("v.showmodal", false);
    },

    onStatusChangeHandler: function(cmp, e, h) {
        console.log("CreateNewController onStatusChangeHandler...");
        let params = e.getParams();
        if (params.status && params.status.toUpperCase().includes("FINISHED")) {
            let outputVariables = params.outputVariables;
        }
    }
});
({
    refreshRequirementsTable: function (component, event, helper) {
        
        // if (component.get('v.buttonState') == 'showAllRequests')
        // {
        //     let rowId = component.get("v.selectedRow");
        //     let parAdReqFilter = component.find("showReqBtn").get("v.class");
        //     let parShowAllFilter = component.find("showAllReqBtn").get("v.class");
        //     let childState = event.getSource().get("v.title");
        //     let accountId = component.get("v.recordId");
            
        //     let filter = 'showAllRequests';
            
        //     helper.callApexMethod(
        //         component,
        //         "requestItems",
        //         {
        //             'currentId': '',
        //             'parentFilter':filter,
        //             'childFilter':childState,
        //             'accountId':accountId,
        //             'parentId':rowId,
        //         },
        //         function (result) {
        //             component.set("v.requestItems",result);
        //             helper.toggleSpinner(component, 0);
        //         },
        //         function(errorcallback){
        //             helper.toggleSpinner(component, 0);
        //         }
        //     );
        // } else
        // {
            let accountId = component.get("v.recordId");
            helper.callApexMethod(
                component,
                "getAdmissionsRequirement",
                {
                    'parentId' : accountId,
                    'applicablePhase' : component.get('v.applicablePhase')
                },
                function (result) {
                    if (result) {
                        component.set("v.admissionsRequirement",result.admissionRequirements);
                        let admissionsRequirementMap = component.get('v.admissionsRequirementMap');
                        
                        if (result.admissionRequirements.length > 0) component.set('v.currentAdmissionId',result.admissionRequirements[0].Admission__c);
                        let foundSelectedRow = false;
                        let isShowAllRequests = false;
                        let requestItems;
                        if (component.get('v.buttonState') == 'showAllRequests')
                        {
                            isShowAllRequests = true;
                            requestItems = [];

                        } else if (component.get('v.selectedRow'))
                        {
                            foundSelectedRow = true;
                            requestItems = result.admissionAndReqMap[component.get('v.selectedRow')];
                        }
                        
                        for(var i=0;i<result.admissionRequirements.length;i++) {
                            admissionsRequirementMap[result.admissionRequirements[i].Id] = result.admissionRequirements[i];
                            if (isShowAllRequests)
                            {
                                requestItems.push.apply(requestItems, result.admissionAndReqMap[result.admissionRequirements[i].Id]);
                            }else if(!foundSelectedRow 
                                    && result.admissionAndReqMap 
                                    && result.admissionAndReqMap[result.admissionRequirements[i].Id]) 
                            {
                                requestItems = result.admissionAndReqMap[result.admissionRequirements[i].Id];
                                //component.set("v.requestItems",result.admissionAndReqMap[result.admissionRequirements[i].Id]);
                                component.set('v.selectedRow',result.admissionRequirements[i].Id);
                                component.set('v.selectedRequirement',result.admissionRequirements[i]);
                                component.set('v.title','Request Items for '+result.admissionRequirements[i].Name+' Requirement');
                                foundSelectedRow = true;
                            } 
                        }
                        if (!isShowAllRequests && !foundSelectedRow && result.admissionRequirements.length > 0)
                        {
                            component.set('v.selectedRow',result.admissionRequirements[0].Id);
                            component.set('v.selectedRequirement',result.admissionRequirements[0]);
                            component.set('v.title','Request Items for '+result.admissionRequirements[0].Name+' Requirement');
                                
                        }
                    
                        // if (component.get("v.bottomBtnState") == 'showAll')
                        // {
                        //     component.set("v.requestItems",requestItems);
                        // } else if (component.get('v.bottomBtnState') == 'showOpen')
                        // {
                        //     helper.getRequestItems(component, event, helper);
                        // }
                        helper.getRequestItems(component, event, helper);

                        component.set('v.admissionsRequirementMap', admissionsRequirementMap );
                        //Ids to make ContentDocumentLinks for
                        let fileRelatedIds = [];
                        if (component.get('v.recordId')) fileRelatedIds.push(component.get('v.recordId'));
                        if (component.get('v.currentAdmissionId')) fileRelatedIds.push(component.get('v.currentAdmissionId'));

                        component.set('v.fileRelatedIds', fileRelatedIds);
                    }
                    helper.hideSpinner(component);
                },
                function(errorcallback){
                    // helper.toggleSpinner(component, 0);
                    helper.hideSpinner(component);
                }
            );
        // }
    },
    getRequestItems : function(component, event, helper) {
        
        let flag = false;        
        let parAdReqFilter = component.find("showReqBtn").get("v.class"); //trueish if Show By Requirement selected
        let parShowAllFilter = component.find("showAllReqBtn").get("v.class"); //trueish if Show All Request Items selected
        let childShowAll = component.find("showAllBtn").get("v.class"); //trueish if Show All selected on bottom
        let childShowOpen = component.find("showOpenBtn").get("v.class"); //trueish if Show Open seleted on bottom
        let accountId = component.get("v.recordId");
        
        let filter;
        let childFil;
        if(parAdReqFilter) {
            filter = component.find("showReqBtn").get("v.title");//showRequirements
            flag = true;
        } else if(parShowAllFilter) {
            filter = component.find("showAllReqBtn").get("v.title");//showAllRequests
        }
        if(childShowAll) {
            childFil = component.find("showAllBtn").get("v.title"); //showAll    
        } else if(childShowOpen) {
            childFil = component.find("showOpenBtn").get("v.title"); //showOpen
        }  
        
        //flag = true if Show By Requirement selected
        let rowId = '';
        let selectedRequirement;
        if(flag) {
        
            let target = event.currentTarget;
            if(target && target.getAttribute && typeof target.getAttribute == 'function')
            {
                let rowIndex = target.getAttribute("data-row-index");
                rowId = component.get('v.admissionsRequirement')[rowIndex].Id;
                let selectedRow = component.get('v.admissionsRequirement')[rowIndex].Id;
                component.set('v.selectedRow',selectedRow);
                let admissionsRequirementMap = component.get('v.admissionsRequirementMap');
                selectedRequirement = admissionsRequirementMap[selectedRow];
                component.set('v.selectedRequirement',selectedRequirement);
            } else {

                rowId = component.get('v.selectedRow');
                selectedRequirement = component.get('v.selectedRequirement');
            }
            if (selectedRequirement)
            {
                component.set('v.title','Request Items for '+ selectedRequirement.Name +' Requirement'); 
            }
            //component.find("spinner").set("v.class", "slds-show");
            helper.showSpinner(component);
        }    
        helper.callApexMethod(
            component,
            "requestItems",
            {
                'currentId': '',
                'parentFilter':filter,
                'childFilter':childFil,
                'accountId':accountId,
                'parentId':rowId,
                'currentPhase': component.get('v.applicablePhase')
            },
            function (result) {
                component.set("v.requestItems",result);
                //helper.toggleSpinner(component, 0);
                helper.hideSpinner(component);
            },
            function(errorcallback){
                component.set("v.requestItems",[]);
                // helper.toggleSpinner(component, 0);
                helper.hideSpinner(component);
            }
        );
        // }
    },
    toggleSpinner : function(component, duration) {
        window.setTimeout($A.getCallback(function() {
            if (component.find("spinner")) {
                var spinnerCls = component.find("spinner").get("v.class");
                // console.log('spinnerCls',spinnerCls);
                if (spinnerCls) {
                    if (spinnerCls === 'slds-show') {
                        component.find("spinner").set("v.class", "slds-hide");    
                    } else {
                        component.find("spinner").set("v.class", "slds-show");    
                    }
                } else{
                    component.find("spinner").set("v.class", "slds-hide");    
                }
            }
        }), duration);	   
    },
    toggleModalSpinner : function(component, duration) {
        window.setTimeout($A.getCallback(function() {
            if (component.find("modalSpinner")) {
                var spinnerCls = component.find("modalSpinner").get("v.class");
                if (spinnerCls) {
                    if (spinnerCls === 'slds-show') {
                        component.find("modalSpinner").set("v.class", "slds-hide");    
                    } else if (spinnerCls === 'slds-hide') {
                        component.find("modalSpinner").set("v.class", "slds-show");    
                    }
                } else{
                    component.find("modalSpinner").set("v.class", "slds-hide");    
                }
            }
        }), duration);	   
    },
    handleCDLData : function(component, event, helper, response) {
    	
        let accountId = component.get("v.recordId");
        /*call apex to create content document links*/
        if(response && response.contentDocumentId) {
            
            helper.callApexMethod(
                component,
                "uploadCDL",
                {
                    'accountId' : accountId,
                    'contentDocumentId' : response.contentDocumentId
                },
                function (result) {
                    if (result) {
                        // console.log(result);
                        component.find('notifLib').showToast({
                            "message": 'Your file was successfully uploaded.',
                            "variant": "success",
                            "mode" : "dismissable"
                        });
                        component.set("v.showUploadModal",false);
                    }
                    helper.toggleModalSpinner(component, 0);    
                },
                function(errorcallback){
                    helper.toggleModalSpinner(component, 0);
                }
            );
        }
    }
})
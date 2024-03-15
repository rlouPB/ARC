({
    doInit : function(component, event, helper) {
        
        let accountId;
        let titleFlag = component.get("v.rowIdx");
        
        if(component.get("v.recordId")) {
        	accountId = component.get("v.recordId");
        } else {
            accountId = component.get("v.accountId");
        }
        
        var params = helper.parseURL();
        let flag = component.get("v.showRequest");
        if (component.get('v.requestItemModal'))
        {
            document.body.style.overflow = 'hidden';
        }
        //specified requestId
        if(params && params.requestId && !flag) {
            
            component.set("v.requestId",params.requestId);
            component.set("v.selectedRequestId",params.requestId);
            component.set("v.accountId",accountId);
            titleFlag = params.requestId;
            
            /****Apex call*****/
            helper.callApexMethod(
                component,
                "requestItems",
                {
                    'currentId': params.requestId,
                    'parentFilter': '',
                    'childFilter': '',
                    'accountId': '',
                    'parentId' : ''
                },
                function (result) {
                    if (result) {
                        component.set("v.newRI",result[0]);
                        component.set("v.requestItemModal",!component.get("v.requestItemModal"));
                        component.set("v.showRequest",true);
        				document.body.style.overflow = 'hidden';

                        var selectedPatientRecord = {};
                        var contactLookup = component.find("contactLookup");
                        
                        if(contactLookup) {
                            
                            if (result[0].Responsible_Contact__c)
                            {
                                var displayField = contactLookup.get("v.displayField") || '';
                                selectedPatientRecord.label = result[0].Responsible_Contact__r.Name;
                                selectedPatientRecord.value = result[0].Responsible_Contact__c;
                                selectedPatientRecord.isRecord = true;
                                // console.log('selectedPatientRecord',selectedPatientRecord);
                                contactLookup.setSelectedRecord(selectedPatientRecord);
                            }
                        }
                    }
                },
                function(errorcallback){
                    helper.toggleModalSpinner(component, 0);
                }
            );
        } 

        var requiredFieldObject = {
            'Status__c':{ label: 'Status', required: true },
            'Action__c': { label: 'Action', required: true },
            'Date_Requested__c': { label: 'Date Requested', required: true },
            'Item_Requested__c': { label: 'Item Requested', required: true }
        };
        component.set("v.requiredFields",requiredFieldObject);

        var callerSearchOptions = [];
        component.set("v.callerSearchOptions",callerSearchOptions);
        var userSearchOptions = [];
        component.set("v.userSearchOptions",userSearchOptions);
        var requirementSearchOptions = [];
        component.set("v.requirementSearchOptions",requirementSearchOptions);

        var callerSearchFilter = [
            {
                'fieldName': 'Account__c',
                'condition': '=',
                'value': accountId
            }    
        ];
        component.set("v.callerSearchFilter",callerSearchFilter);

        var userSearchFilter = [
            {
                'fieldName': 'IsActive',
                'condition': '=',
                'value': true
            },
            {
                'fieldName': 'Profile.Name',
                'condition': 'like',
                'value': 'Riggs%'
            }  
        ];
        component.set("v.userSearchFilter",userSearchFilter);

        let currentAdmissionId = component.get('v.currentAdmissionId');
        if (!currentAdmissionId && component.get('v.selectedRequirement')) 
        {
            currentAdmissionId = component.get('v.selectedRequirement').Admission__c;
        }
        var requirementSearchFilter = [
            {
                'fieldName': 'Admission__c',
                'condition': '=',
                'value': currentAdmissionId
            }    
        ];
        component.set("v.requirementSearchFilter",requirementSearchFilter);
        
        //record Ids to make ContentDocumentLinks for after upload
        let fileRelatedIds = component.get('v.fileRelatedIds');
        if (!fileRelatedIds || fileRelatedIds.length == 0)
        {
            //link to Account and Admission unless passed Ids
            if (component.get('v.accountId')) fileRelatedIds.push(component.get('v.accountId'));
            if (component.get('v.currentAdmissionId')) fileRelatedIds.push(component.get('v.currentAdmissionId'));
            component.set('v.fileRelatedIds', fileRelatedIds);
        }

        if (titleFlag) {
        	helper.getContentVersions(component, event, helper);     
        }
        // document.body.style.overflow = 'hidden';
    },	
    handleDate : function(component, event, helper) {
        var newRequest = component.get("v.newRI");
        let titleFlag = component.get("v.rowIdx");
        if (newRequest.Date_Requested__c == '' && titleFlag !== -1) {
        	newRequest.Date_Requested__c = moment().format('YYYY-MM-DD');
        //debugger;
        }
        component.set("v.newRI", newRequest);
    },
    toggleModal : function(component, event, helper) {
        var fileName = 'No file selected!';
        component.set("v.newRI",{
            "sobjectType":"Request_Item__c",
            "Responsible_Contact__c":"",
            "Action__c":"",
            "Item_Requested__c":"",
            "Date_Requested__c":null,
            "Date_Confirmed__c":null,
            "Status__c":"",
            "Notes__c":"",
            "Admissions_Requirement__c":""
        });
        component.set("v.contentVersions",[]);
        component.set("v.showRequest",false);
    	component.set("v.requestItemModal",false);
        component.set("v.selectedRequestId",'');
        document.body.style.overflow = 'auto';
        component.set("v.requestTitle","New Request Item");
    },
    onFieldChange: function(component, event, helper) {
    	let requestItem = component.get("v.newRI");
        requestItem[event.getSource().get("v.fieldName")] = event.getParam('value');
        // console.log('changing ' + event.getSource().get("v.fieldName") + event.getParam('value'));
        if (event.getSource().get("v.fieldName") == 'Status__c')
        {
            // console.log('changing status field ' + event.getParam('value'));
            if (event.getParam('value') == 'Confirmed')
            {
            	helper.addRequiredField(component, 'Date_Confirmed__c', 'Date Confirmed');
            	if ( !requestItem.Date_Confirmed__c)
            	{
                	requestItem.Date_Confirmed__c = moment().format('YYYY-MM-DD');
                }
            } else
            {
            	helper.removeRequiredField(component, 'Date_Confirmed__c', 'Date Confirmed');
            }
        }
        component.set("v.newRI",requestItem);
    },
    // save : function(component, event, helper) {
        
    //     helper.toggleModalSpinner(component, 0);    
    //     component.set("v.errorMessage",'');
        
    //     let newRequestItem = component.get("v.newRI");
    //     let adReqId = component.get("v.selectedRow");
    //     if (newRequestItem.Admissions_Requirement__c == '') {
    //         newRequestItem.Admissions_Requirement__c = adReqId;    
    //     }
    //     if(newRequestItem.Date_Requested__c == '') {
    //         delete newRequestItem.Date_Requested__c;
    //     }
    //     if(newRequestItem.Date_Confirmed__c == '') {
    //         delete newRequestItem.Date_Confirmed__c;
    //     }
    //     const isFieldsValid = helper.validateIsRequired(
    //             component,
    //             component.get("v.requiredFields"),
    //             newRequestItem);
    //     if(isFieldsValid){
    //         helper.hideCustomToast(component);
            
    //         /****Apex call*****/
    //         helper.callApexMethod(
    //             component,
    //             "dmlRequestItem",
    //             {'requestItem': JSON.stringify(newRequestItem)},
    //             function (result) {
    //                 if (result) {
    //                     if(component.get("v.requestId")) {
    //                         component.find('notifLib').showToast({
    //                             "message": 'Request Item was successfully updated.',
    //                             "variant": "success",
    //                             "mode" : "dismissable"
    //                         });      
    //                     } else {
    //                         let requestItems = component.get("v.requestItems");
    //                         let rowIndex = component.get("v.rowIdx");
    //                         if (rowIndex != null) {
    //                             requestItems[rowIndex] = result;
    //                             component.find('notifLib').showToast({
    //                                 "message": 'Request Item was successfully updated.',
    //                                 "variant": "success",
    //                                 "mode" : "dismissable"
    //                             });
    //                         } else {
    //                             // console.log(result);
    //                             // console.log(component.get("v.requestItems"));
    //                             component.get("v.selectedRequestId",result.Id);
    //                             requestItems.push(result);
    //                             component.find('notifLib').showToast({
    //                                 "message": 'Request Item was successfully created.',
    //                                 "variant": "success",
    //                                 "mode" : "dismissable"
    //                             });
    //                         }                   
    //                         component.set("v.requestItems",requestItems);
    //                     }
    //                     helper.toggleModalSpinner(component, 0);
    //                     component.set("v.requestItemModal",false);
    //                     document.body.style.overflow = 'auto';
    //                     let evt = component.getEvent("closeModalView");
                        
    //                     evt.fire();
    //                     // console.log('fired close modal event');
    //                 }
    //             },
    //             function(errorcallback){
    //                 helper.toggleModalSpinner(component, 0);

    //             }
    //         );
            
    //     } else{
    //         helper.showErrorMessage(component);
    //         helper.toggleModalSpinner(component, 0);
    //     } 
    // },
    downloadFile : function(component, event, helper) {
        
        let contentDocId = event.target.getAttribute("data-id"); 
        let atag = document.createElement('a');
        atag.href = '/sfc/servlet.shepherd/document/download/'+contentDocId;
        atag.click();
    },
    handleRefreshRelatedList : function(component, event, helper)
    {
        if (event.getParam('data') == 'Files')
        {
            helper.getContentVersions(component, event, helper);
        }
    },
    saveAndClose : function(component, event, helper)
    {
        helper.save(component, event, helper, true);
    },
    saveAndUpload : function(component, event, helper)
    {
        helper.save(component, event, helper, false);
    }
})
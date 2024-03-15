({
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
    validateIsRequired : function(component,fields, obj) {
      let errorMessage = component.get("v.errorMessage");
      
      return Object.keys(fields).reduce(function (validSoFar, field) {
          if (fields[field].required)
          {
            if(!obj[field]) {
                if(errorMessage === '' ) {
                    errorMessage = fields[field].label;
                } else {
                    errorMessage = errorMessage + ', ' + fields[field].label;  
                }
                component.set('v.errorMessage',errorMessage)
            }
            return validSoFar && obj[field];
          } else {
            return validSoFar;
          }
      }, true);
    },
    addRequiredField : function(component, fieldName, fieldLabel)
    {
        let reqFieldsObject = component.get('v.requiredFields');
        reqFieldsObject[fieldName] = { 'label': fieldLabel, 'required': true};
        component.set('v.requiredFields', reqFieldsObject);
    },
    removeRequiredField : function(component, fieldName, fieldLabel)
    {
        let reqFieldsObject = component.get('v.requiredFields');
        reqFieldsObject[fieldName] = { 'label': fieldLabel, 'required': false};
        component.set('v.requiredFields', reqFieldsObject);
    },
    showErrorMessage : function(component) {
        this.showCustomToast(component,{'type':'error','title':'Please review the errors in the page.','message':'Required fields missing: '+ component.get('v.errorMessage')});
    },

    parseURL : function() {
        var url = window.location.href,
            params = {},
            match;
        var regex = new RegExp("[?&]" + 'c__requestId' + "(=([^&#]*)|&|#|$)");    
        
        var results;
        if(regex.exec(url) != null){
            results = regex.exec(url);
        } 
        
        if (!results) return null;
        
        if (!results[2]) return '';
        
        if(results[2]){
            params.requestId =  decodeURIComponent(results[2].replace(/\+/g, " "));
        }
        return params;
    },
    // handleCDLData : function(component, event, helper, response) {
    	
    //     let accountId = component.get("v.accountId");
    //     /*call apex to create content document links*/
    //     if(response && response.contentDocumentId) {
            
    //         helper.callApexMethod(
    //             component,
    //             "uploadCDL",
    //             {
    //                 'accountId' : accountId,
    //                 'contentDocumentId' : response.contentDocumentId
    //             },
    //             function (result) {
    //                 if (result) {
    //                     component.set("v.showRequest",false);
    //                     component.set("v.requestItemModal",!component.get("v.requestItemModal"));
    //                     component.find('notifLib').showToast({
    //                         "message": 'Your file was successfully uploaded.',
    //                         "variant": "success",
    //                         "mode" : "dismissable"
    //                     });
    //                 }
    //                 helper.toggleModalSpinner(component, 0);    
    //             },
    //             function(errorcallback){
    //                 helper.toggleModalSpinner(component, 0);
    //             }
    //         );
    //     }
    // },
    save : function(component, event, helper, closeAfterSaving) {
        
        helper.toggleModalSpinner(component, 0);    
        component.set("v.errorMessage",'');
        
        let newRequestItem = component.get("v.newRI");
        let adReqId = component.get("v.selectedRow");
        if (newRequestItem.Admissions_Requirement__c == '') {
            newRequestItem.Admissions_Requirement__c = adReqId;    
        }
        if(newRequestItem.Date_Requested__c == '') {
            delete newRequestItem.Date_Requested__c;
        }
        if(newRequestItem.Date_Confirmed__c == '') {
            delete newRequestItem.Date_Confirmed__c;
        }
        const isFieldsValid = helper.validateIsRequired(
                component,
                component.get("v.requiredFields"),
                newRequestItem);
        if(isFieldsValid){
            helper.hideCustomToast(component);
            
            /****Apex call*****/
            helper.callApexMethod(
                component,
                "dmlRequestItem",
                {'requestItem': JSON.stringify(newRequestItem)},
                function (result) {
                    if (result) {
                        if(component.get("v.requestId")) {
                            component.find('notifLib').showToast({
                                "message": 'Request Item was successfully updated.',
                                "variant": "success",
                                "mode" : "dismissable"
                            });      
                        } else {
                            let requestItems = component.get("v.requestItems");
                            let rowIndex = component.get("v.rowIdx");
                            if (rowIndex != null) {
                                requestItems[rowIndex] = result;
                                component.find('notifLib').showToast({
                                    "message": 'Request Item was successfully updated.',
                                    "variant": "success",
                                    "mode" : "dismissable"
                                });
                            } else {
                                // console.log(result);
                                // console.log(component.get("v.requestItems"));
                                component.get("v.selectedRequestId",result.Id);
                                requestItems.push(result);
                                component.find('notifLib').showToast({
                                    "message": 'Request Item was successfully created.',
                                    "variant": "success",
                                    "mode" : "dismissable"
                                });
                            }                   
                            component.set("v.requestItems",requestItems);
                            let newRI = component.get('v.newRI');
                            newRI.Id = result.Id;
                            component.set('v.newRI', newRI);
                            component.set('v.selectedRequestId', result.Id);
                        }
                        helper.toggleModalSpinner(component, 0);

                        // component.set("v.requestItemModal",false);
                        // document.body.style.overflow = 'auto';
                        // let evt = component.getEvent("closeModalView");
                        
                        // evt.fire();
                        // // console.log('fired close modal event');
                        if (closeAfterSaving)
                        {
                            helper.closeThisComponent(component, event, helper);
                        }
                    }
                },
                function(errorText, component){
                    helper.toggleModalSpinner(component, 0);
                    
                    helper.showCustomToast(component,{'type':'error','title':'Error while saving a record: ','message': errorText});
                }
            );
            
        } else{
            helper.showErrorMessage(component);
            helper.toggleModalSpinner(component, 0);
        } 
    },
    closeThisComponent : function(component, event, helper)
    {
        component.set("v.requestItemModal",false);
        document.body.style.overflow = 'auto';
        let evt = component.getEvent("closeModalView");
        
        evt.fire();
    },
    getContentVersions : function(component, event, helper) {
        let reqId = component.get("v.selectedRequestId");
        /*call apex to get content document links*/
        if(reqId) {
            
            helper.callApexMethod(
                component,
                "getContents",
                {'parentId' : reqId},
                function (result) {
                    if (result) {
                        if (result.length > 0) {
                            component.set("v.attachFlag",true);
                        }
                        component.set("v.contentVersions",result);
                    }
                },
                function(errorcallback){
                    helper.toggleModalSpinner(component, 0);
                }
            );
        }
    }
})
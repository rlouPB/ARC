({
    doInit : function(component, event, helper) {
        helper.refreshRequirementsTable(component, event, helper);
        
	},
    handleRefreshButtonClick : function(component, event, helper)
    {
        helper.refreshRequirementsTable(component, event, helper);
    },
    

    handleAdmissionReqs : function(component, event, helper) {
        //keep click from also firing on table row
        event.stopPropagation();

        let admissionsReqId = event.getSource().get('v.name');
        let checkboxVal = event.getSource().get('v.checked');
        //component.find("spinner").set("v.class", "slds-show");
        helper.showSpinner(component);
        
        helper.callApexMethod(
            component,
            "updateAdmissionsRequirement",
            {
                'admissionReqId':admissionsReqId,
             	'checkVal':checkboxVal
            },
            function (result) {
                component.find('notifLib').showToast({
                    "message": 'Admission Requirement was successfully updated.',
                    "variant": "success",
                    "mode" : "dismissable"
                });

                if (checkboxVal)
                {
                    let evt = $A.get("e.c:refreshPatient");
                    evt.fire();
                }
                helper.hideSpinner(component);
            },
            function(errorcallback){
                component.find('notifLib').showToast({
                    "message": errorcallback,
                    "variant": "error",
                    "mode" : "dismissable"
                });
                helper.hideSpinner(component);
            }
        );
    },
    getRequestItems : function(component, event, helper) {
        component.set('v.buttonState', 'showRequirements'); //clicked on Requirement row, should make sure it's filtered by requirement
        helper.getRequestItems(component, event, helper);
    },
    onButtonGroupClick : function(component, event, helper) {
    	    
        var flag = false;
        
        var state = event.getSource().get("v.title");
        if(state == 'showRequirements' || state == 'showAllRequests') {
            component.set("v.buttonState", state);  
            if(state == 'showAllRequests') {
            	component.set("v.title",'All Request Items');	
                component.set('v.selectedRow','');
                component.set('v.selectedRequirement',null);
                flag = true;
            } else {
                component.set("v.title",'Request Items for Admissions Requirement');
            }
        } else if(state == 'showAll' || state == 'showOpen') {
            component.set("v.bottomBtnState", state); 
            flag = true;
        }
        //component.find("spinner").set("v.class", "slds-show");
        helper.showSpinner(component);

        helper.refreshRequirementsTable(component, event, helper);
    },
    handleEditRequests : function(component, event, helper) {
        let target = event.currentTarget;
        let rowIndex = target.getAttribute("data-row-index");
        component.set("v.rowIdx",rowIndex);
        let requestItem = component.get('v.requestItems')[rowIndex];
        component.set("v.selectedRequestId",requestItem.Id);
        let oldRequest = JSON.parse(JSON.stringify(requestItem));
        component.set("v.newRI",oldRequest);
        component.set("v.oldRequest",requestItem);
        component.set("v.showRequest",true);
    	component.set("v.requestItemModal",true);
        component.set("v.requestTitle",'Edit Request Item');
    },
    shownUploadSection : function(component, event, helper) {
        let target = event.currentTarget;
        let rowIndex = target.getAttribute("data-row-index");
        let requestItem = component.get('v.requestItems')[rowIndex];
        component.set("v.selectedRequestId",requestItem.Id);
        component.set("v.uploadRequest",requestItem);
        component.set("v.showUploadModal",true);
        document.body.style.overflow = 'hidden';
    },
    hideUploadModal : function(component, event, helper){
    	component.set("v.showUploadModal",false);   
      document.body.style.overflow = 'auto'; 
    },
    toggleModal : function(component, event, helper) {
        var fileName = 'No file selected!';
        let admissionsRequirementId = '';
        let selectedRequirement = component.get('v.selectedRequirement');
        let state = component.get("v.buttonState");
        if (selectedRequirement && selectedRequirement.Id && state == 'showRequirements')
        {
            admissionsRequirementId = selectedRequirement.Id;
        }
        component.set("v.newRI",{
            "sobjectType":"Request_Item__c",
            "Responsible_Contact__c":"",
            "Action__c":"",
            "Item_Requested__c":"",
            "Date_Requested__c":"",
            "Status__c":"Open",
            "Notes__c":"",
            "Admissions_Requirement__c": admissionsRequirementId
        });
        component.set("v.rowIdx",null);
        component.set("v.showRequest",true);
        component.set("v.requestItemModal",!component.get("v.requestItemModal"));
    	component.set("v.requestTitle","New Request Item");
    },

 	handleFileChange: function(component, event, helper) {
        var fileName = 'No file selected!';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }

    },
    stopPropagating : function(component, event, helper)
    {
        event.stopPropagation();
    }
})
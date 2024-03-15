({  
    
    // loadRelatedContacts: function(component, event, helper) {
    //     // Load Related Contacts from Salesforce    
    //     var action = component.get("c.getRelContacts");
    //     action.setParams({
    //         "accountId": component.get("v.accntId")
    //     });
    //     // Add callback behavior for when response is received
    //     action.setCallback(this, function(response) {
    //         var state = response.getState();
    //         if (state === "SUCCESS") {
    //             component.set("v.relContact", response.getReturnValue());                
    //             component.set("v.filterRelCon", response.getReturnValue());                
    //         }
    //         else {
    //             console.log("Failed with state: " + state);
    //         }
    //     });
    //     // Send action off to be executed
    //     $A.enqueueAction(action);
        
    // },

    doInit: function(component, event, helper) {
        
        //var self = this;
        helper.updateDisplayMode(component, event, helper);
        helper.loadRelatedContacts(component, event, helper);
        
        var action = component.get("c.fetchRelatedContactsInfo");
        action.setCallback(this, function(response) {
            var state1 = response.getState();
            if (state1 === "SUCCESS") {
                component.set("v.recTypeIds", response.getReturnValue().recordTypeIds);    
                component.set("v.lstOfRecordType", response.getReturnValue().recordTypeValues);  
                component.set("v.isSocialWorker", response.getReturnValue().isSocialWorker);   
                //if(response.getReturnValue().isSocialWorker) {
                    //var options = component.get("v.options");
                    //options = [{'label': 'All', 'value': 'All'}, ...options];
                    //component.set("v.options", options);   
                //}
            }
            else {
                console.log("Failed with state: " + state1);
            }
        });
        // Send action off to be executed
        $A.enqueueAction(action);

        
    },
    handleDisplayModeChange : function(component, event, helper) {
        if(event.getParam("oldValue") != event.getParam("value")) {
            helper.loadRelatedContacts(component, event, helper);
        }
    },

    handleRefreshEvent: function(component, event, helper)
    {
        if (event.getParam('data') == 'Related_Contacts__r')
        {
            helper.loadRelatedContacts(component, event, helper);
        }
    },
    handleRefreshButtonClick: function(component, event, helper)
    {
        helper.loadRelatedContacts(component, event, helper);
    },
    createRecord: function(component, event, helper) {
        var windowHash = window.location.href;
        component.set("v.isOpen", false);
        
        var action = component.get("c.getRecTypeId");
        var recordTypeLabel = component.find("selectid").get("v.value");
        action.setParams({
            "recordTypeLabel": recordTypeLabel
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var createRecordEvent = $A.get("e.force:createRecord");
                var RecTypeID  = response.getReturnValue();
                createRecordEvent.setParams({
                    "entityApiName": "Related_Contact__c",
                    "recordTypeId": RecTypeID,
                    "defaultFieldValues": {                             
                        'Account__c' : component.get("v.accntId")                
                    },
                    "panelOnDestroyCallback": function(event) {
                        window.location.href = windowHash;
                    }
                });
                createRecordEvent.fire();
                
            } else if (state == "INCOMPLETE") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Oops!",
                    "message": "No Internet Connection"
                });
                toastEvent.fire();
                
            } else if (state == "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please contact your administrator"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    closeModal: function(component, event, helper) {
        // set "isOpen" attribute to false for hide/close model box 
        component.set("v.isOpen", false);
        helper.loadRelatedContacts(component, event, helper);
    },

    handleAddRelatedContact : function(component, event, helper) {
        component.set("v.selectedRelatedContactRecordId", null);
        component.set("v.isOpen", true);
    },
    
    handleEditRecord : function(component, event, helper) {
        var recordId = event.target.id;
        console.log('selectedRelatedContactRecordId ' + recordId);
        component.set("v.selectedRelatedContactRecordId", recordId);
        component.set("v.navigationType","standard__recordPage");
        component.set("v.sObjectName","Related_Contact__c");
        component.set("v.actionType","view");
        helper.navigateToRespectivePage(component, event, helper);
        //component.set("v.isOpen", true);
    },

    openModal: function(component, event, helper) {
        // set "isOpen" attribute to true to show model box
        component.set("v.isOpen", true);
    },
    
    /*
    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:newRelatedContactRecord",
            componentAttributes: {
                recordId : component.get("v.accntId")  
            }
        });
        evt.fire();
    },
        
    createRecord : function(component, event, helper) {
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Related_Contact__c",       
            "defaultFieldValues": {                             
                'Account__c' : component.get("v.accntId")                
            }            
        });
        createRecordEvent.fire();
    },
    */    
    
    handleChange: function (component, event, helper) {
        var changeValue = event.getParam("value");
        console.log('changeValue '+ changeValue);
        helper.filterRelatedContacts(component, event, helper);        
    },
    
    editRecord : function(component, event, helper) {
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({            
            "recordId": event.target.id            
        });
        editRecordEvent.fire();
    },
    
    onLaunchMerge : function(component, event, helper) {
		component.set('v.showMergeComponent',true);	
	}
    
    
})
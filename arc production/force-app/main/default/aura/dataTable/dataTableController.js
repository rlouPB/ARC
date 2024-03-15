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
        
        helper.loadRelatedContacts(component, event, helper);
        // Load Record Ids from Salesforce
        var action1 = component.get("c.getRecTypesIds");
        // Add callback behavior for when response is received
        action1.setCallback(this, function(response) {
            var state1 = response.getState();
            if (state1 === "SUCCESS") {
                component.set("v.recTypeIds", response.getReturnValue());              
            }
            else {
                console.log("Failed with state: " + state1);
            }
        });
        // Send action off to be executed
        $A.enqueueAction(action1);
        
        // Load Record Types from Salesforce
        var action2 = component.get("c.fetchRecordTypeValues");
        action2.setCallback(this, function(response) {
        component.set("v.lstOfRecordType", response.getReturnValue());
        });
        $A.enqueueAction(action2);
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
    
    handleChange: function (component, event) {
        var changeValue = event.getParam("value");
        var obj = component.get("v.relContact");
        if(changeValue == 'All'){
            component.set("v.filterRelCon", obj);
        }
        else{           
            var filteredArray = [];
            for (var i in obj){
                if(obj[i].RecordType.Name == changeValue){
                    filteredArray.push(obj[i]);
                }                    
            }
            component.set("v.filterRelCon", filteredArray);  
        }        
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
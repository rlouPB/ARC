({
    updateDisplayMode : function(component, event, helper) {
        console.log('called updateDisplayMode');
        helper.showSpinner(component, event, helper);
        // Load Related Contacts from Salesforce    
        var action = component.get("c.getAccount");
        action.setParams({
            "accountId": component.get("v.accntId")
        });
        // Add callback behavior for when response is received
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue().Current_Admission_Stage__c == 'Admitted') {
                    console.log('Admitted');
                    component.set("v.value", "Authorized");
                    component.set("v.displayMode", "patient");
                } else {
                    console.log('Not Admitted');
                }               
            }
            else {
                console.log("Failed with state: " + state);
            }
            helper.hideSpinner(component, event, helper);
        });
        // Send action off to be executed
        $A.enqueueAction(action);
    },

	loadRelatedContacts: function(component, event, helper) {
        console.log('called loadRelatedContacts');
        helper.showSpinner(component, event, helper);
        // Load Related Contacts from Salesforce    
        var action = component.get("c.getRelContacts");
        action.setParams({
            "accountId": component.get("v.accntId"),
        });
        // Add callback behavior for when response is received
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.relContact", response.getReturnValue());                
                component.set("v.filterRelCon", response.getReturnValue());
                this.filterRelatedContacts(component, event, helper);                
            }
            else {
                console.log("Failed with state: " + state);
            }
            helper.hideSpinner(component, event, helper);
        });
        // Send action off to be executed
        $A.enqueueAction(action);
        
    },

    filterRelatedContacts: function(component, event, helper)
    {
        console.log('filterRelatedContacts');
        var option = component.get("v.value");
        var displayMode = component.get("v.displayMode");
        var obj = component.get("v.relContact");
        var filteredArray = [];
        if(option == 'All') {
            component.set("v.filterRelCon", obj);
        } else if(option == 'Authorized') {
            for (var i in obj) {
                if(((obj[i].RecordType.Name == 'Personal' || (obj[i].RecordType.Name == 'Professional')) && 
                    ((obj[i].Authorization_Level__c && obj[i].Authorization_Level__c.includes('Level')) 
                        || obj[i].Letters__c == 'true')) || (obj[i].RecordType.Name == 'Patient')) {
                    filteredArray.push(obj[i]);
                }                    
            }
            component.set("v.filterRelCon", filteredArray);
        } else {
            for (var i in obj) {
                if(obj[i].RecordType.Name == option) {
                    filteredArray.push(obj[i]);
                }                    
            }
            component.set("v.filterRelCon", filteredArray);
        }
    },

    showSpinner: function(component, event, helper)
    {
        component.set('v.isRefreshing', true);
    },
    hideSpinner: function(component, event, helper)
    {
        component.set('v.isRefreshing', false);
    },
    toggleSpinner: function(component, event, helper)
    {
        component.set('v.isRefreshing', !component.get('v.isRefreshing'));
    },
    navigateToRespectivePage: function (component, event, helper) {
        var navService = component.find("navService");
        var recordId = component.get("v.selectedRelatedContactRecordId");
        var navigationType = component.get("v.navigationType");
        var sObjectName = component.get("v.sObjectName");
        var actionType = component.get("v.actionType");

        // Sets the route to /lightning/o/Account/home
        var pageReference = {
            type: navigationType,
            attributes: {
                objectApiName: sObjectName,
                recordId: recordId,
                actionName: actionType
            },
            state: {
                useRecordTypeCheck: 1
              }
        };
        component.set("v.pageReference", pageReference);
        navService.generateUrl(pageReference)
            .then(url=> {window.open(url, "_blank");});
      }

})
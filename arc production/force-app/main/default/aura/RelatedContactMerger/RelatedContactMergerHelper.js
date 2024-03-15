({
    getRelatedContactsHeleper : function(component,helper) {
        component.set("v.loading", true);
        helper.callApexMethod(
            component,
            "getRelatedContacts",
            {'patientId': component.get("v.recordId")},
            function(result) {
                component.set("v.loading", false);
                var recordWrapper = JSON.parse(result);
                console.log('results',recordWrapper);
                component.set('v.recordsWrapList',recordWrapper);
                //console.log('list-->',JSON.stringify(component.get('v.recordsWrapList')));
            },
            function(error) {
                component.set("v.loading", false);
            },
            false
        );
        
    },
    onError : function(errorString, component) {
        component.find('notifLib').showToast({
            "variant" : "error",
            "title": "Error",
            "message": "Problem merging records: " + errorString
        });
        component.set("v.loading", false);
        console.log('error',errorString);
    },
    onMasterRadioCheck : function(component, sObjectType, index) {
        var recordsWrapList = component.get('v.recordsWrapList');
        var radios = [];
        
        if (sObjectType === 'RelatedContact') {
            
            radios = component.find('relConRadio');
        } else if (sObjectType === 'Contact') {
            
            radios = component.find('conRadio');
        }
        
        if (radios && Array.isArray(radios)) {
            
            radios.forEach(function(radio){
                
                var radioIndex = radio.get('v.tabindex');
                console.log('radioIndex  index',radioIndex,index);
                if(radioIndex == index) {
                    
                    console.log('relContrue');
                    radio.set('v.checked',true);
                }
            });
        }
    },
    saveFinalRecords : function(component,helper) {
        debugger;
        var finalRecords = component.get('v.finalRec');
        let nonMasterRelContactId = component.get('v.nonMasterRecId');
        let nonMasterContactId;
        let selectedContactList = component.get('v.selectedContactList');
        selectedContactList.forEach(function(con) 
        {
            if (con.Id != finalRecords.contactRec.Id)
            {
                nonMasterContactId = con.Id;
            }
        });
        
        
        delete finalRecords.relatedContactRec.Contact__r;
        delete finalRecords.relatedContactRec.attributes;
        finalRecords.relatedContactRec['sobjectType'] = 'Related_Contact_c';
        console.log('finalRecords',JSON.parse(JSON.stringify(finalRecords)));
        console.log('nonMasterRelContactId', nonMasterRelContactId);
        component.set("v.loading", true);
        helper.callApexMethod(
            component,
            "mergeRelatedContacts",
            {'relatedConMasterRecordStr': JSON.stringify(finalRecords.relatedContactRec),
             'contactMasterRecordStr' : JSON.stringify(finalRecords.contactRec),
             'nonMasterRelContactId' : nonMasterRelContactId,
             'nonMasterContactId' : nonMasterContactId},
            function(result) {
                helper.getRelatedContactsHeleper(component,helper);
                component.set("v.selectedContactList", []);
                component.set("v.selectedList", []);
                console.log('results',result);
                var refreshEvent = $A.get('e.c:refreshRelatedList');
                //refreshEvent.data = 'Related_Contacts__r';
                refreshEvent.setParams({
                    "data" : 'Related_Contacts__r'
                });
                refreshEvent.fire();
                component.find('notifLib').showToast({
                    "variant" : "success",
                    "title": "Success!",
                    "message": "The Related Contacts have been updated successfully."
                });
                component.set("v.loading", false);
            },
            helper.onError,
            false
        );        
    },

    closeModal : function (component, event, helper, isConfirmed) 
    {
        let selectedList = component.get('v.selectedList');
        if (!isConfirmed && selectedList.length == 2)
        {
            component.set('v.showCancelConfirmationModal', true);
        } else
        {
            let refreshEvent = component.getEvent('refreshRelatedListEvent');
            refreshEvent.setParam('data', 'Related_Contacts__r');
            refreshEvent.fire();
            component.set('v.showModal',false);
        }
    },

    closeConfirmationModal : function (component, event, helper) {
        component.set('v.showConfirmationModal',false);
    },
    closeCancelConfirmationModal : function (component, event, helper) {
        component.set('v.showCancelConfirmationModal',false);
    },
})
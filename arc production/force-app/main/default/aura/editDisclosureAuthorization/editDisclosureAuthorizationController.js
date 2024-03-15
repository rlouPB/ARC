({
    doInit: function(component, event, helper) {
        
    },
    handleLoad: function(component, event, helper) {
        var admissionId = component.get('v.admissionId');
        if(admissionId) {
            component.find("admissionIdField").set("v.value", admissionId);
        }
        var institutionId = component.get('v.institutionId');
        if(institutionId) {
            component.find("institutionIdField").set("v.value", institutionId);
        }
        var providerId = component.get('v.providerId');
        if(providerId) {
            component.find("providerIdField").set("v.value", providerId);
        }
    },
    save : function(component, event, helper)
    {
        var theForm = component.find('theForm');
        theForm.submit();
    },
    handleCancel: function(component, event, helper) {
        var isDirty = component.get("v.isDirty");
    	if(isDirty) {
    		component.set("v.showCancelModal", true);
    	} else {
    		helper.closeModal(component, event, helper);
        }
    },
    handleSuccess : function(component, event, helper)
    {
        var response = event.getParam('response');

        console.log('handleSuccess');
        var result = {};
        result.Name = response.fields.Expiration_Date__c.value;
        result.Id = response.id;
        helper.closeModal(component, event, helper, result);
    },
    handleIsDirty: function(component, event, helper) {
        component.set('v.isDirty', true);
    },
    handleCloseModalEvent: function(component, event, helper) {
        var isDirty = component.get("v.isDirty");
    	if(isDirty) {
    		component.set("v.showCancelModal", true);
    	} else {
    		helper.closeModal(component, event, helper);
        }
    },
    handleDiscardChanges: function(component, event, helper) {
        component.set('v.showCancelModal', false);
        helper.closeModal(component, event, helper);
    },
    handleBackToDisclosureAuthorization: function(component, event, helper) {
        component.set('v.showCancelModal', false);
    }
})
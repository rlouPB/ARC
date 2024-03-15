({
    handleRequestedByChange : function(component, event, helper) {
        component.set("v.changedFields",[{field:'Consultation_Requested_By__c',value:event.getParam("value")}]);
        console.log("Consultation_Requested_By__c: changed value:"+event.getParam("value"));
        helper.fireNoteChangedEvent(component, event, helper);
    },
    handleRequestedByClincianChange : function(component, event, helper) {
        component.set("v.changedFields",[{field:'Consultation_Requested_By_User__c',value:event.getParam("value").value}]);
        helper.fireNoteChangedEvent(component, event, helper);
    }
})
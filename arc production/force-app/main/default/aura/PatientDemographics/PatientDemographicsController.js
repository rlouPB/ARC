({
    myAction : function(component, event, helper) {

    },

    doInit : function(component, event, helper) {
        helper.setPronounsFilter(component);
    },

    editOn : function(component, event, helper) {
        component.set('v.isEdit', true);
    },

    editOff : function(component, event, helper) {
        component.set('v.isEdit', false);
        component.set('v.loading', false);
        setTimeout(function(){
            var pref = component.get('v.contactRecord')["Preferred_Pronouns__c"];
            if (pref != null && pref != undefined){
                component.set('v.preferredPronounsText', pref);
            }
        }, 1000);
    },

    handleSaveRecord: function(cmp, event, helper) {
        // console.log('Saving the contact details.');
        cmp.set('v.loading', true);
    },

    onEditError: function(cmp,e,h){
        console.log('patient demographics onEditError');
        let params = e.getParams();
        console.log('params', params)
        h.showToast({
            type:"error",
            title:params.message,
            message:params.detail,
            duration: 30000
        });
        cmp.set('v.loading',false);
    },

    onEditSuccess: function(cmp,e,h){
        h.showToast({
            type:"success",
            message:'record saved',
            duration: 10000
        });
        cmp.set('v.loading', false);
    },
})
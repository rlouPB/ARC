({
    doInit : function(component, event, helper) {
        helper.initialize(component);
    },
    buttonClick : function(cmp,e,h) {
        cmp.set('v.currentTab',e.currentTarget.dataset.id)
    },
})
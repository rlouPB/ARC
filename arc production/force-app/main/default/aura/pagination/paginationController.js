({
    Next : function(component, event, helper) {
        component.set("v.currentPage",component.get("v.currentPage") + 1);
    },
    Previous : function(component, event, helper) {
        component.set("v.currentPage",component.get("v.currentPage") - 1);
    }
})
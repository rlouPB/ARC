({
    doInit:function(component, event, helper) {
        //window.addEventListener('resize', helper.sizeColumns);
        helper.sizeColumns(component, event, helper);
    },
    handleResetClick:function(component, event, helper) 
    {
        component.set("v.showResetDomainsModal", true);
    },
    handleConfirmResetClick:function(component, event, helper) 
    {
        //component.find("domainRating").set("v.value", undefined);
        const cmps = component.find("domainRating");
        if (!cmps) return;
        if ($A.util.isArray(cmps)) {
            cmps.forEach(cmp => {
                cmp.set("v.value", undefined);
            })
        } else {
            cmp.set("v.value", undefined);
        }
        component.set("v.showResetDomainsModal", false);
    },
    handleBackToEGO: function(component, event, helper) {
        component.set("v.showResetDomainsModal", false);
    }
    
})
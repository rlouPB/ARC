({
    onManageInterventionsClick : function(cmp, event, helper) {
        cmp.set('v.showManageInterventionsModal',true);
    },
    handleCloseModal:function(component,event,helper)
    {
        $A.get('e.force:refreshView').fire();
        var instanceName=event.getParam("data");
        if(instanceName=='showManageInterventionsModal'){
            component.set("v.showManageInterventionsModal",false);
        }
    },
})
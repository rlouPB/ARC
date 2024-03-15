({
    onInit : function(cmp, event, helper) {
        helper.showSpinner(cmp);
        helper.callApexMethod( cmp, "completeActionItem",{ actionItemId : cmp.get('v.recordId') },function(result){
            helper.showSpinner(cmp);
            if(result){
                helper.showToast({
                    type:"error",
                    message:result,
                    duration: 10000
                });
            }else{
                helper.showToast({
                    type:"success",
                    message:"Action Item Completed",
                    duration: 10000
                });
                $A.get("e.force:refreshView").fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
    }
})
({
    doInit : function(component, event, helper)
    {
        // Check if showing scale rating
        helper.showHideRatingScale(component,event,helper);
    },
    addNewGoal:function(component, event, helper)
    {
        helper.addNewGoal(component);
    },
    cancelGoal:function(component, event, helper)
    {
        //var goalIndex=event.getParam("goalIndex");
        var goalList=component.get("v.goalList");
        if(!$A.util.isEmpty(goalList)){
            //goalList.splice(goalIndex,1);
            component.set("v.goalList",goalList);
        }
    }
})
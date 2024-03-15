({
	doInit:function(component, event, helper)
    {
    },
    handleOnClickEditGoal : function(component, event, helper) {
		component.set("v.isGoalEditDisable",false);
	},
    handleOnClickCancelGoal:function(component, event, helper)
    {
        let goal = component.get("v.goal");
        goal.isDeleted = true;
        if(!$A.util.isEmpty(goal.objectives) && goal.objectives.length > 0){
            goal.objectives.forEach(function(objective){
                objective.isDeleted = true;
            });
        }
        component.set("v.goal", goal);
        var goalIndex=component.get("v.goalCounter");
        var goalCancelEvent=component.getEvent("goalCancelEvent");
        goalCancelEvent.setParams({
            "goalIndex":goalIndex
        });
        goalCancelEvent.fire();
	},
    handleEGOAction:function(component, event, helper)
    {
        let eventAction = event.getParam("action");
        if(!$A.util.isEmpty(eventAction)){
            if(eventAction == "Validate"){
                helper.validate(component,event,helper);
            }
        }
    },
    handleChange:function(component, event, helper)
    {
        var myAttri = component.find("goalRating").get("v.value");
        console.log(myAttri);
        helper.validate(component,event,helper);
    },
    handleResetClick:function(component, event, helper) 
    {
        component.find("goalRating").set("v.value", undefined);
    }
})
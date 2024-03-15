({
    doInit : function(component, event, helper) {
        var goal=component.get("v.goal");
        console.log('in doInit - goal.goalObj.Met_Discontinued_Date__c : ' + goal.goalObj.Met_Discontinued_Date__c);
    },
    onGoalStatusChanged:function(component, event, helper) {
        var goal=component.get("v.goal");
        if(goal.goalObj.Status__c!='Continue Goal'){
            //goal.goalObj.Met_Discontinued_Date__c=$A.localizationService.formatDate(new Date(), "MM/dd/yyyy");
            goal.goalObj.Met_Discontinued_Date__c=$A.localizationService.formatDateUTC(new Date(), "YYYY-MM-DD");
        }else{
            goal.goalObj.Met_Discontinued_Date__c=null;
        }
        component.set("v.goal",goal);
    },
    handleOnClickEditGoal:function(component, event, helper)
    {
        component.set("v.isGoalDisable",false);
    },
    handleOnClickCancelGoal:function(component, event, helper)
    {
        var isDirty = component.get("v.isDirty");
        if(isDirty) {
            component.set("v.showCancelModal", true);
        } else {
            var goalIndex=component.get("v.goalCounter");
            var goalCancelEvent=component.getEvent("goalCancelEvent");
            goalCancelEvent.setParams({
                "goalIndex":goalIndex
            });
            goalCancelEvent.fire();
        }
	},
    handleIsDirty:function(component, event, helper)
	{
        component.set("v.isDirty", true);
	},
    handleDiscardChanges: function(component, event, helper) {
        var goalIndex=component.get("v.goalCounter");
        var goalCancelEvent=component.getEvent("goalCancelEvent");
        goalCancelEvent.setParams({
            "goalIndex":goalIndex
        });
        goalCancelEvent.fire();
        component.set("v.showCancelModal", false);
    },
    handleBackToGoal: function(component, event, helper) {
        component.set("v.showCancelModal", false);
    },    
})
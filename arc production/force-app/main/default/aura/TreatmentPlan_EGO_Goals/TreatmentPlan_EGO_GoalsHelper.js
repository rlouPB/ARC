({
    /**
     * When not to show:
     * 1.  When goal list is empty
     * 2.  If goal list is not empty, check if any of them has "Continued From Goal", if yes, show scale
     */
    showHideRatingScale:function(component,event,helper)
    {
        var goalList=component.get("v.goalList");
        var isGoalEmpty=$A.util.isEmpty(goalList);
        console.log('isGoalEmpty:'+isGoalEmpty);
        if(isGoalEmpty)
        {
            component.get("v.showRatingScale",false);
        }else
        {
            goalList.some(function(goal){
                console.log(goal.goalObj.Label__c+' Id:'+($A.util.isEmpty(goal.goalObj.Id)));
                if(!$A.util.isEmpty(goal.goalObj.Id))
                {
                    component.set("v.showRatingScale",true);
                    return;
                }
            });
        }
    },
    addNewGoal : function(component)
    {
        var goalList=component.get("v.goalList");
        let max = goalList.length == 0? 0 : Math.max(...goalList.map(x=>x.goalObj.Order__c).filter(x=>!isNaN(x)));        
        goalList.push({
            "goalObj":{
                "sobjectType":"Goal__c",
                "Label__c":"",
                "Source__c":"Patient",
                "Order__c" : max+1,
            },
            "objectives":[],
            "newTargetDate":component.get("v.newTargetDate"),
            "isDeleted":false
        });
        component.set("v.goalList",goalList);
    }
})
({
    doInit : function(component, event, helper) {
        let goals = component.get("v.goals");
        console.log('TreatmentPlanGoals doInit goals: ', goals);
        console.log('TreatmentPlanGoals doInit goals.length: ', goals.length);
        
        component.set("v.minIndex", goals.length+1);
        component.set("v.index", goals.length);
        console.log('TreatmentPlanGoals doInit minIndex: ', component.get("v.minIndex"));
        console.log('TreatmentPlanGoals doInit index: ', component.get("v.index"));
    },
	addGoal : function(component, event, helper) {
        var todayDate=component.get("v.todayDate");
        var newTargetDate=component.get("v.newTargetDate");
        var goals=component.get("v.goals");
        let max = goals.length == 0? 0 : Math.max(...goals.map(x=>x.goalObj.Order__c).filter(x=>!isNaN(x)));        
        
        goals.push({"goalObj":{"sobjectType":"Goal__c",
                               "Label__c":"",
                               "Date_Added__c":todayDate,
                               "Target_Date__c":newTargetDate,
                               "Order__c" : max+1},
                    "objectives":[],
                    "newTargetDate":newTargetDate
                   });
        component.set("v.goals",goals);
        component.set("v.index", component.get("v.index") + 1);
        console.log('TreatmentPlanGoals addGoal minIndex: ', component.get("v.minIndex"));
        console.log('TreatmentPlanGoals addGoal index: ', component.get("v.index"));

        // for(var i = 0; i<goals.length; i++) {
        //     let goalsJson = JSON.stringify(cmp.get("v.goals"));
        // console.log('goalsJson : ' + goalsJson);
        //     console.log('goals[i].Label__c : ' + goals[i].Label__c);
        //     console.log('goals[i].Order__c : ' + goals[i].Order__c);
        // }
        let goalsJson = JSON.stringify(component.get("v.goals"));
        console.log('goalsJson : ' + goalsJson);
        
        if (component.get("v.index") >= component.get("v.minIndex")) {
            component.set("v.showCancel", true);
        }
	},
    cancelGoal:function(component, event, helper)
    {
        var goalIndex=event.getParam("goalIndex");
        var goals=component.get("v.goals");
        if(!$A.util.isEmpty(goals)){
            goals.splice(goalIndex,1);
            component.set("v.goals",goals);
        }
    },
    cancelNewGoal:function(component, event, helper)
    {
        var goalIndex=event.getParam("goalIndex");
        var goals=component.get("v.goals");
        console.log('TreatmentPlanGoals canceNewGoal goals.length: ', goals.length);
        if(!$A.util.isEmpty(goals)){
            goals = goals.slice(0, goals.length - 1);
            console.log('TreatmentPlanGoals canceNewGoal goals: ', goals);
            component.set("v.index", component.get("v.index") - 1);
            component.set("v.goals",goals);
            console.log('TreatmentPlanGoals canceNewGoal minIndex: ', component.get("v.minIndex"));
            console.log('TreatmentPlanGoals canceNewGoal index: ', component.get("v.index"));
            if (component.get("v.index") < component.get("v.minIndex")) {
                component.set("v.showCancel", false);
            }
        }
    }
})
({
	addObjective : function(component, event, helper)
    {
        var newTargetDate=component.get("v.newTargetDate");
        var objectives=component.get("v.objectives");
        let max = objectives.length==0? 0 : Math.max( ...objectives.map(x=>x.objectiveObj.Order__c).filter(x=>!isNaN(x)) );
        objectives.push({"objectiveObj":{"sobjectType":"Objective__c","Label__c":"","Status__c":"Continue","Target_Date__c":newTargetDate, "Order__c": ++max},"newTargetDate":newTargetDate});
        component.set("v.objectives",objectives);

        let objsJson = JSON.stringify(component.get("v.objectives"));
        console.log('objsJson : ' + objsJson);
	},
    cancelObjective:function(component,event,helper)
    {
        var objectiveIndex=event.getParam("objectiveIndex");
        var objectives=component.get("v.objectives");
        if(!$A.util.isEmpty(objectives)){
            objectives.splice(objectiveIndex,1);
            component.set("v.objectives",objectives);
        }
    }
})
({
    addNewObjective:function(component){
        var objectiveList=component.get("v.objectiveList");
        let max = objectiveList.length==0? 0 : Math.max( ...objectiveList.map(x=>x.objectiveObj.Order__c).filter(x=>!isNaN(x)) );
        objectiveList.push({
            "objectiveObj":{
                "sobjectType":"Objective__c",
                "Label__c":"",
                "Source__c":"Patient",
                "Order__c": ++max,
            },
            "newTargetDate":component.get("v.newTargetDate"),
            "isDeleted":false
        });
        component.set("v.objectiveList",objectiveList);
    }
})
({
    // Initialization
    doInit : function(component, event, helper) {
    },
    addNewObjective:function(component,event,helper){
        helper.addNewObjective(component);
    },
    cancelObjective:function(component,event,helper)
    {
        //var objectiveIndex=event.getParam("objectiveIndex");
        var objectiveList=component.get("v.objectiveList");
        if(!$A.util.isEmpty(objectiveList)){
            //objectiveList.splice(objectiveIndex,1);
            component.set("v.objectiveList",objectiveList);
        }
    }
})
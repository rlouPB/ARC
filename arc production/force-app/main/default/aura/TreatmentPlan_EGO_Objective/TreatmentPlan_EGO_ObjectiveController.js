({
  doInit: function(component, event, helper)
  {
  },
  handleOnClickEditObjective: function(component, event, helper)
  {
    component.set("v.isObjectiveEditDisable", false);
  },
  handleOnClickCancelObjective: function(component, event, helper)
  {
      let objective = component.get("v.objective");
      objective.isDeleted = true;
      component.set("v.objective", objective);
      let objectiveCounter = component.get("v.objectiveCounter");
      let objectiveCancelEvent = component.getEvent("objectiveCancelEvent");
      objectiveCancelEvent.setParams({ objectiveIndex: objectiveCounter });
      objectiveCancelEvent.fire();
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
      helper.validate(component,event,helper);
  },
  handleResetClick:function(component, event, helper) 
  {
        component.find("objectiveRating").set("v.value", undefined);
  }
});
({
	onStatusChanged : function(component, event, helper) {
		var objective=component.get("v.objective");
        if(objective.objectiveObj.Status__c!='Continue'){
            //objective.objectiveObj.Met_Discontinued_Date__c=new Date();
            objective.objectiveObj.Met_Discontinued_Date__c=$A.localizationService.formatDateUTC(new Date(), "YYYY-MM-DD");
        }else{
            objective.objectiveObj.Met_Discontinued_Date__c=null;
        }
        component.set("v.objective",objective);
    },
    onGoalStatusChanged: function(component, event, helper)
    {
        var oldGoalStatus=event.getParam("oldValue");
        var newGoalStatus=event.getParam("value");
        console.log('onGoalStatusChanged - old value:'+oldGoalStatus+', new value:'+newGoalStatus);
        if(oldGoalStatus!=newGoalStatus){
            var objective=component.get("v.objective");
            if(objective){
                if(newGoalStatus=='Goal Met' || newGoalStatus=='Discontinued')
                {
                    objective.objectiveObj.Status__c=(newGoalStatus=='Goal Met'?'Met':'Discontinued');
                    //objective.objectiveObj.Met_Discontinued_Date__c=new Date();
                    objective.objectiveObj.Met_Discontinued_Date__c=$A.localizationService.formatDateUTC(new Date(), "YYYY-MM-DD");
                }else{
                    objective.objectiveObj.Status__c='Continue';
                    objective.objectiveObj.Met_Discontinued_Date__c=null;
                }
                component.set("v.objective",objective);
            }
        }
    },
    handleOnClickEditObjective:function(component, event, helper)
    {
        component.set("v.isObjectiveDisable",false);
    },
    handleOnClickCancelObjective:function(component,event,helper)
    {
        var isDirty = component.get("v.isDirty");
    	if(isDirty) {
    		component.set("v.showCancelModal", true);
        } else {
            var selfIndex=component.get("v.selfIndex");
            var objectiveCancelEvent=component.getEvent("objectiveCancelEvent");
            objectiveCancelEvent.setParams({"objectiveIndex":selfIndex});
            objectiveCancelEvent.fire();
        }
    },
    handleIsDirty:function(component, event, helper)
	{
    	component.set("v.isDirty", true);
	},
    handleDiscardChanges: function(component, event, helper) {
        var selfIndex=component.get("v.selfIndex");
        var objectiveCancelEvent=component.getEvent("objectiveCancelEvent");
        objectiveCancelEvent.setParams({"objectiveIndex":selfIndex});
        objectiveCancelEvent.fire();
        component.set("v.showCancelModal", false);
    },
    handleBackToObjective: function(component, event, helper) {
        component.set("v.showCancelModal", false);
    }
})
({
    validate:function(component, event,helper)
    {
        /*
        var goalRating = component.find("goalRating");
        if(goalRating!=undefined)
        {
            goalRating=goalRating.get("v.value");
            var ratingErrorMessage = component.find("ratingErrorMessage");
            if ($A.util.isEmpty(goalRating))
            {
                $A.util.addClass(ratingErrorMessage, "slds-show");
                $A.util.removeClass(ratingErrorMessage, "slds-hide");
            }
            else
            {
                $A.util.addClass(ratingErrorMessage, "slds-hide");
                $A.util.removeClass(ratingErrorMessage, "slds-show");
            }
        }*/
        /*
        var goalLabel = component.find("goalLabel");
        if(goalLabel!=undefined)
        {
            goalLabel=goalLabel.get("v.value");
            console.log("goalLabel1:"+goalLabel);
            if ($A.util.isEmpty(goalLabel))
            {
                console.log("goalLabel2:"+goalLabel);
                component.set("v.hasLabelError", true);
            }
            else
            {
                component.set("v.hasLabelError", false);
            }
        }*/
        let goal = component.get("v.goal");
        console.log("goal.goalObj.Label__c:"+goal.goalObj.Label__c);
        if($A.util.isEmpty(goal.goalObj.Label__c)){
            goal.isLabelEmpty = true;
        }else{
            goal.isLabelEmpty = false;
        }
        if($A.util.isEmpty(goal.rating)){
            goal.isRatingEmpty = true;
        }else{
            goal.isRatingEmpty = false;
        }
        component.set("v.goal", goal);
    }
})
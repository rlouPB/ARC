({
    validate:function(component, event,helper)
    {
        /*
        var objectiveRating = component.find("objectiveRating");
        if(objectiveRating!=undefined)
        {
            objectiveRating=objectiveRating.get("v.value");
            var ratingErrorMessage = component.find("ratingErrorMessage");
            if ($A.util.isEmpty(objectiveRating))
            {
                $A.util.addClass(ratingErrorMessage, "slds-show");
                $A.util.removeClass(ratingErrorMessage, "slds-hide");
            }
            else
            {
                $A.util.addClass(ratingErrorMessage, "slds-hide");
                $A.util.removeClass(ratingErrorMessage, "slds-show");
            }
        }
        var objectiveLabel = component.find("objectiveLabel");
        if(objectiveLabel!=undefined)
        {
            objectiveLabel=objectiveLabel.get("v.value");
            var objectiveErrorMessage = component.find("objectiveErrorMessage");
            if ($A.util.isEmpty(objectiveLabel))
            {
                $A.util.addClass(objectiveErrorMessage, "slds-show");
                $A.util.removeClass(objectiveErrorMessage, "slds-hide");
            }
            else
            {
                $A.util.addClass(objectiveErrorMessage, "slds-hide");
                $A.util.removeClass(objectiveErrorMessage, "slds-show");
            }
        }
        */
        let objective = component.get("v.objective");
        if($A.util.isEmpty(objective.objectiveObj.Label__c)){
            objective.isLabelEmpty = true;
        }else{
            objective.isLabelEmpty = false;
        }
        if($A.util.isEmpty(objective.rating)){
            objective.isRatingEmpty = true;
        }else{
            objective.isRatingEmpty = false;
        }
        component.set("v.objective", objective);
    }
})
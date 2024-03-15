({
    helperMethod : function() {

    },

    setPronounsFilter : function(component) {
        var pronounsFilter = [
            {
                'fieldName': 'Field__c',
                'condition': '=',
                'value': "Contact.Preferred_Pronouns__c"
            }    
        ];

        component.set("v.preferredPronounsFilter", pronounsFilter);
    },

    showToast: function(params){
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent){
            toastEvent.setParams(params);
            toastEvent.fire();
        }
    }
})
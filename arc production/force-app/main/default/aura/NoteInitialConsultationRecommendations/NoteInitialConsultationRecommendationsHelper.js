({
    loadRecommendations: function(component, event, helper) {
        component.set("v.isLoading", true);
        var patientNote = component.get('v.theNote.patientNote');
        var recommendations = patientNote.Recommendations__c;
        console.log('recommendations ' + recommendations);
        if(recommendations) {
            var value = recommendations.split(';');
            component.set('v.value', value);
        }
        component.set("v.isLoading", false);
    }
})
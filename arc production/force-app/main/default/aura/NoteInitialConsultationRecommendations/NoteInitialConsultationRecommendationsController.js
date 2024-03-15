({
    doInit: function(component, event, helper) {
        helper.loadRecommendations(component, event, helper);
    },
    handleRecommendationsChanged: function(component, event, helper) {
        if(component.get("v.isLoading") == false){
            var value = component.get('v.value');
            console.log('value ' + value);
            if(value) {
                var recommendations = '';
                if(Array.isArray(value)) {
                    recommendations = value.join(';');
                }
                var changedFields = [
                    {
                        'field': 'Recommendations__c',
                        'value': recommendations
                    },
                    {
                        'field': 'Comments__c',
                        'value': component.get('v.theNote.patientNote.Comments__c')
                    }
                ];
                component.set('v.changedFields', changedFields);
                helper.fireNoteChangedEvent(component, event, helper);
            }
        }
    }
})
({
    doInit : function(component, event, helper) 
    {
        var patientNote = component.get('v.patientNote.patientNote');
        // if (patientNote && patientNote.Completed_By__r && patientNote.Completed_By__r.Name) component.set('v.showCompleted', true);
        // if (patientNote && patientNote.Finalized_By__r && patientNote.Finalized_By__r.Name) component.set('v.showFinalized', true);
        if (patientNote && patientNote.Completed_By__c && patientNote.Completed_By_Professional_Name__c) component.set('v.showCompleted', true);
        if (patientNote && patientNote.Finalized_By__c && patientNote.Finalized_By_Professional_Name__c) component.set('v.showFinalized', true);
    }
})
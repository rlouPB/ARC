({
    doInit : function(component, event, helper) 
    {
        debugger;
        let noteItem = component.get("v.noteItem");
        var subsetField = JSON.parse(noteItem.noteItem.Embedded_Component_Parameters__c).subsetField;
        let theNote = component.get("v.theNote");
        component.set("v.subsetHtml", theNote.patientNote[subsetField]);
    },
    refreshFromSource : function(component, event, helper) 
    {
        helper.getSOHSnapshotSubset(component, event, helper);
    }
})
({
    fireNoteChangedEvent: function(component, event, helper) {
        var noteChangedEvent = component.getEvent('noteChanged');
        var instanceName = component.get('v.instanceName');
        var changedFields = component.get('v.changedFields');
        noteChangedEvent.setParams({
            'changedFields': changedFields,
            'instanceName': instanceName
        });
        noteChangedEvent.fire();
    }
})
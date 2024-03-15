({
    doInit: function(component, event, helper) {
        helper.getUser(component, helper);
        helper.getNote(component, helper);
        
	},

	handleAutoSave: function(component, event, helper)
	{
		
	},

    handleSaveNote: function(component, event, helper) {
        helper.showSpinner(component);
        helper.saveNote(component, helper);
    },
    completeNote: function(component, event, helper) {
        helper.showSpinner(component);
        var status = 'Complete';
        helper.saveNote(component, helper, status);
    },
    finalizeNote: function(component, event, helper) {
        helper.showSpinner(component);
        var status = 'Finalize';
        helper.saveNote(component, helper, status);
    },
    handleNoteChanged: function(component, event, helper) {
        console.log('handleNoteChanged in PatientNote');
        var changedFields = event.getParam('changedFields');
        var patientNote = component.get('v.patientNote');
        changedFields.forEach(element => {
            //var patientNoteFieldString = 'v.patientNote.patientNote.' + element.field;
            //component.set(patientNoteFieldString, element.value);
            patientNote.patientNote[element.field] = element.value;
        });
        
        patientNote.lastChangedFields = changedFields;
        component.set('v.patientNote', patientNote);
		console.log('handleNoteChanged patientNote ' + JSON.stringify(component.get('v.patientNote.patientNote')));
		
		if (component.get("v.firstChange") == true)
		{
			component.set("v.firstChange", false);
		} else
		{
			var asComp = component.find("autosaveComp");
			asComp.resetTimer();
		}
    },
    handleCloseConfirmationModal : function(component, event, helper) {
        component.set("v.showConfirmationModal", false);
    },
    handleOpenNewTab : function(component, event, helper) {
        let patientNote = component.get('v.patientNote');
        window.open("/"+patientNote.patientNote.Id);
    }
})
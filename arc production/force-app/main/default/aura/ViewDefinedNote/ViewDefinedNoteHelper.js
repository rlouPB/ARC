({
    getUser: function(component, helper) {
        var userId = $A.get('$SObjectType.CurrentUser.Id');
        helper.callApexMethod(
            component,
            'getUser',
            {
                userId: userId
            },
            function (result) {
                console.log('User ' + JSON.stringify(result));
                component.set('v.requiresCoSign', result.Requires_Co_Signature__c);
                helper.hideSpinner(component);
            },
            function(errorcallback) {
                helper.hideSpinner(component);
            }
        );
    },
    getNote: function(component, helper) {
        this.callApexMethod(
            component,
            "getNote",
            { 
                "patientNoteId": component.get('v.recordId')
            },
            function (result) {
                console.log('result ' + JSON.stringify(result));
                var parameters = JSON.stringify(JSON.parse(result.noteDefinition.Parameters__c));
                console.log('parameters ' + parameters);
                result.noteDefinition.Parameters__c = JSON.parse(result.noteDefinition.Parameters__c);
                console.log('result ' + JSON.stringify(result));
                helper.updateFields(component, helper, result);
                

                var imageUrl = '/sfc/servlet.shepherd/version/download/' + result.patientNote.Account__r.Photo_Version_Id__c +'?t=' + new Date().getTime();
                //var imageUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=' + result.patientNote.Account__r.Photo_Version_Id__c;
                
                component.set('v.imageUrl', imageUrl);
                
                //helper.hideSpinner(component);
            },
            function(error){
                helper.showCustomToast(component, {
                    'type': 'error',
                    'title': 'Error while loading the Patient Note.',
                    'message': error
                });
                helper.hideSpinner(component);
            },
            true
        );
    },
    saveNote: function(component, helper, status) {
        var note = component.get("v.patientNote");
        var errorMessage = 'There was an error updating the Note.';
        var successMessage = 'Successfully updated the Note.';
        if(!status) {
            status = 'Draft';
        }
        console.log("about to clean patientNoteJSON:"+JSON.stringify(note.patientNote));
        if($A.util.isObject(note.patientNote.Owner)){
            //note.patientNote.OwnerId = note.patientNote.Owner.Id;
            delete note.patientNote.Owner;
        }
        console.log("Ready to save patientNoteJSON:"+JSON.stringify(note.patientNote));
        this.callApexMethod(
            component,
            "saveNote",
            { 
                "patientNoteJSON": JSON.stringify(note.patientNote),
                "newStatus": status
            },
            function (result) {
                if(result === 'success') {
                    component.find('notifLib').showToast({
                        "title": "Success!",
                        "message": successMessage
                    });
                    component.set('v.status', status);
                    if(status == 'Completed' || status == 'Finalized' || status == 'Complete' || 
                        status == 'Finalize') {
                        component.set('v.readOnly', true);
                    }
                    helper.getNote(component, helper);
                }
                else {
                    if(result === 'Patient Note is already finalized.'){
                        helper.showCustomToast(component, {
                            'type': 'warning',
                            'title': errorMessage,
                            'message': result
                        });
                        helper.getNote(component, helper);
                    }else if(result === 'This Patient Note has been changed in a different session. To avoid overwriting changes, please edit the current version'){
                        component.set("v.showConfirmationModal", true);
                        component.set("v.showErrorMessage", true);
                        helper.hideSpinner(component);
                    }else{
                        helper.showCustomToast(component, {
                            'type': 'error',
                            'title': errorMessage,
                            'message': result
                        });
                        helper.hideSpinner(component);
                    }
                }
            },
            function(error){
                helper.showCustomToast(component, {
                    'type': 'error',
                    'title': 'Error while saving a record',
                    'message': error
                });
                helper.hideSpinner(component);
            },
            true
		);

		var asComp = component.find("autosaveComp");
		console.log("Turn off autosave");
		asComp.autosaveOff();
		component.set("v.firstChange", true);
    },
    updateFields: function(component, helper, result) {
        var parameters = result.noteDefinition.Parameters__c;
        //component.set('v.parameters', result.noteDefinition.Parameters__c);
        var patientNote = result;
        console.log('parameters before update ' + JSON.stringify(parameters));
        if(parameters.header && parameters.header.fieldNames) {
            parameters.header.fieldNames.forEach(element => {
                if(element.fieldName && !element.source) {
                    var value = element.fieldName.split('.').reduce(
                        (a, b) => (typeof a == "undefined" || a === null) ? 
                        a : a[b], patientNote.patientNote);
                    element.value = value;
                }
            });
        }
        if(parameters.sidebar && parameters.sidebar.fieldNames) {
            parameters.sidebar.fieldNames.forEach(element => {
                if(element.fieldName && !element.source) {
                    var value = element.fieldName.split('.').reduce(
                        (a, b) => (typeof a == "undefined" || a === null) ? 
                        a : a[b], patientNote.patientNote);
                    element.value = value;
                }
            });
        }
        if(parameters.footer && parameters.footer.fieldNames) {
            parameters.footer.fieldNames.forEach(element => {
                if(element.fieldName && !element.source) {
                    var value = element.fieldName.split('.').reduce(
                        (a, b) => (typeof a == "undefined" || a === null) ? 
                        a : a[b], patientNote.patientNote);
                    element.value = value;
                }
            });
        }
        if(patientNote.noteItems) {
            patientNote.noteItems.forEach(element => {
                if(element.noteItem.Field_Name__c) {
                    var value = element.noteItem.Field_Name__c.split('.').reduce(
                        (a, b) => a[b], patientNote.patientNote);
                    if(element.value != value) {
                        element.value = value;
                    }
                }
            });
        }
        console.log('parameters after update ' + JSON.stringify(parameters));
        console.log('patientNote.noteItems after update ' + JSON.stringify(patientNote.noteItems));
        component.set('v.parameters', parameters);
        component.set('v.patientNote', patientNote);
        var status = patientNote.patientNote.Status__c;
        component.set('v.status', status);
        if(status == 'Completed' || status == 'Finalized') {
            component.set('v.readOnly', true);
        }
        component.set('v.showSpinner', false);
    }
})
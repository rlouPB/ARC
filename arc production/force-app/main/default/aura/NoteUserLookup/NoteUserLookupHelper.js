({
    interpretParameters : function(component, event, helper)
    {
        var label = component.get('v.label');
        if (!label || label.length == 0)
        {
            component.set('v.labelHidden', false);
        }

        var noteItem = component.get('v.noteItem');
        if (noteItem.noteItem.Is_Required__c == true)
        {
            component.set('v.required', true);
        }

        var sObject = component.get('v.sObject');
        var displayField = component.get('v.displayField');
        if (!displayField)
        {
            if (sObject == 'User')
            {
                displayField = component.get('v.userDisplayField');
            } else
            {
                displayField = component.get('v.permSetAssignDisplayField');
            }
            component.set('v.displayField', displayField);
        }

        var displayFieldValue = component.get('v.displayFieldValue');
        if (!displayFieldValue)
        {
            if (sObject == 'User')
            {
                displayFieldValue = component.get('v.userDisplayFieldValue');
            } else
            {
                displayFieldValue = component.get('v.permSetAssignDisplayFieldValue');
            }
            component.set('v.displayFieldValue', displayFieldValue);
        }

    },
    populateSelectedRecord : function(component, event, helper)
    {
        let me = this;
        var theNote = component.get('v.theNote');
        var patientNoteField = component.get('v.patientNoteField');
        var displayField = component.get('v.displayField');
        var recordId = theNote.patientNote[patientNoteField];
        var label = '';
        var isRecord = (recordId) ? true : false;
        if (recordId)
        {
            //if standard field
            var relationshipName = patientNoteField.substr(0,patientNoteField.length-2);
            if (patientNoteField.endsWith('__c'))
            {  
                //custom field
                relationshipName = patientNoteField.substr(0,patientNoteField.length-1) + 'r';
            }
            label = theNote.patientNote[relationshipName][displayField];
            if( !label ){ label = theNote.patientNote[relationshipName].Name || theNote.patientNote[relationshipName].Professional_Name__c; }
            if( !label ){ label = me.deepFind(theNote.patientNote[relationshipName],displayField) }
        }
        var selectedRecord = 
        {
            'value': recordId,
            'label': label,
            'isRecord': isRecord
        };
        console.log('populateSelectedRecord ' + JSON.stringify(selectedRecord));
        component.set('v.selectedRecord', selectedRecord);
        component.set('v.recordLoaded', true);
    },
    deepFind: function(obj, path) {
        if(obj && path){
            var paths = path.split('.')
                , current = obj
                , i;
            
            for (i = 0; i < paths.length; ++i) {
                if (current[paths[i]] == undefined) {
                    return undefined;
                } else {
                    current = current[paths[i]];
                }
            }
            return current;
        }
    },
    changeSelected : function(component, event, helper) 
    {
        if (!component.get('v.recordLoaded')) return;

        //populate changedFields
        var selectedRecord = component.get('v.selectedRecord');
        var patientNoteField = component.get('v.patientNoteField');
        var newValue = null;
        if (patientNoteField)
        
        {
            if (selectedRecord.isRecord)
            {
                newValue = selectedRecord.value
            }
            var changedFields = component.set('v.changedFields') || [];
            changedFields.push(
                {
                    field: component.get('v.patientNoteField'),
                    value: newValue
                });
            component.set('v.changedFields', changedFields);
            
            //fire NoteChangedEvent
            helper.fireNoteChangedEvent(component, event, helper);
        }
    },
    populateFilters : function(component, event, helper)
    {
        var userLookupFilters = [
            {
                'fieldName': 'IsActive',
                'condition': '=',
                'value': true
            }
        ];
        var psetLookupFilters = [
            {
                'fieldName': 'Assignee.IsActive',
                'condition': '=',
                'value': true
            }
        ];
        var userTypes = component.get('v.userTypes');
        if (userTypes && userTypes.length > 0)
        {
            //userTypes should be a single-quoted, comma-separated String
            var userTypeString = '(';
            userTypeString += userTypes;
            userTypeString += ')';

            userLookupFilters.push(
            {
                'fieldName': 'UserType',
                'condition': 'IN',
                'value': userTypeString
            });
            psetLookupFilters.push(
            {
                'fieldName': 'Assignee.UserType',
                'condition': 'IN',
                'value': userTypeString
            });
        }
        var profileNames = component.get('v.profileNames');
        if (profileNames && profileNames.length > 0)
        {
            //profileNames should be a single-quoted, comma-separated String
            var profileNameString = '(';
            profileNameString += profileNames;
            profileNameString += ')';

            userLookupFilters.push(
            {
                'fieldName': 'Profile.Name',
                'condition': 'IN',
                'value': profileNameString
            });
            psetLookupFilters.push(
            {
                'fieldName': 'Assignee.Profile.Name',
                'condition': 'IN',
                'value': profileNameString
            });
        }
        var permissionSetNames = component.get('v.permissionSetNames');
        if (permissionSetNames && permissionSetNames.length > 0)
        {
            //permissionSetNames should be a single-quoted, comma-separated String
            var permSetNameString = '(';
            permSetNameString += permissionSetNames;
            permSetNameString += ')';

            psetLookupFilters.push(
            {
                'fieldName': 'PermissionSet.Name',
                'condition': 'IN',
                'value': permSetNameString
            });
        }
        
        
        component.set('v.filters', userLookupFilters);
        component.set('v.psetAssignmentFilters', psetLookupFilters);
    }
        

})
({
    doInit : function(component, event, helper) {
        helper.applyCSS(component, event);

        var selectedRowsObject = {"requestItems": [], "admissionMedications": [], "forms": [],"baseNotes":[]};
        
        component.set("v.selectedRowsObject", selectedRowsObject);
        
        //var grandParentId = '0015B00000TPXZHQA5';
        //component.set("v.recordId", grandParentId);
        // var grandParentId = component.get("v.recordId");
        // var grandparentLookupFieldName = 'Patient_Account__c';

        let simpleRecord = component.get('v.simpleRecord');
        if (simpleRecord.Current_Admission__c)
        {
            let selectedTargetObject = {
                "value": simpleRecord.Current_Admission__c,
                "label": simpleRecord.Current_Admission__r.Name,
                "isRecord":true
            };
            component.set('v.selectedTargetObject', selectedTargetObject);
        }

        component.set("v.sourceObjectLabel", 'Move items from this admission file');
        component.set("v.targetObjectLabel", 'Move items to this admission file');
        component.set("v.parentObjectName", 'Admission__c');
        
        // var lookupFilters = component.get("v.lookupFilters");
        
        // lookupFilters.source.push({
        //     'fieldName': grandparentLookupFieldName,
        //     'condition': '=',
        //     'value': grandParentId
        // });
        // lookupFilters.source.push({
        //     'fieldName': 'Id',
        //     'condition': '!=',
        //     'value': simpleRecord.Current_Admission__c
        // });

        // lookupFilters.target.push({
        //     'fieldName': grandparentLookupFieldName,
        //     'condition': '=',
        //     'value': grandParentId
        // });
        helper.buildLookupFilters(component, event, helper);

        // component.set("v.lookupFilters", lookupFilters);


        helper.loadAvailableAdmissions(component);
    },
    
    handleSelectedSourceObjectChanged : function(component, event, helper) {
        component.set('v.showRelatedLists', false);
        var selectedSourceObject = component.get("v.selectedSourceObject");
        console.log('selectedSourceObject ' + JSON.stringify(selectedSourceObject));
        //helper.updateRequestItemFilters(component, selectedSourceObject);
        helper.buildLookupFilters(component, event, helper);
        helper.loadRelatedObjectDatatables(component);
    },

    handleSelectedTargetObjectChanged : function(component, event, helper)
    {
        //build source filters
        helper.buildLookupFilters(component, event, helper);
    },

    handleCheckboxChange : function(component, event, helper)
    {
        let eventId = event.getSource().get('v.id');
        let checked = event.getSource().get('v.checked');
        console.log('checked ' + checked);
        let name = event.getSource().get('v.name');
        
        helper.updateSelectedRows(component, eventId, checked, name);
    },

    handleCheckAllBoxes : function(component, event, helper)
    {
        let name = event.getSource().get('v.name');
        let checked = event.getSource().get('v.checked');
        helper.selectAllRows(component, checked, name);
    },

    removeComponent : function(component, event, helper) {
        helper.removeComponent(component, event);
    },

    handleSaveButtonClick : function(component, event, helper) 
    {
        helper.showSpinner(component, 'Moving Records');
        var selectedRowsObject = component.get("v.selectedRowsObject");
        console.log('selectedRowsObject ' + JSON.stringify(selectedRowsObject));

        helper.moveSelectedRecords(component, helper);
    }
})
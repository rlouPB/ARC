({
    setFilters: function(component) {
    	var staffLookupFilter = [
            {
                'fieldName': 'IsActive',
                'condition': '=',
                'value': true
            }    
        ];
        component.set("v.staffLookupFilter", staffLookupFilter);

        var contactLookupFilter = [
            {
                'fieldName': 'Available_For_Schedule__c',
                'condition': '=',
                'value': true
            }    
        ];
        component.set("v.contactLookupFilter", contactLookupFilter);

        var groupLookupFilter = [
            {
                'fieldName': 'Active__c',
                'condition': '=',
                'value': true
            }    
        ];
        component.set("v.groupLookupFilter", groupLookupFilter);    

        var resourceLookupFilter = [
            {
                'fieldName': 'Active__c',
                'condition': '=',
                'value': true
            }    
        ];
        component.set("v.resourceLookupFilter", resourceLookupFilter);
    },
    updateHeaderRow: function(component) {
        var headerRow = component.find('header-row');
        headerRow.updateRow();
    },
    updateScheduleRows: function(component) {
        var selectedRecordList = component.get('v.selectedRecordList');
        component.set('v.selectedRecordList', selectedRecordList);
    }
})
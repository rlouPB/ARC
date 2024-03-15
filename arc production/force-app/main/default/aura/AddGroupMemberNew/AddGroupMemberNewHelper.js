({
	setFilters: function(component) 
    {
        var staffLookupFilter = [
            {
                'fieldName': 'UserType',
                'condition': '=',
                'value': 'Standard'
            },
            {
                'fieldName': 'IsActive',
                'condition': '=',
                'value': true
            }    
        ];
        component.set("v.staffLookupFilter", staffLookupFilter);

        var patientLookupFilter = [
            {
                'fieldName': 'RecordType.Name',
                'condition': '=',
                'value': 'Patient'
            },
            {
                'fieldName': 'Account.Current_Admission_Stage__c',
                'condition': '=',
                'value': 'Admitted'
            } 
        ];
        component.set("v.patientLookupFilter", patientLookupFilter);
    }
})
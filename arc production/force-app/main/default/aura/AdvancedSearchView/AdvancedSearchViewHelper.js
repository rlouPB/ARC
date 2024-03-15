({
    prepopulateSearchForValue : function(component){
        var context = component.get("v.context");
        var searchOptions = component.get("v.searchOptions");
        var buttonState = component.get("v.buttonState");
        console.log('context');
        
        if(buttonState === 'contactSearch') {
            if(context == 'patient'){
                searchOptions.searchFor = 'patient';
            } else if(context == 'contact'){
                searchOptions.searchFor = 'relatedContact';
            }
        } else if(buttonState === 'searchByCall') {
            if(context == 'patient'){
                searchOptions.searchFor = 'patient';
            } else if(context == 'contact'){
                searchOptions.searchFor = 'caller';
            }
        }
        
        console.log('searchOptions**', searchOptions);
        component.set("v.searchOptions", searchOptions);
    },
    
    searchByCallHelper : function(component, helper) {
        component.set("v.loading", true);
        var searchOptions = component.get("v.searchOptions") || {};
        var task = component.get("v.task") || {};
        component.set("v.data", []);
        var isValidated = true;
        
        searchOptions.gender = task.Caller_Gender__c;
        searchOptions.city = task.Patient_City__c;
        searchOptions.state = task.Patient_State__c;
        searchOptions.phone = task.Calling_Number__c;
        
        console.log(searchOptions.startDate);
        if(searchOptions.startDate && !searchOptions.endDate){
            console.log('Entered');
            isValidated = false;
        } else if(!searchOptions.startDate && searchOptions.endDate) {
            isValidated = false;
        }
        
        if(isValidated === true) { 
            console.log('searchOptions##', JSON.stringify(searchOptions));
            helper.callApexMethod(
                component,
                "searchByCall",
                {
                    'searchOptions' : JSON.stringify(searchOptions),
                    'recordId' : component.get("v.recordId") || ''
                },
                function(response) {
                    component.set("v.loading", false);
                    console.log('response**',response);
                    var result = JSON.parse(response);
                    
                    if(result.length > 0){
                        helper.initializeSearchByCallResult(component, result);
                    } else {
                        component.set("v.noRecordsFound", true);
                    }
                },
                function(errorcallback){
                    component.set("v.loading", false);
                    console.log('error');
                    component.find('notifLib').showToast({
                        "message": errorcallback,
                        "variant": "error",
                        "mode" : "dismissable"
                    });
                },
                false
            );
        } else {
            component.set("v.loading", false);
            component.find('notifLib').showToast({
                "message": 'Search Range should have both Start Date and End Date value.',
                "variant": "error",
                "mode" : "dismissable"
            });
        }
    },
    
    contactSearchHelper : function(component, helper) {
        var searchOptions = component.get("v.searchOptions") || {};
        var task = component.get("v.task") || {};
        component.set("v.loading", true);
        component.set("v.data", []);
        
        searchOptions.gender = task.Caller_Gender__c;
        searchOptions.city = task.Patient_City__c;
        searchOptions.state = task.Patient_State__c;
        searchOptions.phone = task.Calling_Number__c;
        
        
        console.log('searchOptions##', JSON.stringify(searchOptions));
        
        
        helper.callApexMethod(
            component,
            "contactSearch",
            {
                'searchOptions' : JSON.stringify(searchOptions),
                'recordId' : component.get("v.recordId") || ''
            },
            function(response) {
                console.log('response**',response);
                component.set("v.loading", false);
                var result = JSON.parse(response);
                
                if(result.length > 0){
                    helper.initializeContactSearchResult(component, result);
                } else {
                    component.set("v.noRecordsFound", true);
                }
            },
            function(errorcallback){
                console.log('error');
                component.set("v.loading", false);
                component.find('notifLib').showToast({
                    "message": errorcallback,
                    "variant": "error",
                    "mode" : "dismissable"
                });
            },
            false
        );
        
    },
    
    initializeSearchByCallResult : function(component, result) {
        var columns = [
            {
                type: 'button',
                typeAttributes : {
                    name: 'selectRow',
                    label: 'Select',
                    variant: 'brand',
                }
            },
            {
                type: 'date',
                fieldName: 'callDateTime',
                label: 'Call Date/Time',
                sortable: true
            },
            {
                type: 'text',
                fieldName: 'callingPhoneNumber',
                label: 'Calling Phone Number',
                sortable: true
            },
            {
                type: 'url',
                fieldName: 'patientUrl',
                label: 'Patient Name',
                sortable: true,
                typeAttributes : {
                    label: { fieldName: 'accountName'},
                    target: '_blank'
                }
            },
            {
                type: 'text',
                fieldName: 'patientAddress',
                label: 'Patient Address'
            },
            {
                type: 'url',
                fieldName: 'contactUrl',
                label: 'Contact Name',
                sortable: true,
                typeAttributes : {
                    label: {fieldName: 'callerName'},
                    target: '_blank'
                }
            },
            {
                type: 'text',
                fieldName: 'role',
                sortable: true,
                label: 'Caller Relationship to Patient'
            },
            {
                type: 'text',
                fieldName: 'ARCUserName',
                sortable: true,
                label: 'ARC User'
            },
            {
                type: 'text',
                fieldName: 'callSubject',
                sortable: true,
                label: 'Call Subject'
            },
            {
                type: 'text',
                fieldName: 'callStatus',
                sortable: true,
                label: 'Call Status'
            },
            {
                type: 'text',
                fieldName: 'callNotes',
                label: 'Call Notes'
            }
        ];
        
        component.set("v.columns", columns);
        component.set("v.data", result);
    },
    
    initializeContactSearchResult : function(component, result) {
        var columns = [
            {
                type: 'button',
                typeAttributes : {
                    name: 'selectRow',
                    label: 'Select',
                    variant: 'brand',
                }
            },
            {
                type: 'url',
                fieldName: 'patientUrl',
                label: 'Patient Name',
                sortable: true,
                typeAttributes : {
                    label: { fieldName: 'accountName'},
                    target: '_blank'
                }
            },
            {
                type: 'text',
                fieldName: 'patientTaskSubject',
                label: 'Most Recent Call about Patient',
                sortable: true
            },
            {
                type: 'url',
                fieldName: 'contactUrl',
                label: 'Contact Name',
                sortable: true,
                typeAttributes : {
                    label: {fieldName: 'name'},
                    target: '_blank'
                }
            },
            {
                type: 'text',
                fieldName: 'role',
                sortable: true,
                label: 'Relationship to Patient'
            },
            {
                type: 'text',
                fieldName: 'contactTaskSubject',
                label: 'Most Recent Call with Contact',
                sortable: true
            }
        ];
        
        component.set("v.columns", columns);
        component.set("v.data", result);
    },
    
    sortData: function (component, fieldName, sortDirection) {
        var tableData = component.get("v.data");
        
        tableData.sort(function(a,b){
            console.log('a,b', a[fieldName], b[fieldName]);
            if(sortDirection == 'asc'){
                if((a[fieldName] === null || a[fieldName] === '') && b[fieldName] === 0){
                    return -1;
                }
                if(a[fieldName] === 0 && (b[fieldName] === null || b[fieldName] === '')){
                    return 1;
                }
                if(a[fieldName] === null || a[fieldName] === undefined){
                    a[fieldName] = '';
                }
                if(b[fieldName] === null || b[fieldName] === undefined){
                    b[fieldName] = '';
                }
                console.log('typeof(a[fieldName])',typeof(a[fieldName]));
                if (((typeof(a[fieldName]) !== 'number') ? a[fieldName].toLowerCase() : a[fieldName] ) < ((typeof(b[fieldName]) !== 'number') ? b[fieldName].toLowerCase() : b[fieldName] )) {
                    return -1;
                }
                if (((typeof(a[fieldName]) !== 'number') ? a[fieldName].toLowerCase() : a[fieldName] ) > ((typeof(b[fieldName]) !== 'number') ? b[fieldName].toLowerCase() : b[fieldName] )) {
                    return 1;
                }
                
                return 0; 
            } else if(sortDirection === 'desc'){
                if((a[fieldName] === null || a[fieldName] === '') && b[fieldName] === 0){
                    return 1;
                }
                if(a[fieldName] === 0 && (b[fieldName] === null || b[fieldName] === '')){
                    return -1;
                }
                if(a[fieldName] === null || a[fieldName] === undefined){
                    a[fieldName] = '';
                }
                if(b[fieldName] === null || b[fieldName] === undefined){
                    b[fieldName] = '';
                }
                if (((typeof(a[fieldName]) !== 'number') ? a[fieldName].toLowerCase() : a[fieldName] ) > ((typeof(b[fieldName]) !== 'number') ? b[fieldName].toLowerCase() : b[fieldName] )) {
                    return -1;
                }
                if (((typeof(a[fieldName]) !== 'number') ? a[fieldName].toLowerCase() : a[fieldName] ) < ((typeof(b[fieldName]) !== 'number') ? b[fieldName].toLowerCase() : b[fieldName] )) {
                    return 1;
                }
                
                return 0; 
            }
            
        });
        component.set("v.data", []);
        console.log('data', tableData);
        component.set("v.data", tableData);
    },
    
    sortBy: function (field, reverse, primer) {
        console.log('field', field);
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            console.log('a,b', a = key(a), b = key(b), reverse * ((a > b) - (b > a)));
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
            
        }
    }
})
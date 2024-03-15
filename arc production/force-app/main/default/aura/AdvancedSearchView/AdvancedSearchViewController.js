({
    doInit : function(component, event, helper) {
    	helper.prepopulateSearchForValue(component);
    },
    updateColumnSorting: function (component, event, helper) {
                
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        console.log('fieldName', fieldName, sortDirection);
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        if(sortDirection === 'asc'){
            var sort = {
                'fieldName' : fieldName,
                'order' : 'desc'
            };
            component.set("v.sort",sort);
        }
        if(sortDirection === 'desc') {
            var sort = {
                'fieldName' : fieldName,
                'order' : 'asc'
            };
            component.set("v.sort",sort);
        }
        
        helper.sortData(component, fieldName, sortDirection);
    },
    
	onButtonGroupClick : function(component, event, helper) {
		console.log('button  ', event.getSource().get("v.title"));
        var state = event.getSource().get("v.title");
        var searchOptions = component.get("v.searchOptions") || {};
        var task = component.get("v.task") || {};
        var options = [];
        
        console.log('searchFor', component.find("searchFor"));
        searchOptions.searchFor = '';
        searchOptions.startDate = '';
        searchOptions.endDate = '';
        searchOptions.ARCUser = '';
        searchOptions.isIncludeNonStarterCalls = true;
        
        component.set("v.searchForOptions", []); //to refresh radio group 
        if(state === 'contactSearch') {
            options = [{'label': 'Patient', 'value': 'patient'},
                       {'label': 'Related Contact', 'value': 'relatedContact'}];
        } else if(state === 'searchByCall'){
            options = [{'label': 'Patient', 'value': 'patient'},
                       {'label': 'Caller', 'value': 'caller'}]
        }
        
        component.set("v.searchForOptions", options);
        component.set("v.buttonState", state);
        component.set("v.columns", []);
        component.set("v.data", []);
        helper.prepopulateSearchForValue(component);
        
	},
    
    cancel : function(component, event, helper) {
        var evt = component.getEvent("closeModalView");
        evt.fire();
    },
    
    onSearch : function(component, event, helper) {
        console.log('searchOptions', JSON.stringify(component.get("v.searchOptions")));
        console.log('task', JSON.stringify(component.get("v.task")));
        component.set("v.noRecordsFound", false);
        var buttonState = component.get("v.buttonState");
        if(buttonState === 'contactSearch') {
            helper.contactSearchHelper(component, helper);
        } else if(buttonState === 'searchByCall') {
            helper.searchByCallHelper(component, helper);
        }
        
    },
    
    onCheckboxGroupChange : function(component, event, helper) {
        console.log('selected value', component.get("v.searchOptions"));
    },
    
    resetSearchOptions : function(component, event, helper) {
        var options = component.get("v.searchOptions");
        var searchFor = options.searchFor;
        var searchOptions = {'name':'', 'startDate':'','endDate':'', 'isIncludeNonStarterCalls':true,'ARCUser':''};
        var task = {'sobjectType': 'Task','Subject': '','Caller_Gender__c':'','Patient_City__c':'','Patient_State__c':'','Calling_Number__c':''};
        
        searchOptions.searchFor = searchFor || '';
        component.set("v.searchOptions", searchOptions);
        component.set("v.task", task);
        var userLookup = component.find('userLookup');
        if(userLookup){
            userLookup.closePill();
        }
    },
    
    getSelectedRow : function(component, event, helper) {
        console.log('entered');
        var row = event.getParam('row');
        var evt = component.getEvent("closeModalView");
        var data = {};
        var context = component.get("v.context") || 'patient';
        var buttonState = component.get("v.buttonState") || 'contactSearch';
        
        if(buttonState == 'contactSearch') {
            if(context == 'patient') {
                data.label = row.accountName || '';
                data.value = row.accountId;
            } else if(context == 'contact'){
                data.label = row.callerName;
                data.value = row.callerId;
            }
        }  else if(buttonState == 'searchByCall') {
            if(context == 'patient') {
                data.label = row.accountName;
                data.value = row.accountId;
            } else if(context == 'contact') {
                data.label = row.callerName;
                data.value = row.callerId;
            }
        }
        
        console.log('data', data);
        evt.setParams({
            "data" : data
        });
        evt.fire();
    }
})
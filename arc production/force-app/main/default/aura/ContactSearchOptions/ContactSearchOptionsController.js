({
    doInit : function(component, event, helper) {
        var searchType = component.get("v.searchType");
        var whoToSearch;
        console.log(searchType);
    	if(searchType === 'contactSearch') {
            whoToSearch = [{'label': 'Patient', 'value': 'patient'},
                       {'label': 'Related Contact', 'value': 'relatedContact'}];
        } else if(searchType === 'searchByCall' || searchType === 'searchAllColumns' || searchType === 'notesView'){
            whoToSearch = [{'label': 'Patient', 'value': 'patient'},
                       {'label': 'Person Spoken To', 'value': 'caller'}]            
        }

        component.set("v.whoToSearch", whoToSearch);
        helper.prepopulateWhoToSearch(component);
    },

	onButtonGroupClick : function(component, event, helper) {
		console.log('button  ', event.getSource().get("v.title"));
        var state = event.getSource().get("v.name");
        var searchData = component.get("v.searchData") || {};
        var task = component.get("v.task") || {};
        var options = [];
        
        console.log('searchFor', component.find("searchFor"));
        searchData.searchFor = '';
        searchData.startDate = '';
        searchData.endDate = '';
        searchData.ARCUser = '';
        searchData.isIncludeNonStarterCalls = true;
        
        component.set("v.whoToSearch", []); //to refresh radio group 
        if(state === 'contactSearch') {
            options = [{'label': 'Patient', 'value': 'patient'},
                       {'label': 'Related Contact', 'value': 'relatedContact'}];
        } else if(state === 'searchByCall' || state === 'searchAllColumns' || state === 'notesView'){
            options = [{'label': 'Patient', 'value': 'patient'},
                       {'label': 'Person Spoken To', 'value': 'caller'}];
            
            if(state === 'searchAllColumns'){
                component.set("v.isSelectedAll",true);
            } else if (state === 'notesView'){
                component.set("v.isSelectedAll",false);
            }
        }
        
        
        
        component.set("v.whoToSearch", options);
        component.set("v.searchType", state);
        helper.prepopulateWhoToSearch(component);
	},

    onSearch : function(component, event, helper) {
        let task = component.get("v.task"),
            searchData = component.get("v.searchData");
        
        searchData.gender = task.Caller_Gender__c;
        searchData.city = task.Patient_City__c;
        searchData.state = task.Patient_State__c;
        searchData.phone = task.Calling_Number__c;
        
        component.set("v.searchData",searchData);
        
        var btnEvent = component.getEvent("buttonClicked");
        btnEvent.setParams({
            "name" : event.getSource().get("v.name"),
            "data": {
                "contactSearchInfo" : searchData,
                "task" : component.get("v.task")
            }
        });
        btnEvent.fire();
       console.log(JSON.stringify(btnEvent.getParams()))
    },
    
    onCheckboxGroupChange : function(component, event, helper) {
        console.log('selected value', component.get("v.searchData"));
    },
    
    resetSearchOptions : function(component, event, helper) {
        var options = component.get("v.searchData");
        var searchFor = options.searchFor;
        var searchData = {'name':'', 'startDate':'','endDate':'', 'isIncludeNonStarterCalls':true,'ARCUser':''};
        var task = {'sobjectType': 'Task','Subject': '','Caller_Gender__c':'','Patient_City__c':'','Patient_State__c':'','Calling_Number__c':''};
        
        searchData.searchFor = searchFor || '';
        component.set("v.searchData", searchData);
        component.set("v.task", task);
        var userLookup = component.find('userLookup');
        if(userLookup){
            userLookup.closePill();
        }
        
        var btnEvent = component.getEvent("buttonClicked");
        btnEvent.setParams({
            "name" : event.getSource().get("v.name"),
            "data": {
                "contactSearchInfo" : component.get("v.searchData")
            }
        });
        btnEvent.fire();
    },
})
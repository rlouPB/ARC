({
	getGroupNote : function(component, event, helper) {
        var action = component.get("c.getGroupNoteFromId");
        action.setParams({
            "groupNoteId": component.get("v.recordId") 
        });
        action.setCallback(this, function(response){
           var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.objGroupNote", response.getReturnValue());
                if(response.getReturnValue().Group_Attendance__r){
                    var jsonData = response.getReturnValue().Group_Attendance__r;
                    jsonData.sort(function(a, b){
                       var nameA = a.Patient__r.Name.split(" ")[1].toLowerCase();
                        var nameB = b.Patient__r.Name.split(" ")[1].toLowerCase();
                        if (nameA < nameB) //sort string ascending
                            return -1 
                        if (nameA > nameB)
                            return 1
                        return 0 //default return value (no sorting)
                    })
                    console.log('jsonData',jsonData);
                    component.set("v.lstGroupAttendance", response.getReturnValue().Group_Attendance__r);
                    
                    console.log('response.getReturnValue().Group_Attendance__r',response.getReturnValue().Group_Attendance__r);
                }
                if(component.get("v.objGroupNote.Did_Group_Meet__c") == 'No'){
                    component.set("v.isGroupMeet", true);
                }
            }
        });
        $A.enqueueAction(action);
		
	},
    upsertGroupNote : function(component, event, helper){
        var action = component.get("c.updateGroupNote");
        var lstGA = [];
        lstGA = component.get("v.lstGroupAttendance");
        console.log('databeforeupsert',JSON.stringify(component.get("v.objGroupNote")));
        action.setParams({
            "objGroupNote": component.get("v.objGroupNote"),
            "lstGroupAttendance":lstGA
        });
        action.setCallback(this, function(response){
           var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            console.log('response', JSON.stringify(response));
            if(state === "SUCCESS"){
                console.log('upsert success',response.getReturnValue());
                component.set("v.objGroupNote", response.getReturnValue());
                toastEvent.setParams({
                    "title": "Success!",
                    "type" : "success",
                    "message": "The record has been updated successfully."
                });
                 toastEvent.fire();
            	$A.get("e.force:closeQuickAction").fire();
            }
            else{
                toastEvent.setParams({
                    "title": "Error!",
                      "type" : "error",
                    "message": "There was an error!"
                });
                toastEvent.fire();
            }
          
        });
        $A.enqueueAction(action);
    },
    finalizeGroupNote : function(component, event, helper){
         var action = component.get("c.finalizedGroupNote");
        console.log('databeforeupsert',JSON.stringify(component.get("v.objGroupNote")));
        action.setParams({
            "objGroupNote": component.get("v.objGroupNote") 
        });
        action.setCallback(this, function(response){
           var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            console.log('response', JSON.stringify(response));
            if(state === "SUCCESS"){
                console.log('upsert success',response.getReturnValue());
                component.set("v.objGroupNote", response.getReturnValue());
                toastEvent.setParams({
                    "title": "Success!",
                    "type" : "success",
                    "message": "The record has been finalized successfully."
                });
                 toastEvent.fire();
            	
            }
            else{
                toastEvent.setParams({
                    "title": "Error!",
                      "type" : "error",
                    "message": "There was an error!"
                });
                toastEvent.fire();
            }
          
        });
        $A.enqueueAction(action);
    },
    
    setFilters: function(component) {

        var ownerLookupFilter = [
            {
                'fieldName': 'IsActive',
                'condition': '=',
                'value': true
            }
        ];
        component.set("v.ownerLookupFilter", ownerLookupFilter);
    }
})
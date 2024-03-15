({
	init : function(component, event, helper) {
        
        // helper.getGroupNote(component, event, helper);
        // helper.setFilters(component);
        // if(component.get("v.objGroupNote.Did_Group_Meet__c") == 'No'){
        //             component.set("v.isGroupMeet", true);
        // }
        
        // if(component.get("v.objGroupNote.Status__c") == 'Finalized'){
        //     component.set("v.isReadOnly", true);
        // }
	},
    
    handleSelectedItemEvent : function(component, event, helper) {
        var newRecordId = component.get("v.selectedRecordPatient").value;
       console.log('new rec'+newRecordId);
         var lstGroupAttendance = component.get("v.lstGroupAttendance");
        var recordExists = false;
        if(lstGroupAttendance){
            for(var i = 0; i <lstGroupAttendance.length; i++ ){
                console.log('new rec'+newRecordId+'---newRC'+newRecordId);
                if(lstGroupAttendance[i].Patient__c == newRecordId){
                    recordExists = true;
                }
                
            }
        }
        console.log('new rec exists'+recordExists);
        if(recordExists == false){
           
            var params = event.getParams();
            var sourceInstanceName = params.sourceInstanceName;
            var selectedObj = params.selectedObj;
            console.log('sourceInstanceName',sourceInstanceName);
             console.log('selectedObj',selectedObj);
            console.log('serlectedrecord',component.get("v.selectedRecordPatient").value);
            //console.log('selectedObjasdasd',component.get("v.objGroupAttendance.Patient__c"));
            
           
            
            var action = component.get("c.getGroupAttendanceInstance");
            action.setParams({
                "accId": component.get("v.selectedRecordPatient").value,
                "groupNoteId": component.get("v.objGroupNote.Id")
            });
            action.setCallback(this,function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    var lstGA = component.get("v.lstGroupAttendance");
                    lstGA.push(response.getReturnValue());
                    component.set("v.lstGroupAttendance",lstGA);
                    console.log('ret rec',component.get("v.lstGroupAttendance"));
                }
            });
            $A.enqueueAction(action);
        }else{
            
            var childCmp = component.find("gaComponent")
             childCmp.duplicatePatient(newRecordId);
                       
        }
    },
    changeOwner : function(component, event, helper){
    
    	 component.set("v.ownerChange", true);
         var objMap = {};
        console.log('simple',JSON.stringify(component.get("v.objSimpleMeeting")));
        console.log('record',JSON.stringify(component.get("v.objmeeting")));
        //console.log(component.get("v.objGroupNote.OwnerId")); 
        objMap["value"] = component.get("v.objGroupNote.Owner.Id");
        objMap["label"] = component.get("v.objGroupNote.Owner.Name");
        objMap["isRecord"] = true;
        component.set("v.selectedRecord", objMap);
        
        var childCmp = component.find("ownerLookup");
        var retnMsg = childCmp.setSelectedRecord(component.get("v.selectedRecord"));
	},
    
    groupMeet : function(component, event, helper){
        
        console.log(event.getSource().get("v.value"));
        
        var option = event.getSource().get("v.value");
        
        
        if(option == 'No'){
        	component.set("v.isGroupMeet", true);
            console.log(option);
    	}
        else if(option == 'Yes' || option == 'None'){
            component.set("v.isGroupMeet", false);
            component.set("v.objGroupNote.Reason_Group_Did_Not_Meet__c", 'None');
        }
            
      
    },
    
    updateGroupNoteJS : function(component, event, helper){
        helper.upsertGroupNote(component, event, helper);
    },
    
    finalizeGroupNote : function(component, event, helper){
    	console.log('method called');
        var now = Date();
    	var finalizedUser = $A.get( "$SObjectType.CurrentUser.Id" );
    	component.set("v.objGroupNote.Finalized_By__c", finalizedUser);
    	//component.set("v.objGroupNote.Finalized_Datetime__c", now); // Commented it because it was giving field read error
    	component.set("v.objGroupNote.Status__c", 'Finalized');
    	component.set("v.isReadOnly", true);
        console.log('before call');
        helper.finalizeGroupNote(component, event, helper);
	},
    
    closeModal : function(component, event, helper){
         $A.get("e.force:closeQuickAction").fire(); 
    }
   
})
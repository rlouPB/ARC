({
	doInit : function(component, event, helper) {
		helper.loadData(component, event, helper);
	},
    closeModel : function(component, event, helper){
        if(component.get("v.isDataChanged")){
                    component.set("v.isModalOpenConfirmation", true);
        }
        else{
            component.set("v.isModalOpenConfirmation", false);
        	component.set("v.isModalOpen", false);
        }
    },
    closeModelConfirm : function(component, event, helper){
        
        component.set("v.isModalOpenConfirmation", false);
        component.set("v.isModalOpen", false);
        helper.loadData(component, event, helper);
    },
    gobackToEditing : function(component, event, helper){
        component.set("v.isModalOpenConfirmation", false);
        component.set("v.isModalOpen", true);
    },
    manageAssignedClinicians : function(component, event, helper){
        component.set("v.isModalOpen", true);
        component.set("v.isDataChanged", false);
    },
    addMember : function(component, event, helper){
        
      /*  var caseTeamMembers = component.get("v.caseTeamMembers");
        var params = event.getParams();
        var sourceInstanceName = params.sourceInstanceName;
        var selectedObj = params.selectedObj;
        
        
        caseTeamMembers.push({});
        component.set("v.caseTeamMembers",caseTeamMembers);
        */
        
        
        
    },
    upsertCaseTeamMembers : function(component, event, helper){
        var action = component.get("c.saveCaseTeamMember");
        console.log(component.get("v.caseTeamMembers"));
        console.log(component.get("v.accountRecord.Current_Case__c"));
      var data = JSON.stringify(JSON.parse(JSON.stringify(component.get("v.caseTeamMembers"))));
        console.log(data);
        action.setParams({
            "lstCTM": data,
            "parentId":component.get("v.accountRecord.Current_Case__c")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
 			var toastEvent = $A.get("e.force:showToast");            
            if(state === "SUCCESS"){
                console.log('success',response.getReturnValue());
               
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "The records have been updated/created successfully."
                });
                helper.loadData(component, event, helper);
                component.set("v.isModalOpen", false);
            }
            else{
                console.log(response.getError()[0].message);
                 toastEvent.setParams({
                     "type": "error",
                    "title": "Error!",
                    "message": response.getError()[0].message
                });
                console.log(response.getReturnValue());
            }
            toastEvent.fire();
                    

        });
        $A.enqueueAction(action);
    },
    addMember : function(component, event, helper){
       var action = component.get("c.getCaseTeamMemberInstance");
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('called,123');
            if(state === "SUCCESS"){
                var CTM = component.get("v.caseTeamMembers");
                CTM.push(response.getReturnValue());
                component.set("v.caseTeamMembers",CTM);
            }
        });
        $A.enqueueAction(action);
        component.set("v.isDataChanged", true);
    },
    removeMember : function(component, event, helper){
        //alert('removed');
        console.log('index name', event.getParam('sourceInstanceName'));
        console.log(event.getParam('selectedObj'));
        var CTM = component.get("v.caseTeamMembers");
        component.set("v.caseTeamMembers");
        var ctmToDelete = CTM[event.getParam('sourceInstanceName')];
        console.log('ctmToDelete', JSON.stringify(ctmToDelete));
        ctmToDelete.isDeleted = true;
        CTM[event.getParam('sourceInstanceName')] = ctmToDelete;
        console.log('CTM', CTM);
        component.set("v.caseTeamMembers", CTM);
         console.log('CTM After', CTM);
        component.set("v.isDataChanged", true);
       /* var action = component.get("c.deleteCaseTeamMemberInstance");
       action.setParams({
            "ctmId":CTM[event.getParam('sourceInstanceName')].Id
        });
        
        var toastEvent = $A.get("e.force:showToast");    
        action.setCallback(this, function(response){
            var state = response.getState();
             if(state === "SUCCESS"){
                console.log('success',response.getReturnValue());
               
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "The member has been removed!"
                });
                helper.loadData(component, event, helper);
               
            }
            else{
                console.log(response.getError()[0].message);
                 toastEvent.setParams({
                     "type": "error",
                    "title": "Error!",
                    "message": response.getError()[0].message
                });
                console.log(response.getReturnValue());
            }
            toastEvent.fire();
        });
       // $A.enqueueAction(action); */
    },
    handleCaseTeamRoleChanged : function(component, event, helper){
        console.log("handleCaseTeamRoleChanged:");
         component.set("v.isDataChanged", true);
    }
    
})
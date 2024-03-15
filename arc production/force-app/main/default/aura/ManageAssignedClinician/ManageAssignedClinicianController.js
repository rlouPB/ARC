({
	doInit : function(component, event, helper) {
		var recordId = component.get("v.recordId");
        var actionGetCTM = component.get("c.getCaseTeamMember");
        actionGetCTM.setParams({
            "accId":recordId
        });
        actionGetCTM.setCallback(this, function(response){
            var state = response.getState();
            console.log('called');
            if(state === "SUCCESS"){
                component.set("v.caseTeamMembers",response.getReturnValue())
                console.log(component.get("v.caseTeamMembers"));
            }
        });
		$A.enqueueAction(actionGetCTM);
        
        var actionGetCTMRole = component.get("c.getCaseTeamMemberRole");
       
        actionGetCTMRole.setCallback(this, function(response){
            var state = response.getState();
            console.log('called,123');
            if(state === "SUCCESS"){
                component.set("v.caseTeamMembersRoles",response.getReturnValue())
                console.log(component.get("v.caseTeamMembersRoles"));
            }
        });
		$A.enqueueAction(actionGetCTMRole);
	},
    
    removeMember : function(component, event, helper){
        
        var caseTeamMembers = component.get("v.caseTeamMembers");
        var params = event.getParams();
        var sourceInstanceName = params.sourceInstanceName;
        
        caseTeamMembers.splice(sourceInstanceName, 1);
        component.set("v.caseTeamMembers",caseTeamMembers);
        alert('removed');
    },
    
    addMember : function(component, event, helper){
        alert('selected');
        var caseTeamMembers = component.get("v.caseTeamMembers");
        var params = event.getParams();
        var sourceInstanceName = params.sourceInstanceName;
        var selectedObj = params.selectedObj;
        
        
        caseTeamMembers.push({});
        component.set("v.caseTeamMembers",caseTeamMembers);
        
        /*var action = component.get("c.getCaseTeamMemberInstance");
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('called,123');
            if(state === "SUCCESS"){
                var CTM = component.get("v.caseTeamMembers");
                CTM.push(response.getReturnValue());
                component.set("v.caseTeamMembers",CTM);
            }
        });
        $A.enqueueAction(action);*/
        
        
    }
})
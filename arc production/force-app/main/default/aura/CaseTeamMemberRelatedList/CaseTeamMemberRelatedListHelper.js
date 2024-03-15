({
	loadData : function(component, event, helper) {
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
	}
})
({
	setFilters: function(component, event, helper)
	{
        
		var psetAssignmentFilters = 
		[
			{
				'fieldName': 'Assignee.IsActive',
				'condition': '=',
				'value': true
			}
		];
		
		var userTypes = "'Standard'";
		if (userTypes && userTypes.length > 0)
		{
			//userTypes should be a single-quoted, comma-separated String
			var userTypeString = '(';
			userTypeString += userTypes;
			userTypeString += ')';
		
			psetAssignmentFilters.push(
			{
				'fieldName': 'Assignee.UserType',
				'condition': 'IN',
				'value': userTypeString
			});
		}

		//currently no profiles filtered 210519 JN
		var profileNames = '';
		if (profileNames && profileNames.length > 0)
		{
			//profileNames should be a single-quoted, comma-separated String
			var profileNameString = '(';
			profileNameString += profileNames;
			profileNameString += ')';

			psetAssignmentFilters.push(
			{
				'fieldName': 'Assignee.Profile.Name',
				'condition': 'IN',
				'value': profileNameString
			});
		}
		
		var permissionSetNames = component.get('v.permissionSetNames');
		if (permissionSetNames && permissionSetNames.length > 0)
        {
            //permissionSetNames should be a single-quoted, comma-separated String
            var permSetNameString = '(';
            permSetNameString += permissionSetNames;
            permSetNameString += ')';

            psetAssignmentFilters.push(
            {
                'fieldName': 'PermissionSet.Name',
                'condition': 'IN',
                'value': permSetNameString
            });
        }
		console.log('psetAssignmentFilters ' + JSON.parse(JSON.stringify(psetAssignmentFilters)));
		
		component.set('v.psetAssignmentFilters', psetAssignmentFilters);

	},
	
	loadData : function(component, event, helper,showValue) {
		var recordId = component.get("v.recordId");
		console.log("recordId: " + recordId);
		var action = component.get("c.getAssignedClinicians");
		action.setParams({
			"accountID":recordId,
			"showValue": showValue//"active"
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
            console.log("called getAssignedClinicians");
			if (state === "SUCCESS")
			{
				var listResponse = response.getReturnValue();
				console.log("listResponse: " + JSON.stringify(listResponse));
				listResponse.forEach(function(value){
					if (value.Id)
					{
						var object = {};
						object.isRecord = true;
						//object.label = value.User__r.Name;
						object.label = value.User__r.Professional_Name__c;
						object.value = value.User__r.Id;
						value.LookupObject = object;
					} else
					{
						var object = {};
						object.isRecord = false;
					}
				});

				component.set("v.assignedClinicians", listResponse);
                console.log(JSON.stringify(component.get("v.assignedClinicians")));
			} else
			{
				console.log("getAssignedClinicians failed");
			}
		});
		$A.enqueueAction(action);

		var rolesAction = component.get("c.getRoles");
		rolesAction.setCallback(this, function(rolesResponse)
		{
			var state = rolesResponse.getState();
			console.log("called getRoles");
			if (state == "SUCCESS") {
				component.set("v.clincianRoles", rolesResponse.getReturnValue());
                console.log("returned roles: " + JSON.stringify(component.get("v.clincianRoles")));
			} else
			{
				console.log("getRoles failed");
			}
		});
		$A.enqueueAction(rolesAction);

		var getAdmissionIDAction = component.get("c.getAdmissionID");
		getAdmissionIDAction.setParams({
			"accountID":recordId
		});
		getAdmissionIDAction.setCallback(this, function(admissionResponse)
		{
			var state = admissionResponse.getState();
			console.log("called getRoles");
			if (state == "SUCCESS") {
                console.log("returned Admission ID: " + admissionResponse.getReturnValue());
				component.set("v.admissionID", admissionResponse.getReturnValue());
			} else
			{
				console.log("getAdmissionID failed");
			}
			helper.hideSpinner(component, event, helper);
		});
		$A.enqueueAction(getAdmissionIDAction);
	},

	fireCloseModalEvent : function(component, event, helper)
	{
		let closeEvent = component.getEvent('closeModalEvent');
		closeEvent.setParam('data', 'manageClinicians');
		closeEvent.fire();
	},
	
    showSpinner : function(component, event, helper)
    {
        component.set("v.spinnerVisible", true);
	},
	
	hideSpinner : function(component, event, helper)
	{
		component.set("v.spinnerVisible", false)
	}
})
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
	
	loadData : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		console.log("recordId: " + recordId);
		var action = component.get("c.getLabObservations");
		action.setParams({
			"procedureOrderId":recordId
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
            console.log("called getLabObservations");
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
						object.label = value.Compendium_Entry__r.Test_Name__c;
						object.value = value.Compendium_Entry__r.Id;
                        object.category = value.Compendium_Entry__r.Category__c;
						value.LookupObject = object;
					} else
					{
						var object = {};
						object.isRecord = false;
					}
				});

				component.set("v.labObservations", listResponse);
                console.log(JSON.stringify(component.get("v.labObservations")));
                helper.hideSpinner(component, event, helper);
			} else
			{
				console.log("getLabObservations failed");
			}
		});
		$A.enqueueAction(action);
	},

	fireCloseModalEvent : function(component, event, helper)
	{
        debugger;
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
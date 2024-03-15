({
	doInit : function(component, event, helper) 
	{
		helper.showSpinner(component, event, helper);
		helper.setFilters(component, event, helper);
		helper.loadData(component, event, helper,'active');
	},

	closeManageCliniciansModal : function(component, event, helper)
	{
		helper.fireCloseModalEvent(component, event, helper);
	},
	
	closeManageCliniciansModalConfirm : function(component, event, helper)
	{
		if (component.get("v.isDataChanged"))
		{
			component.set("v.isModalOpenConfirmation", true);
		} else
		{
			helper.fireCloseModalEvent(component, event, helper);
		}
	},
	
	gobackToEditing : function(component, event, helper) 
	{
		component.set("v.isModalOpenConfirmation", false);
	},

	upsertCaseTeamMembers : function(component, event, helper)
	{
		helper.showSpinner(component, event, helper);
		var action = component.get("c.saveAssignedClinicians");
		var assignedClinicians = component.get("v.assignedClinicians");
		assignedClinicians.forEach(function(clinician)
		{
			if (clinician.User__c)
			{
				clinician.userID = clinician.User__c;
			} else if (clinician.LookupObject && clinician.LookupObject.value)
			{
				clinician.userID = clinician.LookupObject.value;
			}
			
			clinician.role = clinician.Role__c;
			clinician.startDate = clinician.Start_Date__c;
			clinician.endDate = clinician.End_Date__c;
		});
		console.log('assignedClinicians: ' + JSON.stringify(assignedClinicians));

		var data = JSON.stringify(JSON.parse(JSON.stringify(assignedClinicians)));
		console.log('data: ' + data);
		action.setParams(
		{
			"input" : data,
			"admissionID" : component.get("v.admissionID"),
			"patientID" : component.get("v.recordId")
		});
		console.log("action params: " + JSON.stringify(action.getParams()));
		action.setCallback(this, function(response)
		{
			var state = response.getState();
			var toastEvent = $A.get("e.force:showToast");
			if(state === "SUCCESS")
			{
				console.log('success',response.getReturnValue());
				toastEvent.setParams(
				{
					"type": "success",
					"title": "Success!",
					"message": "The records have been updated/created successfully."
				});
				//component.set("v.isDataChanged", false);
				//helper.loadData(component, event, helper);
				helper.fireCloseModalEvent(component, event, helper);
			} else
			{
				console.log(response.getError()[0].message);
				toastEvent.setParams(
				{
					"type": "error",
					"title": "Error!",
					"message": response.getError()[0].message
				});
				console.log(response.getReturnValue());
			}
			toastEvent.fire();
			helper.hideSpinner(component, event, helper);
		});
		$A.enqueueAction(action);
	},

	addMember : function(component, event, helper)
	{
		var action = component.get("c.getAssignedClinicianInstance");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var clinicians = component.get("v.assignedClinicians");
                clinicians.push(response.getReturnValue());
                component.set("v.assignedClinicians", clinicians);
            }
        });
		$A.enqueueAction(action);
		
        component.set("v.isDataChanged", true);
	},

	removeMember : function(component, event, helper)
	{
		console.log('index name: ', event.getParam('sourceInstanceName'));
        console.log(event.getParam('selectedObj'));
        var clinicians = component.get("v.assignedClinicians");
        component.set("v.assignedClinicians");
        var clinicianToDelete = clinicians[event.getParam('sourceInstanceName')];
        console.log('clinicianToDelete', JSON.stringify(clinicianToDelete));
        clinicianToDelete.isDeleted = true;
        clinicians[event.getParam('sourceInstanceName')] = clinicianToDelete;
        console.log('clinicians: ', clinicians);
        component.set("v.assignedClinicians", clinicians);
		console.log('clinicians After: ', clinicians);
		
        component.set("v.isDataChanged", true);
	},


	reloadData : function(component, event, helper)
	{
		var showValue = component.get("v.radioValue");
		helper.loadData(component, event, helper,showValue);
	},
})
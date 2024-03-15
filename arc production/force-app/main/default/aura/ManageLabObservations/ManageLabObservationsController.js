({
	doInit : function(component, event, helper) 
	{
		helper.showSpinner(component, event, helper);
		//helper.setFilters(component, event, helper);
		helper.loadData(component, event, helper);
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

	upsertLabObservations : function(component, event, helper)
	{
		debugger;
		helper.showSpinner(component, event, helper);
		var action = component.get("c.saveLabObservations");
		var labObservations = component.get("v.labObservations");
		labObservations.forEach(function(lab)
		{
            if (lab.LookupObject && lab.LookupObject.value)
			{
				lab.compendiumEntryId = lab.LookupObject.value;
			} else {
                lab.compendiumEntryId = lab.Compendium_Entry__c;
            }
			lab.startDate = lab.Start_Date__c;
			lab.endDate = lab.End_Date__c;
			lab.queryAnswer = lab.Query_Answer__c;
		});
		console.log('labObservations: ' + JSON.stringify(labObservations));

		var data = JSON.stringify(JSON.parse(JSON.stringify(labObservations)));
		console.log('data: ' + data);
		action.setParams(
		{
			"input" : data,
			"procedureOrderId" : component.get("v.recordId")
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
				component.set("v.isDataChanged", false);
				helper.loadData(component, event, helper);
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
		var poId = component.get("v.recordId");
		var selectedObj= event.getParam("selectedObj");
		var sourceInstanceName = event.getParam("sourceInstanceName");
		var action = component.get("c.getLabObservationInstance");
		
		action.setParams(
			{
				"selectedEntryId" : selectedObj.value,
				"poId" : poId
			});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
				var newObj = response.getReturnValue();
                var labs = component.get("v.labObservations");
				var result = labs.find(function(item) {
					if(item.LookupObject) {
						return item.LookupObject.value == newObj.Compendium_Entry__c;
					} else {
						return false;
					}
					
				});
				Object.assign(result, response.getReturnValue())
				labs.push({isRecord:false})
				
                //labs.push(response.getReturnValue());
                component.set("v.labObservations", labs);
            }
        });
		$A.enqueueAction(action);
		
        component.set("v.isDataChanged", true);
	},

	removeMember : function(component, event, helper)
	{
		console.log('index name: ', event.getParam('sourceInstanceName'));
        console.log(event.getParam('selectedObj'));
        var labObservations = component.get("v.labObservations");
        component.set("v.labObservations");
        var labObservationToDelete = labObservations[event.getParam('sourceInstanceName')];
        console.log('labObservationToDelete', JSON.stringify(labObservationToDelete));
        labObservationToDelete.isDeleted = true;
        labObservations[event.getParam('sourceInstanceName')] = labObservationToDelete;
        console.log('clinicians: ', labObservations);
        component.set("v.labObservations", labObservations);
		console.log('clinicians After: ', labObservations);
		
        component.set("v.isDataChanged", true);
	}
})
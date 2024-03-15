({
	autosaveOn : function(component, event, helper)
	{
		console.log("autosaveOn for instance: " + component.get("v.instanceName"));
		helper.startAutosaving(component, event, helper);
	},
	
	autosaveOff : function(component, event, helper)
	{
		console.log("autosaveOff for instance: " + component.get("v.instanceName"));
		helper.stopAutosaving(component, event, helper);
	},
	
	autosaveChange : function(component, event, helper)
	{
		console.log("autosaveChange for instance: " + component.get("v.instanceName"));
		if (component.get("v.isAutosaveOn") == "false")
		{
			helper.startAutosaving(component, event, helper);
		} else
		{
			helper.stopAutosaving(component, event, helper);
		}
	},
	
	reset : function(component, event, helper)
	{
		console.log("reset for instance: " + component.get("v.instanceName"));
		helper.stopAutosaving(component, event, helper);
		helper.startAutosaving(component, event, helper);
	}
})
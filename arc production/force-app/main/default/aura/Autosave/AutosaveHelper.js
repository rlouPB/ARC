({
	fireAutosaveNowEvent : function(component, event, helper)
	{
		console.log("fireAutosaveNowEvent for instance: " + component.get("v.instanceName"));
        let lastSuccessfulSaveTime = component.get('v.lastSuccessfulSaveTime');
		let previousSaveLockoutLength = component.get('v.previousSaveLockoutLength');
		
		let timeSinceLastSave = (lastSuccessfulSaveTime) ? lastSuccessfulSaveTime.diff()/1000*(-1) : null;
        //if (component.get('v.loading') || component.get('v.isAutosaving'))
        if ( timeSinceLastSave && timeSinceLastSave < previousSaveLockoutLength)
        {
            console.log('save already in progress. Draft save aborted. Last save: ' + moment(lastSuccessfulSaveTime) + ' (' + timeSinceLastSave + ' seconds ago)');
            return;
		}
		
		component.set("v.autosaveMessage", "Autosaving...");
		var asEvent = component.getEvent("autosaveNowEvent");
		asEvent.setParams
		({
			"instanceName" : component.get("v.instanceName")
		});
		asEvent.fire();

		helper.stopAutosaving(component, event, helper);
	},

	startAutosaving : function(component, event, helper)
	{
		console.log("startAutosaving for instance: " + component.get("v.instanceName"));
		if (!component.get("v.timeoutId"))
        {
            console.log("autosaving for instance " + component.get("v.instanceName"));
            component.set("v.timeoutId", 
                window.setInterval(
                    $A.getCallback(function() {
                        helper.fireAutosaveNowEvent(component, event, helper)
					}), 1000 * component.get("v.saveFrequency")));
			component.set("v.autosaveMessage", "");
        }
	},

	stopAutosaving : function(component, event, helper)
	{
		console.log("stopAutosaving for instance: " + component.get("v.instanceName"));
		let timeStamp = moment();
		component.set('v.lastSuccessfulSaveTime', timeStamp);
		window.clearInterval(component.get("v.timeoutId"));
		component.set("v.timeoutId", "");
		//component.set("v.autosaveMessage", "Saved!");
		component.set("v.autosaveMessage", "");
	}
})
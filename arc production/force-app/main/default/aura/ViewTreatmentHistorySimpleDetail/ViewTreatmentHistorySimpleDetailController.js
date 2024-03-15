({
    handleRecordUpdated: function(component, event, helper) 
    {
        var eventParams = event.getParams();
        console.log('event fired ' + JSON.stringify(event.getParams()));
        if(eventParams.changeType === "LOADED") {
            component.set("v.isRecordLoaded",true);
        } else //if (eventParams.changeType === 'CHANGED') {
        {
        	//reload when updated
        	component.find('recordLoader').reloadRecord(true);
        }
    },
})
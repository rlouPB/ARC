({
	handleRecordUpdated : function(component, event, helper) {
		var eventParams = event.getParams();
        console.log('event fired ' + JSON.stringify(event.getParams()));
        if(eventParams.changeType === "LOADED") {
            component.set("v.isRecordLoaded", true);
            console.log('header loaded');
            // window.setTimeout($A.getCallback(function() {
            //     helper.toggleSpinner(component, 0);  
            // }),1000);
        } else {
        	//reload when any of these three records is updated
        	component.find('contactRecordLoader').reloadRecord(true);
        	// helper.toggleSpinner(component, 0);
        }
	}
})
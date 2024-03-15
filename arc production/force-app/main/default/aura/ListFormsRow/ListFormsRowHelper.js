({
	refreshList : function(component, event, helper)
	{
		// console.log("Starting ListFormsRow helper.refreshList -------------------------------------------");
		var index;
		var fieldList = component.get("v.fieldList");
		var formRecord = component.get("v.formRecord");
		// console.log("formRecord: " + formRecord);

		var valueList = [];
		for (index in fieldList)
		{
			var apiName = fieldList[index];
			// console.log("api: " + apiName);
			var value = formRecord[apiName];
			// console.log("value: " + value);

			var object = {};

			if (fieldList[index].includes("Date"))
			{
				if (value.includes(".000Z"))
				{
					object.value = value.substring(5, 7) + "/" + value.substring(8, 10) + "/" + value.substring(0, 4);
				} else
				{
					object.value = value;
				}
				object.size = 3;
			} else if (fieldList[index].includes("disco__Form_Template_Name__c"))
			{
				object.value = value;
				object.size = 12;
			} else
			{
				object.value = value;
				object.size = 4;
			}
			valueList.push(object);
			if (fieldList[index].includes("disco__Form_Template_Name__c"))
			{
				var blankSpaceObject = {};
				blankSpaceObject.value = "";
				blankSpaceObject.size = 3;
				valueList.push(blankSpaceObject);
			}
		}
		// console.log("valueList: " + valueList);
		component.set("v.valueList", valueList);
		// console.log("Ending ListFormsRow helper.refreshList -------------------------------------------");
	},

	// subscribe : function(component, event, helper)
	// {
	// 	console.log("Starting ListFormsRow helper.subscribe -------------------------------------------");
	// 	// Get the empApi component.
    //     const empApi = component.find('empApi');
    //     console.log("empApi: " + empApi);
    //     // Get the channel from the attribute.
    //     const channel = component.get('v.channel');
    //     // Subscription option to get only new events.
    //     const replayId = -1;
    //     // Callback function to be passed in the subscribe call.
    //     // After an event is received, this callback prints the event
    //     // payload to the console. A helper method displays the message
    //     // in the console app.
    //     const callback = function (message) {
    //         console.log('Event Received : ' + JSON.stringify(message));
    //         // helper.onReceiveNotification(component, message);
    //     };
    //     // Subscribe to the channel and save the returned subscription object.
    //     empApi.subscribe(channel, replayId, $A.getCallback(callback)).then($A.getCallback(function (newSubscription) {
    //         console.log('Subscribed to channel ' + channel);
    //         component.set('v.subscription', newSubscription);
    //     }));



	// 	// const empApi = component.find('empApi');
	// 	// console.log("empApi: " + empApi);
	// 	// const channel = "/data/Patient_Note__ChangeEvent";
	// 	// const replayId = -1;

	// 	// const eventReceivedCallback = function (message) {
    //     //     console.log('Event Received : ' + JSON.stringify(message));
    //     //     component.find("formRecordData").reloadRecord(true);
	// 	// };

	// 	// const subscribedCallback = function (newSubscription) {
    //     //     console.log('Subscribed to channel ' + channel);
    //     //     component.set('v.subscription', newSubscription);
	// 	// };
		
	// 	// empApi.subscribe(channel, replayId, $A.getCallback(eventReceivedCallback))
	// 	// .then($A.getCallback(subscribedCallback))
	// 	// .catch(error => {
	// 	// 	console.log("error: " + error);
	// 	// });

	// 	// empApi.onError($A.getCallback(error => {
    //     //     // Error can be any type of error (subscribe, unsubscribe...)
    //     //     console.error("EMP API error: ", error);
	// 	// }));
		
	// 	// empApi.setDebugFlag(true);
		
	// 	// empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
    //     //     // Process event (this is called each time we receive an event)
	// 	// 	console.log("Received event ", JSON.stringify(eventReceived));
	// 	// 	component.find("formRecordData").reloadRecord(true);
    //     // }))
    //     // .then(subscription => {
    //     //     // Confirm that we have subscribed to the event channel.
    //     //     // We haven't received an event yet.
    //     //     console.log("Subscribed to channel ", subscription.channel);
    //     //     // Save subscription to unsubscribe later
    //     //     component.set("v.subscription", subscription);
	// 	// })
	// 	// .catch(error => {
	// 	// 	console.log("error: " + error);
	// 	// });
		
	// 	console.log("Ending ListFormsRow helper.subscribe -------------------------------------------");
	// }
})
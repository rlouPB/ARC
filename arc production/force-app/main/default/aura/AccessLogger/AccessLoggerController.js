({
	init : function(cmp, event, helper) {

		var action = cmp.get("c.log");

        action.setParams({
        	"source" 	: cmp.get('v.context'), 
            "recordId" 	: cmp.get("v.recordId")
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();

            if(state === "SUCCESS"){
            	console.log('Logged Successfully.')
            } 
    	});

        $A.enqueueAction(action);

	}
})
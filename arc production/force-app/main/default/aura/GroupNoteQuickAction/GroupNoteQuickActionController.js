({
	init : function(component, event, helper) {
	    var recordId = component.get("v.recordId");
        console.log('record id',recordId);
       	var navService = component.find("navService");
        var pageReference = {
            
            "type": "standard__component",
            "attributes": {
               "componentName": "c__GroupNote"    
            },    
            "state": { 
                 "recordId": recordId
            }
        };
        
        component.set("v.pageReference",pageReference);
        
        console.log('pd',JSON.stringify(component.get("v.pageReference")));
        //navService.navigate(component.get("v.pageReference"));  
    }
        
   
})
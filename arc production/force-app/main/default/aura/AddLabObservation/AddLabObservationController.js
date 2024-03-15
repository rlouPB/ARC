({
    onInit : function( component, event, helper ) {    
        console.log(component.get( "v.recordId" ));    
        
    },
    onSelectedCompendiumEntryChanged : function( component, event, helper ) {    
        console.log(component.get( "v.recordId" ));    
        let selectedEntry = component.get('v.selectedCompendiumEntry');   
        var action = component.get("c.getCategory");
        // var paramObj = {
        //     "poId" : component.get( "v.recordId" ),
        //     "selectedEntry" : selectedEntry.value
        // }
        action.setParams({ entryId : selectedEntry.value});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                //console.log('object',response.getReturnValue());
                let category = response.getReturnValue();
               
                component.set('v.category', category);
            }
        });
        $A.enqueueAction(action); 
    },
    saveLabObservation : function( component, event, helper ) {    
        event.stopPropagation();
        console.log(component.get( "v.recordId" ));  
        var poId = component.get( "v.recordId" );
        let selectedEntry = component.get('v.selectedCompendiumEntry');   
        var action = component.get("c.addLabObservation");
        
        action.setParams({ poId : poId, selectedEntryId : selectedEntry.value});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action); 
    }
})
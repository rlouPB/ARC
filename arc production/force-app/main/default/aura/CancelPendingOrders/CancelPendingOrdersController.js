({
    onInit : function( component, event, helper ) {    
        component.set('v.columns', [
            {label: 'Activation Date', fieldName: 'Date__c', type: 'date'},
            {label: 'Due Date', fieldName: 'Due_Date__c', type: 'date'},
            {label: 'Procedure Type', fieldName: 'Procedure_Type__c', type: 'text'}
        ]);

        let action = component.get( "c.getPendingOrders" );  
        action.setParams({  
            orderId: component.get( "v.recordId" )
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();  
            if ( state === "SUCCESS" ) {  
                component.set('v.data', response.getReturnValue());
                
            }  else {
                
                let showToast = $A.get( "e.force:showToast" );
                showToast.setParams({
                    title : 'Testing Toast!!!',
                    message : 'Record Not Saved due to error.' ,
                    type : 'error',
                    mode : 'sticky',
                    message : 'Some error occured'
                });
                showToast.fire();
                
            }
        });  
        $A.enqueueAction( action );         
    },
    confirmPendingOrdersCancellation: function( component, event, helper ) {  
        component.set("v.isModalOpenConfirmation", true);
    },
    closeConfirmPendingOrdersCancellation: function( component, event, helper ) {  
        component.set("v.isModalOpenConfirmation", false);
    },
    cancelPendingOrders: function( component, event, helper ) {  
        debugger;
        component.set("v.isModalOpenConfirmation", false);
        //let data = JSON.stringify(component.get( "v.data" ));
        var selectedOrders = component.find("pendingOrders");
		var listOfOrders = selectedOrders.getSelectedRows();
        
        if(listOfOrders && listOfOrders.length !=0) {
            let cancelAction = component.get( "c.cancelOrders" );  
            cancelAction.setParams({  
                procedureResults: JSON.stringify(listOfOrders)
            });  
            cancelAction.setCallback(this, function(response) {  
                let state = response.getState();  
                
                if ( state === "SUCCESS" ) {  
                    let count = response.getReturnValue();
                    let showToast = $A.get( "e.force:showToast" );
                    showToast.setParams({
                        title : 'Pending Orders Cancelled',
                        message : count + ' pending orders have been cancelled.' ,
                    });
                    showToast.fire();
                    $A.get("e.force:closeQuickAction").fire();  
                    $A.get('e.force:refreshView').fire();  
                }  else { 
                    let showToast = $A.get( "e.force:showToast" );
                    showToast.setParams({
                        title : 'Testing Toast!!!',
                        message : 'Record Not Saved due to error.' ,
                        type : 'error',
                        mode : 'sticky',
                        message : 'Some error occured'
                    });
                    showToast.fire();
                    
                }
            });  
            $A.enqueueAction( cancelAction );     
            
        } 
    },
    closeQuickAction: function( component, event, helper ) {  
        $A.get("e.force:closeQuickAction").fire();  
        $A.get('e.force:refreshView').fire();  
    }
})
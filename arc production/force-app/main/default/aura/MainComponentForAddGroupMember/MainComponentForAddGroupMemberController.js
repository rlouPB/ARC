({
	createModal : function(component, event, helper) {
		var modalBody;
        var selectedUser = component.get("v.selectedUser");
        $A.createComponents([
            ['c:AddGroupMemberNew',{"selectedUser": selectedUser,"group":component.get("v.group"),"aura:id": "newGMId"}],
            
                ["lightning:button",
                {
                    "aura:id": "AddButton",
                    "variant":"brand",
                    "label": "Save",
                    onclick : component.getReference("c.add")
                }],
                ["lightning:button",
                {
                    "aura:id": "CloseButton",
                    "label": "Close",
                     onclick : component.getReference("c.Close")
                                  
                }]
            ],
            
         function(cmp, status){
                         
             if (status === 'SUCCESS') {
                 modalBody = cmp[0];
                 
                
                 component.find("overlayLib").showCustomModal({
                     header: 'Add Group Member to ' + component.get("v.group").Name,
                     body: modalBody,
                     footer: [cmp[1],cmp[2]],
                     showCloseButton: true,
                     cssClass: 'my-modal my-custom-class my-other-class slds-modal_medium',
                     closeCallback: function() {
                     }
                 });
             }
         });
	},
    
    Close : function(component, event, helper){
        
        var appEvent = $A.get("e.c:AddNewGroupButtonEvent");
        appEvent.setParams({
            "buttonClicked" : "Close"
            });
         appEvent.fire();
        console.log('close Main');
        
    },
    add : function(component, event, helper){
         
        var appEvent = $A.get("e.c:AddNewGroupButtonEvent");
        appEvent.setParams({
            "buttonClicked" : "add"
            });
         appEvent.fire(); 
         console.log('add Main');
    }
})
({
	
    EditDatesPatient : function(component, id_str, helper){
        //  var ctarget = event.currentTarget;
        //     var id_str = event.getParam('row').Id;
           
        var patinentObject;
        var patientRecords = component.get("v.patientGroupMembers");
        for(var i = 0; i< patientRecords.length; i++){
            if(patientRecords[i].Id == id_str){
                patinentObject = patientRecords[i];
            }
        }
        component.set("v.patientObject",patinentObject);
        console.log('obj');
        console.log('123',component.get("v.patientObject"));
        var modalBody;
        var selectedUser = "Patient";
        $A.createComponents([
            ['c:AddGroupMemberNew',{"selectedUser": selectedUser,"passedRecordId": component.get("v.patientObject").Id,"group":component.get("v.group"),"EditType":"Dates","aura:id": "newGMId"}],
            
                ["lightning:button",
                {
                    "aura:id": "AddButton",
                    "variant":"brand",
                    "label": "Save",
                    onclick : component.getReference("c.add")
                }]
                ,
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
                 
                
                 component.find("overlayLib2").showCustomModal({
                     header: "Edit Dates",
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
    changeRolePatient : function(component, id_str, helper){
    //    var ctarget = event.currentTarget;
    //         var id_str = event.getParam('row').Id;
            console.log(id_str);
        var patinentObject;
        var patientRecords = component.get("v.patientGroupMembers");
        for(var i = 0; i< patientRecords.length; i++){
            if(patientRecords[i].Id == id_str){
                patinentObject = patientRecords[i];
            }
        }
        component.set("v.patientObject",patinentObject);
        console.log('obj');
        console.log('123',component.get("v.patientObject"));
        var modalBody;
        var selectedUser = "Patient";
        $A.createComponents([
            ['c:AddGroupMemberNew',{"selectedUser": selectedUser,"passedRecordId": component.get("v.patientObject").Id,"group":component.get("v.group"),"EditType":"Role","aura:id": "newGMId"}],
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
                                  
                }],
                
            ],
            
         function(cmp, status){
                         
             if (status === 'SUCCESS') {
                 modalBody = cmp[0];
                 
                
                 component.find("overlayLib2").showCustomModal({
                     header: "Change Role",
                     body: modalBody,
                     footer: [cmp[1],cmp[2]],
                     showCloseButton: true,
                     cssClass: 'my-modal my-custom-class my-other-class slds-modal_large',
                     closeCallback: function() {
                     }
                 });
             }
         });
    },
    changeRoleStaff : function(component, id_str, helper){
        // var ctarget = event.currentTarget;
        // var id_str = event.getParam('row').Id;
        // console.log(id_str);
        var staffObject;
        var staffRecords = component.get("v.staffGroupMembers");
        for(var i = 0; i< staffRecords.length; i++){
            if(staffRecords[i].Id == id_str){
                staffObject = staffRecords[i];
            }
        }
        component.set("v.staffObject",staffObject);
        console.log('obj');
        console.log('123',component.get("v.staffObject"));
        var modalBody;
        var selectedUser = "Staff";
        $A.createComponents([
            ['c:AddGroupMemberNew',{"selectedUser": selectedUser,"passedRecordId": component.get("v.staffObject").Id,"group":component.get("v.group"),"EditType":"Role","aura:id": "newGMId"}],
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
                 
                
                 component.find("overlayLib2").showCustomModal({
                     header: "Change Role",
                     body: modalBody,
                     footer: [cmp[1],cmp[2]],
                     showCloseButton: true,
                     cssClass: 'my-modal my-custom-class my-other-class slds-modal_large',
                     closeCallback: function() {
                     }
                 });
             }
         });
        
    },
    // EditDatesStaff : function(component, event, helper){
    EditDatesStaff : function(component, id_str, helper){
        // var ctarget = event.currentTarget;
        // var id_str = event.getParam('row').Id;
        console.log(id_str);
        var staffObject;
        var staffRecords = component.get("v.staffGroupMembers");
        for(var i = 0; i< staffRecords.length; i++){
            if(staffRecords[i].Id == id_str){
                staffObject = staffRecords[i];
            }
        }
        component.set("v.staffObject",staffObject);
        console.log('obj');
        console.log('123',component.get("v.staffObject"));
        var modalBody;
        var selectedUser = "Staff";
        $A.createComponents([
            ['c:AddGroupMemberNew',{"selectedUser": selectedUser,"passedRecordId": component.get("v.staffObject").Id,"group":component.get("v.group"),"EditType":"Dates","aura:id": "newGMId"}],
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
                 
                
                 component.find("overlayLib2").showCustomModal({
                     header: "Edit Dates",
                     body: modalBody,
                     footer: [cmp[1],cmp[2]],
                     showCloseButton: true,
                     cssClass: 'my-modal my-custom-class my-other-class slds-modal_medium',
                     closeCallback: function() {
                     }
                 });
             }
         });
        
    }
})
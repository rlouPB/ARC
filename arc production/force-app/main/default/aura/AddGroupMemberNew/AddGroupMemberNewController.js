({
	init : function(component, event, helper) {
        let group = JSON.parse(JSON.stringify(component.get('v.group')))
        console.log('**** group ---> ', group.Type__c);
         window.addEventListener("keydown", function(event) {
            var kcode = event.code;
            if(kcode == 'Escape'){
                console.log('esccape id press - Outer Component');
                event.preventDefault();
                event.stopImmediatePropagation();
            }
        }, true);
		var actionStaff = component.get("c.getRoles");
		actionStaff.setParam("roleType","Staff");
        
         var today = $A.localizationService.formatDate(new Date(), "MM/DD/YYYY");
        var result = new Date();
        result.setDate(result.getDate()+1);
        var tomorrow = $A.localizationService.formatDate(result, "MM/DD/YYYY");
       
        
        
        component.set("v.staffObject.Start_Date__c",today);
        component.set("v.patientObject.Start_Date__c",today);

        var recordEditId = component.get("v.passedRecordId");
        if(recordEditId){
            if(component.get("v.selectedUser") == "Patient"){
                var getPatientObject = component.get("c.getPatientGroupMember");
                getPatientObject.setParams({
                    "patientId":recordEditId
                });
                getPatientObject.setCallback(this, function(resp){
                    var state = resp.getState();
                    if(state === "SUCCESS"){
                        component.set("v.memberName",resp.getReturnValue().Patient__r.Name);
                        if(component.get("v.EditType") != "Role"){
                            component.set("v.patientObject", resp.getReturnValue());
                            
                            component.find("patientRole").set("v.value",resp.getReturnValue().Role__c);
                        }
                        
                        if(component.get("v.EditType") == "Dates"){
                            component.find("patientRole").set("v.disabled",true);
                        }
                       if(component.get("v.EditType") == "Role"){
                           component.set("v.patientObjectOld", resp.getReturnValue());
                           component.find("patientRoleOld").set("v.value",resp.getReturnValue().Role__c);
                           component.set("v.patientObject.Start_Date__c",tomorrow);
                           component.find("endDateOld").set("v.value",today);
                           
                        }
						
						
                        

                        var objMap = {};
                        objMap["value"] = resp.getReturnValue().Patient__c;
                        objMap["label"] = resp.getReturnValue().Patient__r.Name;
                        
                             objMap["isRecord"] = true;
                        
                       
                        component.set("v.selectedRecord", objMap);
                        if(component.get("v.EditType") == ""){
                        var childCmp = component.find("patientLookup");
                         
                        var retnMsg = childCmp.setSelectedRecord(component.get("v.selectedRecord"));
                         }
                       
                       
                    }
                });
                $A.enqueueAction(getPatientObject);
                
            }
            if(component.get("v.selectedUser") == "Staff"){
                var getStaffObject = component.get("c.getStaffGroupMember");
                getStaffObject.setParams({
                    "staffId":recordEditId
                });
                getStaffObject.setCallback(this, function(resp){
                    var state = resp.getState();
                    if(state === "SUCCESS"){
                        component.set("v.staffObjectOld", resp.getReturnValue());
                       
                        component.set("v.memberName",resp.getReturnValue().Staff_Member__r.Name);
                        if(component.get("v.EditType") != "Role"){
                            component.set("v.staffObject", resp.getReturnValue());
                           
                            component.find("staffRole").set("v.value",resp.getReturnValue().Role__c);
                        }
                        if(component.get("v.EditType") == "Dates"){
                            component.find("staffRole").set("v.disabled",true);
                          
                        }
                        if(component.get("v.EditType") == "Role"){
                           component.set("v.staffObjectOld", resp.getReturnValue());
                           component.find("staffRoleOld").set("v.value",resp.getReturnValue().Role__c);
                           component.set("v.staffObject.Start_Date__c",tomorrow);
                           component.set("v.staffObjectOld.Planned_End_Date__c",today);
                        }
                        
                        var objMap = {};
                        objMap["value"] = resp.getReturnValue().Staff_Member__c;
                        objMap["label"] = resp.getReturnValue().Staff_Member__r.Name;
                        objMap["isRecord"] = true;
                        component.set("v.selectedRecord", objMap);
                         if(component.get("v.EditType") == ""){
                            var childCmp = component.find("staffLookup");
                            var retnMsg = childCmp.setSelectedRecord(component.get("v.selectedRecord"));
                        }
                        
                    }
                });
                $A.enqueueAction(getStaffObject);
                
            }
        }
        actionStaff.setCallback(this, function(response){
            console.log('----,',response.getReturnValue());
            component.set("v.RolesStaff",response.getReturnValue() );
        });
        $A.enqueueAction(actionStaff);
                                               
		console.log("v.group: " + JSON.stringify(component.get("v.group")));
		var actionPatient = component.get("c.getRoles");
		actionPatient.setParam("roleType","Patient");
		actionPatient.setParam("groupID",component.get("v.group").Id);
        actionPatient.setCallback(this, function(response){
			var returnRoles = response.getReturnValue();
			var returnRolesOld = [...returnRoles];
			if (component.get("v.patientObjectOld.Role__c") != null) {
				returnRolesOld.push(component.get("v.patientObjectOld.Role__c"));
			}
			if (component.get("v.patientObject.Role__c") != null) {
				returnRolesOld.push(component.get("v.patientObject.Role__c"));
			}
            console.log('----,',returnRoles);
            component.set("v.Rolespatient",returnRoles);
            component.set("v.RolespatientOld",returnRolesOld);
        });
        $A.enqueueAction(actionPatient);
        
        helper.setFilters(component);

        
       
	},
    
    addGroupMember : function(component, event, helper) {
        var addGroupMember = component.get("v.newGroupMember");
        var action = component.get("c.saveGroupMember")
        //var addContact = component.get("v.newAccount");
		
		//var add = component.find('add');
        //add.submit();
    	
	},
    handleButtonClickedFromMainComponent : function(component, event, helper){

        let selectedRecord = JSON.parse(JSON.stringify(component.get('v.selectedRecord')));

        console.log('******* selectedRecord ----> ', selectedRecord);
        
        console.log('clicked handled');
        var groupId = component.get("v.group.Id");
        
        var buttonName = event.getParam("buttonClicked");
        if(buttonName == 'Close'){
             component.find("overlayLib").notifyClose();
        }
        if(buttonName == 'add')
        {
            
            if (!selectedRecord || !selectedRecord.isRecord)
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please select the new member's name from the picklist",
                    "duration" : 2000,
                    "type": "error"
                });
                toastEvent.fire();
                return;
            }

           var userType = component.get("v.selectedUser");
            if(userType == "Staff"){
                var action = component.get("c.saveStaffGroupMember");
                console.log('staffMemberobject',component.get("v.staffObject"));
                component.set("v.staffObject.Group_Name__c", groupId);
                component.set("v.staffObjectOld.Group_Name__c", groupId);
                
                action.setParams({
                    "sgm" : component.get("v.staffObject"),
                    "EditType" : component.get("v.EditType"),
                    "Oldsgm" : component.get("v.staffObjectOld")
                });
                
                action.setCallback(this, function(response){
                    var state = response.getState();
                     console.log('test',response.getReturnValue());
                    if(state === "SUCCESS"){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "The record has been created successfully.",
                            "duration" : 2000
                        });
                        toastEvent.fire();
                       
                        var refEvent = $A.get("e.c:refreshPatient");
						refEvent.fire();
                       
                        if(component.get("v.EditType") != "Role" && component.get("v.EditType") != "Dates"){
                        var childCmp = component.find("staffLookup");
            			var retnMsg = childCmp.closePill();
                        }
                       if(component.get("v.EditType") == "Role" || component.get("v.EditType") == "Dates"){
                           
                             component.find("overlayLib").notifyClose();
                        }
                        component.set("v.staffObject.Planned_End_Date__c", '');
                    }
                    else{
                       var errors = response.getError();
                         console.log('123',errors)
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": errors[0].pageErrors[0].message,
                            "duration" : 2000
                        });
                        toastEvent.fire();
                    }
            	});
                $A.enqueueAction(action);
            }
            if(userType == "Patient"){
            	var action = component.get("c.saveGroupMember");
                console.log('test',JSON.stringify(component.get("v.patientObject")));
                component.set("v.patientObject.Group_Name__c", groupId);
                console.log('component.get("v.patientObjectOld")', component.get("v.patientObjectOld"));
				console.log('component.get("v.patientObject")', component.get("v.patientObject"));

				var editType = component.get("v.EditType");
				
				if (editType != null && editType != "Role" && (component.get("v.patientObject").Patient__c == null || !component.get("v.patientObject").Patient__c.startsWith("003"))) {
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						"title": "Patient not found.",
						"message": "No record was created. Please select a patient from the search field.",
						"duration" : 2000
					});
					toastEvent.fire();
				} else {

					action.setParams({
						"pgm" : component.get("v.patientObject"),
						"EditType" : component.get("v.EditType"),
						"Oldpgm" : component.get("v.patientObjectOld")
					});
					
					action.setCallback(this, function(response){
						
						var state = response.getState();
						console.log('state'+state);
						var toastEvent = $A.get("e.force:showToast");
						if(state === "SUCCESS"){
							console.log(response.getReturnValue());
						
							toastEvent.setParams({
								"title": "Success!",
								"message": "The record has been created successfully.",
								"duration" : 2000
							});
							toastEvent.fire();
							var refEvent = $A.get("e.c:refreshPatient");
							refEvent.fire();
							if(component.get("v.EditType") != "Role" && component.get("v.EditType") != "Dates"){
						
							var childCmp = component.find("patientLookup");
							var retnMsg = childCmp.closePill();
							}
							if(component.get("v.EditType") == "Role" || component.get("v.EditType") == "Dates"){
							
								component.find("overlayLib").notifyClose();
							}
							component.set("v.patientObject.Planned_End_Date__c", '');
						}
						else{
							var errors = response.getError();
							console.log(errors)
							toastEvent.setParams({
								"title": "Error!",
								"message": errors[0].pageErrors[0].message,
								"duration" : 2000
							});
							toastEvent.fire(); 
						}
					});
					$A.enqueueAction(action);
				}
            }
           
                
            
            
        }
    },
    clearPill : function(component, event, helper){
         var patientCmp = component.find("patientLookup");
         
         var staffCmp = component.find("staffLookup");
        if(staffCmp)
        {
            if(staffCmp != 'undefined'){
                var retnMsg = staffCmp.closePill();
            }
        }
        
         if(patientCmp)
        {
            if(patientCmp != 'undefined'){
                var retnMsg = patientCmp.closePill();
            }
        }
        
         
    },
    showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
   },
    
 // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
      component.set("v.Spinner", false);
    }
    
})
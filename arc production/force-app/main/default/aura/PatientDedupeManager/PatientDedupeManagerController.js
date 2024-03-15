({
	doInit : function(component, event, helper) {
		helper.isDuplicateRecordsExistHelper(component, helper);
	},
    handleRecordUpdated : function(component, event, helper)
    {
        var eventParams = event.getParams();
        console.log('event fired ' + JSON.stringify(event.getParams()));
        if(eventParams.changeType === "LOADED") {
            //component.set("v.isRecordLoaded",true);
        } else //if (eventParams.changeType === 'CHANGED') {
        {
            //component.find('recordLoader').reloadRecord(true);
            helper.isDuplicateRecordsExistHelper(component, helper);
        }

    },

    onMasterRadioButtonChange : function(component, event, helper) {   
        var apiName = event.getSource().get("v.name");
        var tabindex = event.getSource().get("v.tabindex");
        var objName = event.getSource().get("v.value");
        var checked = event.getSource().get("v.checked")
        var selectedPatients = component.get("v.selectedPatients");
        var finalRec = component.get("v.finalRec");
        
        var masterRecRadio = component.find("masterRecRadio");
        // var masterAdmissionRecRadio = component.find("masterAdmissionRecRadio");
        console.log('apiName', apiName, objName);
        if(apiName === 'Id' && objName === 'Contact') {
            if(masterRecRadio) {
                if(Array.isArray(masterRecRadio)){
                    for(var i=0; i< masterRecRadio.length; i++) {
                        $A.util.removeClass(masterRecRadio[i], 'slds-has-error');
                    }
                } else {
                    $A.util.removeClass(masterRecRadio, 'slds-has-error');
                }
            }
        }
        
        if(checked) {
            if(objName === 'Contact'){
                component.set('v.slectedMasterRecordIndex', tabindex);
                //helper.isValidMasterAccountRecord(component, event, helper);

                finalRec.contactRec = JSON.parse(JSON.stringify(selectedPatients[tabindex].contactRec));
                finalRec.accountRec = JSON.parse(JSON.stringify(selectedPatients[tabindex].accountRec));
                
                var conFieldRadio = component.find("conFieldRadio");
                var accFieldRadio = component.find("accFieldRadio");
                console.log('conFieldRadio', conFieldRadio);
                helper.radioButtonCheckHelper(component, conFieldRadio, tabindex);
                helper.radioButtonCheckHelper(component, accFieldRadio, tabindex);

            } 
        }
        component.set("v.finalRec", finalRec);
        console.log('finalRec', finalRec);
        console.log('contactRec', finalRec.contactRec);
        console.log('accountRec', finalRec.accountRec);
        
    },
    onRadioButtonChange : function(component, event, helper) {
        var radioName = event.getSource().get("v.name");
        var apiNameArr = radioName.split('-');
        var apiName = apiNameArr[1];
        var tabindex = event.getSource().get("v.tabindex");
        var objName = event.getSource().get("v.value");
        var checked = event.getSource().get("v.checked")
        var selectedPatients = component.get("v.selectedPatients");
        var finalRec = component.get("v.finalRec");
        console.log('name', apiName, tabindex, objName);
        
        if(checked) {
            if(objName === 'Contact'){
                finalRec.contactRec[apiName] = selectedPatients[tabindex].contactRec[apiName] || null;
            } else if(objName === 'Account'){
                finalRec.accountRec[apiName] = selectedPatients[tabindex].accountRec[apiName] || null;
            } else if(objName === 'Admission'){
                if(apiName === 'AdmissionId'){
                    finalRec.admissionRec['Id'] = selectedPatients[tabindex].admissionRec['Id'] || null;
                } else {
                    finalRec.admissionRec[apiName] = selectedPatients[tabindex].admissionRec[apiName] || null;
                }
            }
        }
        component.set("v.finalRec", finalRec);
        console.log('finalRec', finalRec);
        console.log('contactRec', finalRec.contactRec);
        console.log('accountRec', finalRec.accountRec);
    },
    
    comparePatient : function(component, event, helper) {
        helper.comparePatient(component, event, helper);
    },
    
    onSelectForCompare : function(component, event, helper) {
        console.log('event', event.getSource().get("v.value"));
        console.log('checked', checked);
        var patient = event.getSource().get("v.value");
        var checked = event.getSource().get("v.checked");
        var selectedPatients = component.get("v.selectedPatients") || [];
        var DuplicatePatients = component.get("v.DuplicatePatients") || [];
        
        if(checked === true) {
            
            if(selectedPatients.length > 0) {
                var isAvailable = false;
                for(var i=0; i< selectedPatients.length; i++) {
                    if(selectedPatients[i].contactRec.Id === patient.contactRec.Id) {
                        isAvailable = true;
                        break;
                    }
                }
                
                if(isAvailable === false) {
                    if(selectedPatients.length >= 2) {
                        for(var j=0; j< DuplicatePatients.length; j++) {
                            if(DuplicatePatients[j].contactRec.Id === patient.contactRec.Id) {
                                DuplicatePatients[j].isSelected = false;
                            }
                        }
                        patient.isSelected = false;
                        component.find('notifLib').showToast({
                            "message": "Please select only two patients to compare.",
                            "variant": "error",
                            "mode" : "dismissable"
                        });
                    } else {
                        selectedPatients.push(patient);
                    }
                    
                }
            } else {
                selectedPatients.push(patient);
            }
        } else if(checked === false) {
            if(selectedPatients.length > 0) {
            	for(var i=0; i< selectedPatients.length; i++) {
                    if(selectedPatients[i].contactRec.Id === patient.contactRec.Id) {
                        selectedPatients.splice(i, 1);
                    }
                }
            }
        }
        console.log('selectedPatients', selectedPatients);
        component.set("v.selectedPatients", selectedPatients);
        //debugger;
        //component.set("v.selectedPatients", helper.validateSpecialFields(selectedPatients));
        component.set("v.DuplicatePatients", DuplicatePatients);
    },
    
    
    onDifferentPeopleButtonClick : function(component, event, helper)
    {
        debugger;
        const differentContactId = event.getSource().get('v.name');
        component.set('v.differentContactId', differentContactId);
        
        const variant = event.getSource().get('v.variant');
        let newDifferentValue = (variant != 'destructive');//if currently destructive, that means it's current different
        component.set('v.newDifferentValue', newDifferentValue);

        component.set("v.confirmationModalMode", 'differentPeople');  
        component.set("v.showConfirmationModal", true);
    },
    
    onSamePersonButtonClick : function(component, event, helper) {
        //debugger;
        var selectedPatients = component.get("v.selectedPatients") || [] ;
        
        if(selectedPatients.length == 2) {

            component.set("v.mode", 'Edit');
        } else {
            component.find('notifLib').showToast({
                "message": "Please select two Patients.",
                "variant": "error",
                "mode" : "dismissable"
            });
        }
    },

    onMergePatientsClick : function(component, event, helper)
    {
        if(!helper.isValidMasterAccountRecord(component, event, helper)) {
            return;
        }
        helper.masterRecordValidation(component, 'mergePatients');
    },

    onCloseButtonClick : function(component, event, helper)
    {
        if (component.get('v.mode') == 'View')
        {
            helper.cancel(component, event, helper);
        } else
        {
            component.set("v.confirmationModalMode", 'closeButton');  
            component.set("v.showConfirmationModal", true);
        }
    },
    onCancelMergeClick : function(component, event, helper)
    {
        component.set("v.mode", 'View');
    },

    yes : function(component, event, helper) {
        var  confirmationModalMode = component.get("v.confirmationModalMode") || '';
        
        if(confirmationModalMode === 'mergePatients') {
            helper.mergePatientsHelper(component, helper);
        } 
        if(confirmationModalMode === 'differentPeople') 
        {
            component.set("v.loading", true);
            helper.onDifferentPersonConfirmed(component, event, helper);
        } 
        if(confirmationModalMode === 'closeButton') 
        {
            helper.cancel(component, event, helper);
        } 
    },
    no : function(component, event, helper) {
        component.set('v.differentContactId', '');
        component.set("v.showConfirmationModal", false);
    }
})
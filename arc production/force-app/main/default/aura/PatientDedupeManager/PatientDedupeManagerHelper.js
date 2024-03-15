({
    getSelectedPatients : function(component, helper) {
        var selectedPatients = [];
        var DuplicatePatients = component.get("v.DuplicatePatients") || [];
        
        if(DuplicatePatients.length > 0) {
            for(var i=0; i< DuplicatePatients.length; i++) {
                if(DuplicatePatients[i].isSelected === true) {
                    selectedPatients.push(DuplicatePatients[i]);
                }
            }
        }
        console.log('selectedPatients', selectedPatients);

        // component.set("v.selectedPatients", selectedPatients);
        component.set("v.selectedPatients", helper.validateSpecialFields(selectedPatients));
    },
    
    radioButtonCheckHelper : function(component, fieldRadio, tabindex) {
        if(fieldRadio) {
            if(Array.isArray(fieldRadio)){
                fieldRadio.forEach(function(radio){
                    var index = radio.get("v.tabindex");
                    console.log(index, tabindex, radio.get("v.name"));
                    
                    if(index == tabindex) {
                        console.log('entered');
                        radio.set("v.checked", true);
                    } else {
                        radio.set("v.checked", false);
                    }
                });
                    
            } else {
                var index = fieldRadio.get("v.tabindex");
                if(index == tabindex) {
                    fieldRadio.set("v.checked", true);
                } else {
                    fieldRadio.set("v.checked", false);
                }
            }
        }
    },
    
    isDuplicateRecordsExistHelper : function(component, helper, callback)
    {
        if (!component.get('v.loading'))
        {
            component.set("v.loading", true);
            helper.callApexMethod(
                component,
                "isDuplicateRecordsExist",
                {'recordId': component.get("v.recordId")},
                function (result) {
                    component.set("v.loading", false);
                    component.set("v.isDuplicatePatientsExist",result);

                    if (callback) callback(component, helper);
                },
                function(error){
                    component.set("v.loading", false);
                    console.log('error', error);
                    component.find('notifLib').showToast({
                        "message": error,
                        "variant": "error",
                        "mode" : "dismissable"
                    });
                },
                false
            );
        }
    },
    
    masterRecordValidation : function(component, mode){
        var finalRec = component.get("v.finalRec");
        var conIdUnavailable = false;
        var admissionIdUnavailable = false;
        var errorMsg = '';
        var selectedPatients = component.get("v.selectedPatients");
        
        console.log('contactRec', finalRec.contactRec, finalRec.accountRec);
        if(!finalRec.contactRec.Id)
        {
            conIdUnavailable = true;
            var masterRecRadio = component.find("masterRecRadio");
            if(masterRecRadio) {
                if(Array.isArray(masterRecRadio)){
                    for(var i=0; i< masterRecRadio.length; i++) {
                        $A.util.addClass(masterRecRadio[i], 'slds-has-error');
                    }
                } else {
                    $A.util.addClass(masterRecRadio, 'slds-has-error');
                }
            }
            errorMsg += 'Please select the Master record for Contact';
        } else if(!finalRec.accountRec.Id){
            for(var i=0; i< selectedPatients.length; i++){
                if(finalRec.contactRec.Id === selectedPatients[i].contactRec.Id){
                    finalRec.accountRec.Id = selectedPatients[i].contactRec.AccountId || selectedPatients[i].accountRec.Id || '';
                }
            }
            component.set("v.finalRec", finalRec);
        } 

        if(!conIdUnavailable ) 
        {
            component.set("v.showConfirmationModal", true);
            component.set("v.confirmationModalMode", mode);
        } else {
            component.find('notifLib').showToast({
                "message": errorMsg,
                "variant": "error",
                "mode" : "dismissable"
            });
        }
    },

    onDifferentPersonConfirmed : function(component, event, helper)
    {
        const conId = component.get('v.differentContactId');
        const newDifferentValue = component.get('v.newDifferentValue'); 

        console.log(conId + ' to mark different ' + newDifferentValue);

        helper.setAsDifferentPeopleHelper(component, helper, conId, newDifferentValue);
    },


    
    setAsDifferentPeopleHelper : function(component, helper, conId, newDifferentValue) 
    {
        component.set("v.loading", true);
        
        let duplicatePatients = component.get("v.DuplicatePatients") || [];
        let conIds = [];
        if (newDifferentValue)
        {
            //if it's just this one and one other, mark both different
            let nonDifferentConIds = [];
            for(var i=0; i< duplicatePatients.length; i++)
            {
                if (duplicatePatients[i].contactRec.Id != conId && !duplicatePatients[i].isDifferent) //collect if this is a nonDifferent
                {
                    nonDifferentConIds.push(duplicatePatients[i].contactRec.Id);
                }
            }
            conIds = [ conId ];

            if (nonDifferentConIds.length == 1)
            {
                conIds = [...conIds, ...nonDifferentConIds];
            }

        } else if (!component.get('v.numberNonDifferentPatients'))
        {
            for(var i=0; i< duplicatePatients.length; i++)
            {
                conIds.push(duplicatePatients[i].contactRec.Id);
            }
        }

        helper.callApexMethod(
            component,
            "setAsDifferentPeople",
            {'conIds': JSON.stringify(conIds), newDifferentValue},
            function (result) {
                helper.comparePatient(component, event, helper);
                component.set("v.showConfirmationModal", false);
                component.set('v.differentContactId', '');
            },
            function(error){
                component.find('notifLib').showToast({
                    "message": error,
                    "variant": "error",
                    "mode" : "dismissable"
                });
                console.log('error', error);

                helper.isDuplicateRecordsExistHelper(component, helper);
                component.set("v.showConfirmationModal", false);
                component.set('v.differentContactId', '');
            },
            false
        );
    },
    
    comparePatient : function(component, event, helper) {
        if (component.get("v.isDuplicatePatientsExist"))
        {
            component.set("v.loading", true);
            helper.callApexMethod(
                component,
                "getDuplicateRecordSet",
                {'recordId': component.get("v.recordId")},
                function (result) {
                    component.set("v.loading", false);
                    console.log(JSON.parse(result));
                    console.log('**** Duplicated Accs ----> ', JSON.parse(result));
                    var result = JSON.parse(result);
                    console.log('result', result);
                    let numberNonDifferentPatients = 0;
                    if (result.records && result.records.length > 0)
                    {
                        numberNonDifferentPatients = result.records.filter(patient => !patient.isDifferent).length;
                        component.set("v.DuplicatePatients", result.records);
                        component.set("v.FieldSet", result.allFieldSet);
                        component.set("v.showCompareModal", true);
                    }
                    component.set('v.numberNonDifferentPatients', numberNonDifferentPatients);
                    
                    // helper.getSelectedPatients(component);
                    helper.getSelectedPatients(component, helper);
                    component.set("v.loading", false);
                },
                function(error){
                    component.set("v.loading", false);
                    console.log('error', error);
                    component.find('notifLib').showToast({
                        "message": error,
                        "variant": "error",
                        "mode" : "dismissable"
                    });
                    component.set("v.loading", false);
                },
                false
            );
        }
    },
    
    mergePatientsHelper : function(component, helper) {
        var finalRec = component.get("v.finalRec") || {};
        var selectedPatients = component.get("v.selectedPatients") || [];
        var secondaryRecId = '';
        var secondaryRecAccId = '';
        var secondaryAdmissionId = '';
        
        for(var i=0; i< selectedPatients.length; i++){
            if(selectedPatients[i].contactRec.Id !=  finalRec.contactRec.Id) {
                secondaryRecId = selectedPatients[i].contactRec.Id;
                secondaryRecAccId = selectedPatients[i].contactRec.AccountId || selectedPatients[i].accountRec.Id || '';
            }
        }
        
        if(secondaryRecId != ''){
            component.set("v.loading", true);
            
            helper.callApexMethod(
                component,
                'mergePatients',
                {
                    'masterRecStr': JSON.stringify(finalRec),
                    'secondaryConId': secondaryRecId
                },
                function (result) {
                    debugger;
                    
                    //if (!result.errorMessage)
                    if (result.errorMessage == undefined || result.errorMessage == '' || result.errorMessage == null)
                    {
                        component.set("v.loading", false);
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Patient merged successfully.",
                            "mode" : "dismissable"
                            
                        });
                        toastEvent.fire();
                        
                        if(component.get("v.recordId") === finalRec.accountRec.Id
                            || component.get("v.recordId") === secondaryRecAccId) 

                        {
                            var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": finalRec.accountRec.Id
                            });
                            navEvt.fire();
                        } else {
                            helper.isDuplicateRecordsExistHelper(component, helper, 
                                new function(component, helper)
                                {
                                    helper.comparePatient(component, null, helper);
                                });
                            component.set("v.showConfirmationModal", false);
                            component.set("v.showCompareModal", false);
                            component.set("v.mode", 'View');
                            component.set("v.finalRec", {'contactRec':{},'accountRec':{},'admissionRec':{}});

                            //helper.comparePatient(component, event, helper);
                        }
                    } else
                    {
                        component.set("v.loading", false);
                        // console.log('error', error);
                        // component.find('notifLib').showToast({
                        //     "message": error,
                        //     "variant": "error",
                        //     "mode" : "dismissable"
                        // });

                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error",
                            "message": result.errorMessage,
                            "type": "error",
                            "mode" : "dismissable"
                            
                        });
                        toastEvent.fire();

                    }
                    
                },
                function(error){
                    component.set("v.loading", false);
                    console.log('error', error);
                    component.find('notifLib').showToast({
                        "message": error,
                        "variant": "error",
                        "mode" : "dismissable"
                    });
                },
                false
            );
        } 
        
    },
    cancel : function(component, event, helper) 
    {
        component.set("v.showConfirmationModal", false);
        component.set("v.showCompareModal", false);
        component.set("v.mode", 'View');
        component.set("v.finalRec", {'contactRec':{},'accountRec':{},'admissionRec':{}});
        helper.isDuplicateRecordsExistHelper(component, helper);
    },
    isValidMasterAccountRecord: function (component) {
        debugger;
        
        let slectedMasterRecordIndex = component.get('v.slectedMasterRecordIndex');        

        if (slectedMasterRecordIndex == undefined) {
            return false;
        }
        
        var selectedPatients = component.get("v.selectedPatients");

        //Prevent User to continue if the Account we would be deleting has a Medical Record Number or any of our External IDs specified.
        let nonMasterIndex = slectedMasterRecordIndex == 0 ? 1 : 0;
        let nonMasterAccountRecord = JSON.parse(JSON.stringify(selectedPatients[nonMasterIndex].accountRec));
        let masterAccountRecord = JSON.parse(JSON.stringify(selectedPatients[slectedMasterRecordIndex].accountRec));        
        let finalRec = component.get("v.finalRec");
        let isInvalidSelectedField = false;

        //TODO: Compare master VS nonMaster Records special Fields
        let specialFields = [
            { label:'Medical_Record_Number__c', bothPopulated: false, value: ''},
            { label:'External_Contact_Id__c', bothPopulated: false, value: ''},
            { label:'External_ID__c', bothPopulated: false, value: ''},
            { label:'External_Patient_Id__c', bothPopulated: false, value: ''}
        ];

        //Verify if both records contains values in special fileds
        let accRecordOne = selectedPatients[0].accountRec;
        let accRecordTwo = selectedPatients[1].accountRec;

        for (let i = 0; i < specialFields.length; i++) {
            const field = specialFields[i];

            if(accRecordOne[field.label] && accRecordTwo[field.label]){
                //specialFields[i].bothPopulated = true;
                //Verify if the selected field to merge from the final record is the same as the master record.
                // if(finalRec.accountRec[field.label] != masterAccountRecord[field.label]){
                    isInvalidSelectedField = true;
                    break;
                //}
            } else {//Validate if the final record has a valid value in the special field
                let value = accRecordOne[field.label] ? accRecordOne[field.label] : accRecordTwo[field.label];
                if(finalRec.accountRec[field.label] != value) {
                    isInvalidSelectedField = true;
                    break;
                }
            }
        }


        // if(nonMasterAccountRecord.Medical_Record_Number__c || nonMasterAccountRecord.External_Contact_Id__c
        //     || nonMasterAccountRecord.External_ID__c || nonMasterAccountRecord.External_Patient_Id__c) {
        //     component.find('notifLib').showToast({
        //         "message": "This is an invalid master patient record.",
        //         "variant": "error",
        //         "mode" : "dismissable"
        //     });
        //     return false;
        // }

        if(isInvalidSelectedField) {
            component.find('notifLib').showToast({
                "message": "Invalid selected fields for the Master Record",
                "variant": "error",
                "mode" : "dismissable"
            });
            return false;
        }

        return true;
    },
    validateSpecialFields: function(selectedPatients) {//This will prevent the user to select fields on mergin if both records have the same special fields populated
       
        if (selectedPatients) {
            
            debugger;
            let specialFields = [
                'Medical_Record_Number__c',
                'External_Contact_Id__c',
                'External_ID__c',
                'External_Patient_Id__c'
            ];

            if (selectedPatients.length >= 2) {
                 //Verify if both records contains values in special fileds
                let accRecordOne = selectedPatients[0].accountRec;
                let accRecordTwo = selectedPatients[1].accountRec;

                for (let i = 0; i < specialFields.length; i++) {
                    const field = specialFields[i];
                
                    if(accRecordOne[field] && accRecordTwo[field]){
                        selectedPatients[0].accountRec.dontDisplay = true;
                        selectedPatients[1].accountRec.dontDisplay = true;
                    }
                }
            }
            
        }

        return selectedPatients;
    }


})
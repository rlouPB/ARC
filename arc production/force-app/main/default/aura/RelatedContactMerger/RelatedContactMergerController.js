({
    doInit : function(component, event, helper) {
        helper.getRelatedContactsHeleper(component,helper);
    },
    onSelectionChange : function (component, event, helper) {
        var selectedRelatedContact = event.getSource().get('v.value');
        var checked = event.getSource().get('v.checked');
        
        console.log('checked-->',checked);
        //console.log('selectedRelatedContact-->',JSON.stringify(selectedRelatedContact));
        var selectedList = component.get('v.selectedList') || [];
        var selectedContactList = component.get('v.selectedContactList') || [];
        let isDifferentContactIds = false;

        if (checked && checked === true) {
            if (selectedList && selectedList.length >= 2) {
                
                var inputCheckboxes = component.find("isMerge");
                
                if (inputCheckboxes && Array.isArray(inputCheckboxes)) {
                    for(var i=0 ; inputCheckboxes.length > i ; i++ )
                    {
                        if(inputCheckboxes[i].get('v.name') == selectedList[0].Id){
                            inputCheckboxes[i].set('v.checked',false);
                            break;
                        }
                    }
                }

                selectedList.splice(0,1);
                selectedContactList.splice(0,1);

                
            }       
            if (selectedList && selectedList.length === 1) {
                
                if(selectedList[0].RecordTypeId === selectedRelatedContact.RecordTypeId){
                    
                    selectedList.push(selectedRelatedContact);
                    selectedContactList.push(selectedRelatedContact.Contact__r);
                    if (selectedContactList[0].Id != selectedContactList[1].Id) isDifferentContactIds = true;
                } else {
                    event.getSource().set('v.checked',false);
                    component.find('notifLib').showToast({
                        "variant" : "warning",
                        "title": "Merge Incompatible",
                        "message": "Select Related Contacts of same type"
                    });
                }
            } else {
                
                selectedList.push(selectedRelatedContact);
                selectedContactList.push(selectedRelatedContact.Contact__r);
            }
        } else {
            
            var existingIndex = selectedList.indexOf(selectedRelatedContact);
            console.log('existingIndex-->',existingIndex);
            
            if (existingIndex != -1) {
                
                selectedList.splice(existingIndex,1);
                selectedContactList.splice(existingIndex,1);
                event.getSource().set('v.checked',false);
            }
        }
        component.set('v.selectedList',selectedList);
        component.set('v.selectedContactList',selectedContactList);
        component.set('v.isDifferentContactIds', isDifferentContactIds);
        console.log('selectedList',JSON.parse(JSON.stringify(selectedList)));
        console.log('selectedContactList',JSON.parse(JSON.stringify(selectedContactList)));
    },
    onRadioButtonChange : function (component, event, helper) {
        debugger;
        var index = event.getSource().get('v.tabindex');
        var fieldname = event.getSource().get('v.name');
        var sObjectType = event.getSource().get('v.value');
        var selectedList = component.get('v.selectedList');
        var selectedContactList = component.get('v.selectedContactList');
        var finalRec = component.get('v.finalRec') || {};
        var deleteIndex = (index == 0) ? 1 : 0 ;
        
        console.log('index-->',index);
        console.log('deleteIndex-->',deleteIndex);
        console.log('fieldname-->',fieldname);
        //console.log('finalRec-->',JSON.parse(JSON.stringify(finalRec)));'
        
        var fieldnamesArr = fieldname.split('-');
        console.log('fieldNamesArr',fieldnamesArr);
        fieldname = fieldnamesArr[1];
        console.log('aftr split fieldname-->',fieldname);
        if (fieldname && fieldname === 'Id' && sObjectType === 'RelatedContact') {
            
            fieldname = 'Id';
            helper.onMasterRadioCheck(component, sObjectType, index);
            finalRec.relatedContactRec = JSON.parse(JSON.stringify(selectedList[index]));
            component.set('v.nonMasterRecId',selectedList[deleteIndex].Id);
            finalRec.contactRec[fieldname] = (selectedContactList[index][fieldname] != undefined) ? selectedContactList[index][fieldname] : null; //Added by Fernando Ortiz
            let testFinalRec = JSON.parse(JSON.stringify(finalRec));
            console.log('##### testFinalRec ---> ',  testFinalRec);
        } else if (fieldname && fieldname === 'Id' && sObjectType === 'Contact') {
            debugger;
            
            fieldname = 'Id';
            helper.onMasterRadioCheck(component, sObjectType, index);
            finalRec.contactRec = JSON.parse(JSON.stringify(selectedContactList[index]));
            
        } 
        console.log('selectedList-->',JSON.parse(JSON.stringify(selectedList)));
        console.log('before update index-->',index);
        console.log('fieldname***>',fieldname);
        
        if (sObjectType && sObjectType === 'RelatedContact' && fieldname !== 'Id'){
            
            finalRec.relatedContactRec[fieldname] = (selectedList[index][fieldname] != undefined) ? selectedList[index][fieldname] : null;
        } else if (sObjectType && sObjectType === 'Contact' && fieldname !== 'Id') {
            
            finalRec.contactRec[fieldname] = (selectedContactList[index][fieldname] != undefined) ? selectedContactList[index][fieldname] : null;
        }
        console.log('finalRec-->',JSON.parse(JSON.stringify(finalRec)));
    },
    handleCloseModalEvent : function (component, event, helper)
    {
        let modalName = 'rcMerge';

        if (event) modalName = event.getParam('data');
        if (modalName == 'mergeConfirmation')
        {
            event.stopPropagation();
            helper.closeConfirmationModal(component, event, helper);
        } else if (modalName == 'cancelConfirmation')
        {
            event.stopPropagation();
            helper.closeCancelConfirmationModal(component, event, helper);
        } else if (modalName == 'rcMerge')
        {
            helper.closeModal(component, event, helper);
        }
    },

    closeModal : function (component, event, helper) 
    {
        helper.closeModal(component, event, helper);
    },
    onMerge : function (component, event, helper) {
        let finalRecords = component.get('v.finalRec');
        let isDifferentContactIds = component.get('v.isDifferentContactIds');

        if (finalRecords 
            && finalRecords.relatedContactRec && finalRecords.relatedContactRec.Id
            && (!isDifferentContactIds || 
                    (finalRecords.contactRec  && finalRecords.contactRec.Id )))

        {
            component.set('v.showConfirmationModal',true);
        }  else {
            component.find('notifLib').showToast({
                "variant" : "info",
                "title": "No Selection",
                "message": "Please Select 2 records for merge and identify which is the Master."
            });
        }
    },
    onConfirmMerge : function (component, event, helper) 
    {
        helper.saveFinalRecords(component,helper);
        helper.closeConfirmationModal(component, event, helper);
    },
    onConfirmCancel : function (component, event, helper) 
    {
        helper.closeModal(component, event, helper, true);
    },
    closeConfirmationModal : function (component, event, helper) 
    {
        helper.closeConfirmationModal(component, event, helper);
    },
    closeCancelConfirmationModal : function (component, event, helper) 
    {
        helper.closeCancelConfirmationModal(component, event, helper);
    }
})
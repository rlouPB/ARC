({
    showSpinner: function(component) {
        let spinnerCmp = component.find('mySpinner');
        spinnerCmp.set("v.class", "slds-show");
        //component.set("v.showSpinner", true); 
    },
	hideSpinner: function(component) {
        let spinnerCmp = component.find('mySpinner');
        spinnerCmp.set("v.class", "slds-hide");
        //component.set("v.showSpinner", false); 
    },
    showToast: function(params) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(params);
        toastEvent.fire();
    },
    handleError: function(errors,helper) {
    	let errorMessage = helper.getErrorMessage(errors);
                        
        helper.showToast({
        	title : "Error!!!",
            message : errorMessage,
            type : "error",
            mode : "sticky"
        });
        
    },
    getErrorMessage : function(errors) {
    	let errorMessage = '';
        if (errors && Array.isArray(errors) && errors.length > 0) {
            errors.forEach(error=>{
                if (error.message) {
                	errorMessage += error.message + "\n";
            	} 
                if (error.pageErrors && error.pageErrors.length > 0) {
                	error.pageErrors.forEach(pageError=>{
                    	errorMessage += pageError.message + "\n";
                	});
                } else if (error.fieldErrors) {
                	let fields = Object.keys(error.fieldErrors);
                   
                    fields.forEach(fieldError=>{
                        if(Array.isArray(error.fieldErrors[fieldError])) {
						let fieldErrors =  error.fieldErrors[fieldError];
                           fieldErrors.forEach(err=>{
                            	errorMessage += err.message; 
                            });
                    	}
                    	   
                    })
                }
            });
        }
       return  (errorMessage != '' ? errorMessage : 'Unknown error');       
	},
    getSOHSnapshotSubset : function(component, event, helper)
    {
        debugger;
        var patientId
        let noteItem = component.get("v.noteItem");
        var subsetType = JSON.parse(noteItem.noteItem.Embedded_Component_Parameters__c).subsetType;
        var subsetField = JSON.parse(noteItem.noteItem.Embedded_Component_Parameters__c).subsetField;
        let theNote = component.get("v.theNote");
        
        if (!$A.util.isEmpty(theNote)
            && !$A.util.isEmpty(theNote.patientNote)
            && !$A.util.isEmpty(theNote.patientNote.Account__c)) 
        {
            patientId = theNote.patientNote.Account__c;
        }
        if(!$A.util.isEmpty(patientId))
        {
            //console.log('patientNote:'+JSON.stringify(theNote));
            let action = component.get('c.getSOHSnapshotSubset');
            helper.showSpinner(component);
            let params=
            {
                "noteId": theNote.patientNote.Id,
                "patientId":patientId,
                "noteType":subsetType,
                "sohField":subsetField
            };
            action.setParams(params);
            action.setCallback(this, response=>{
                if (response.getState() ===  "SUCCESS")
                {
                    let returnVal=response.getReturnValue();
                    //let meetingTypeList=JSON.parse(returnVal);
                    /*
                    console.log("meetingTypeList:"+JSON.stringify(returnVal));
                    component.set("v.meetingTypeList",returnVal);
                    helper.fireNoteChangedEvent(component, event, helper);
                    */
                    console.log('Current Treatment Plan:'+JSON.stringify(returnVal));
                    var changedFields = component.set("v.changedFields") || [];
                    changedFields.push({
                        field: subsetField,
                        value: returnVal
                    });
                    component.set("v.changedFields", changedFields);
                    helper.fireNoteChangedEvent(component, event, helper);
                    component.set("v.subsetHtml", returnVal);
                } 
                else if (response.getState() === "ERROR")
                {
                    helper.handleError(response.getError(),helper);
                }
            	helper.hideSpinner(component);   
        	});
            $A.enqueueAction(action);
        }else{
            helper.hideSpinner(component);   
        }
    }
})
/* eslint-disable no-unused-expressions */
({
  showSpinner: function (component) {
    let spinnerCmp = component.find("mySpinner");
    spinnerCmp.set("v.class", "slds-show");
    //component.set("v.showSpinner", true);
  },
  hideSpinner: function (component) {
    let spinnerCmp = component.find("mySpinner");
    spinnerCmp.set("v.class", "slds-hide");
    //component.set("v.showSpinner", false);
  },
  showToast: function (params) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams(params);
    toastEvent.fire();
  },
  handleError: function (errors, helper) {
    let errorMessage = helper.getErrorMessage(errors);

    helper.showToast({
      title: "Error!!!",
      message: errorMessage,
      type: "error",
      mode: "sticky"
    });
  },
  getErrorMessage: function (errors) {
    let errorMessage = "";

    if (errors && Array.isArray(errors) && errors.length > 0) {
      errors.forEach((error) =>{
        if (error.message) {
          errorMessage += error.message + "\n";
        }
        if (error.pageErrors && error.pageErrors.length > 0) {
          error.pageErrors.forEach((pageError) =>{
            errorMessage += pageError.message + "\n";
          });
        } else if (error.fieldErrors) {
          let fields = Object.keys(error.fieldErrors);

          fields.forEach((fieldError) =>{
            if (Array.isArray(error.fieldErrors[fieldError])) {
              let fieldErrors = error.fieldErrors[fieldError];
              fieldErrors.forEach((err) =>{
                errorMessage += err.message;
              });
            }
          });
        }
      });
    }
    return errorMessage != "" ? errorMessage : "Unknown error";
  },
  getCurrentTreatmentPlan: function (component, event, helper) 
  {
    var treatmentPlanId = component.get("v.treatmentPlanId");

    let theNote = component.get("v.theNote");
    if (!$A.util.isEmpty(theNote) &&
      !$A.util.isEmpty(theNote.patientNote) &&
      !$A.util.isEmpty(theNote.patientNote.Account__r) &&
      !$A.util.isEmpty(theNote.patientNote.Account__r.Current_Case__c)
    ) {
      treatmentPlanId = theNote.patientNote.Account__r.Current_Case__c;
    }
    if (!$A.util.isEmpty(treatmentPlanId)) 
    {
      //console.log('patientNote:'+JSON.stringify(theNote));
      let action = component.get("c.getTreatmentPlan");
      helper.showSpinner(component);
      let params = 
      {
        treatmentPlanId: treatmentPlanId
      };
      action.setParams(params);
      action.setCallback(this, (response) => {
        if (response.getState() === "SUCCESS") 
        {
          let returnVal = response.getReturnValue();
          //let meetingTypeList=JSON.parse(returnVal);
          /*
                    console.log("meetingTypeList:"+JSON.stringify(returnVal));
                    component.set("v.meetingTypeList",returnVal);
                    helper.fireNoteChangedEvent(component, event, helper);
                    */
          console.log("Current Treatment Plan:" + JSON.stringify(returnVal));
          component.set("v.currentTreatmentPlan", returnVal);
        } 
        else if (response.getState() === "ERROR") 
        {
          helper.handleError(response.getError(), helper);
        }
        helper.hideSpinner(component);
      });
      $A.enqueueAction(action);
    } else {
      helper.hideSpinner(component);
    }
  }
});
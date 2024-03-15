({
  getDateStrings: function (component, event, helper) {
    var attended = "8/1, 8/5, 8/10, 8/14, 8/15, 8/18, 8/22, 8/26, 8/28, 8/30";
    var absences = "8/12, 8/20, 8/28";

    component.set("v.attended", attended);
    component.set("v.absences", absences);
  },
  showSpinner: function (component) {
    let spinnerCmp = component.find("mySpinner");
    spinnerCmp.set("v.class", "slds-show");
  },
  hideSpinner: function (component) {
    let spinnerCmp = component.find("mySpinner");
    spinnerCmp.set("v.class", "slds-hide");
  },
  getMeetings: function (component, event, helper) {
    let theNote = component.get("v.theNote");
    if (!$A.util.isEmpty(theNote.patientNote.Contact_Date__c) 
        && theNote.patientNote.Status__c == 'Draft') 
    {
      // console.log('patientNote:'+JSON.stringify(theNote));
      let action = component.get("c.getMeetings");
      helper.showSpinner(component);
      let params = {
        contactDate: theNote.patientNote.Contact_Date__c,
        patientId: theNote.patientNote.Account__c,
        noteId: theNote.patientNote.Id
      };
      action.setParams(params);
      action.setCallback(this, (response) => {
        if (response.getState() == "SUCCESS") {
          let returnVal = response.getReturnValue();

          component.set("v.meetingTypeList", returnVal.meetingTypes);
          //update patient note if status is Draft
          if (theNote.patientNote.Status__c == 'Draft') 
          {
            helper.updateAggregatedAttendanceFields(component, returnVal);
            helper.fireNoteChangedEvent(component, event, helper);
          }
        } else if (response.getState() == "ERROR") {
          helper.handleError(response.getError(), helper);
        }
        helper.hideSpinner(component);
      });
      $A.enqueueAction(action);
    } else {
      helper.hideSpinner(component);
    }
  },
  updateAggregatedAttendanceFields: function (component, returnVal) {
    var attendedDates = "";
    var unattendedDates = "";
    var unknownDates = "";
    //add to changedFields
    var changedFields = component.set("v.changedFields") || [];
    
    changedFields.push({
      field: "Attended_Meetings__c",
      value: returnVal.attendedDates
    });
    changedFields.push({
      field: "Unattended_Meetings__c",
      value: returnVal.unattendedDates
    });
    changedFields.push({
      field: "Unknown_Meeting_Attendance__c",
      value: returnVal.unknownDates
    });
    changedFields.push({
      field: "NoteAttendanceHtml__c",
      value: returnVal.noteAttendanceHtml
    });
    
    component.set("v.changedFields", changedFields);
    //helper.fireNoteChangedEvent(component, event, helper);
  },
  updateAttendanceComments: function (component, event, helper) {
    component.set("v.changedFields", [
      { field: "Attendance_Comments__c", value: event.getParam("value") }
    ]);
    helper.fireNoteChangedEvent(component, event, helper);
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
      errors.forEach((error) => {
        if (error.message) {
          errorMessage += error.message + "\n";
        }
        if (error.pageErrors && error.pageErrors.length > 0) {
          error.pageErrors.forEach((pageError) => {
            errorMessage += pageError.message + "\n";
          });
        } else if (error.fieldErrors) {
          let fields = Object.keys(error.fieldErrors);

          fields.forEach((fieldError) => {
            if (Array.isArray(error.fieldErrors[fieldError])) {
              let fieldErrors = error.fieldErrors[fieldError];
              fieldErrors.forEach((err) => {
                errorMessage += err.message;
              });
            }
          });
        }
      });
    }
    return errorMessage != "" ? errorMessage : "Unknown error";
  },

  getStartOfMonth: function (component, event, helper) {
    var endOfMonth = component.get("v.theNote.patientNote.Contact_Date__c");
    if (endOfMonth) {
      var startOfMonth = new Date(
        endOfMonth.substring(0, 8).concat("01 00:00:00")
      );
      var endOfMonthDate = new Date(endOfMonth.concat(" 12:00:00"));
      component.set("v.startOfMonth", startOfMonth);
      component.set("v.endOfMonth", endOfMonthDate);
    }
  }
});
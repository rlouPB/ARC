({
  toggleSpinner: function (component, duration) {
    component.set("v.enableButtons", !component.get("v.enableButtons"));
    window.setTimeout(
      $A.getCallback(function () {
        if (component.find("spinner")) {
          var spinnerCls = component.find("spinner").get("v.class");
          if (spinnerCls) {
            if (spinnerCls === "slds-show") {
              component.find("spinner").set("v.class", "slds-hide");
            } else {
              component.find("spinner").set("v.class", "slds-show");
            }
          } else {
            component.find("spinner").set("v.class", "slds-hide");
          }
        }
      }),
      duration
    );
  },

  hideSpinner: function (component, helper, duration) {
    component.set("v.enableButtons", true);
    window.setTimeout(
      $A.getCallback(function () {
        if (component.find("spinner")) {
          component.find("spinner").set("v.class", "slds-hide");
        }
      }),
      duration
    );
  },

  showSpinner: function (component, helper, duration) {
    component.set("v.enableButtons", false);
    window.setTimeout(
      $A.getCallback(function () {
        if (component.find("spinner")) {
          component.find("spinner").set("v.class", "slds-show");
        }
      }),
      duration
    );
  },

  populateDefaultFieldValues: function (component, event, helper) {
    console.log("NewPatientViewController populateDefaultFieldValues...");

    let patient = component.get("v.patient");
    patient.Service_Type__c = component.get("v.newActivity").Service_Type__c;
    let defaultPreferredPhone = "Mobile";
    patient.npe01__PreferredPhone__c = defaultPreferredPhone;
    component.set("v.patient", patient);
  },

  validateRequiredFields: function (
    component,
    helper,
    sobjectInstance,
    requiredFields
  ) {
    console.log("NewPatientViewController validateRequiredFields...");

    let isValidDates = true;

    if (sobjectInstance.Birthdate) {
      isValidDates = helper.isValidDate(
        component,
        "Birthdate",
        sobjectInstance.Birthdate
      );
    }

    var fieldsStr = "";
    for (var key in requiredFields) {
      if (!sobjectInstance[key]) {
        if (fieldsStr == "") {
          fieldsStr = requiredFields[key];
        } else {
          fieldsStr = fieldsStr + ", " + requiredFields[key];
        }
      }
    }
    if (fieldsStr == "" && isValidDates) {
      return true;
    } else {
      let errorMsgList = component.get("v.errorMessages");
      if (fieldsStr != "") {
        let errorMsg = "Required Fields Missing: " + fieldsStr;
        errorMsgList.push({ type: "error", title: errorMsg });
      }
      component.set("v.errorMessages", errorMsgList);
      return false;
    }
  },

  // Validates that the input string is a valid date formatted as "mm/dd/yyyy"
  isValidDate: function (component, fieldLabel, dateString) {
    console.log("NewPatientViewController isValidDate...");
    // First check for the pattern
    //check that date was properly interpreted by ui:inputDate (should show as yyyy-mm-dd if ui:inputdate knew what you were entering)
    if (!/^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$/.test(dateString)) {
      let errorMsgs = component.get("v.errorMessages");
      let errorStr = fieldLabel + " not in proper format (MM/DD/YYYY). ";
      errorMsgs.push({ type: "error", title: errorStr });
      component.set("v.errorMessages", errorMsgs);
      return false;
    }

    // Parse the date parts to integers
    var parts = dateString.split("-");
    var day = parseInt(parts[2], 10);
    var month = parseInt(parts[1], 10);
    var year = parseInt(parts[0], 10);

    var monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    // Adjust for leap years
    if (year % 400 == 0 || (year % 100 != 0 && year % 4 == 0))
      monthLength[1] = 29;

    // Check the range
    let inRange =
      year > 1000 &&
      year < 3000 &&
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= monthLength[month - 1];
    if (!inRange) {
      let errorStr = fieldLabel + " out of range. ";
      component.get("v.errorMessages").push({ type: "error", title: errorStr });
    }
    return inRange;
  },

  showErrorMessages: function (component) {
    console.log("NewPatientViewController showErrorMessages...");

    let msgs = component.get("v.errorMessages");
    let msgBody = "";
    // let self = this;
    msgs.forEach(function (msg) {
      //this.showCustomToast(component,{'type':msg.type,'title':'Please review the errors in the page.','message': fieldsStr});
      msgBody += "\n" + msg.title;
    });
    this.showCustomToast(component, {
      type: "error",
      title: "Please review errors",
      message: msgBody
    });
    component.set("v.errorMessages", []);
  }
});
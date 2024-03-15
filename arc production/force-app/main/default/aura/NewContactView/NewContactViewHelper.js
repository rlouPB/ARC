({
  toggleSpinner: function (component, duration) {
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
  validateIsRequired: function (component, fields, obj) {
    let errorMessage = component.get("v.errorMessage");

    return Object.keys(fields).reduce(function (validSoFar, field) {
      if (!obj[field]) {
        if (errorMessage === "") {
          errorMessage = fields[field];
        } else {
          errorMessage = errorMessage + ", " + fields[field];
        }
      }
      component.set("v.errorMessage", errorMessage);
      return validSoFar && obj[field];
    }, true);
  },
  showErrorMessage: function (component) {
    this.showCustomToast(component, {
      type: "error",
      title: "Please review the errors in the page.",
      message: "Required fields missing: " + component.get("v.errorMessage")
    });
  },
  setValueBasedOnFieldType: function (obj, apiName, event) {
    if (
      apiName === "Contact" &&
      event.getSource().get("v.fieldName") === "Name"
    ) {
      obj["FirstName"] = event.getParams().firstName;
      obj["LastName"] = event.getParams().lastName;
      obj["salutation"] = event.getParams().salutation;
    }

    if (event.getParams().hasOwnProperty("checked")) {
      obj[event.getSource().get("v.fieldName")] = event.getParam("checked");
    } else {
      obj[event.getSource().get("v.fieldName")] = event.getParam("value");
    }

    return obj;
  },
  saveContactform: function (component, contact, relatedContact, helper) {
    var self = this;
    helper.callApexMethod(
      component,
      "saveContactDetails",
      {
        con: contact,
        relatedContact: relatedContact,
        hasAccount: true,
        serviceType: ""
      },
      function (result) {
        console.log(JSON.stringify(result));
        self.handleSaveSuccess(component, result);
      },
      function (error) {
        self.toggleSpinner(component, 0);
        helper.showCustomToast(component, {
          type: "error",
          title: "Error while saving a record",
          message: error
        });
      }
    );
  },
  handleSaveSuccess: function (component, result) {
    let evt = component.getEvent("closeModalView");

    this.toggleSpinner(component, 0);

    var data = {
      label: result.contactName,
      value: result.contactId
    };
    evt.setParams({
      data: data
    });
    evt.fire();
  }
});
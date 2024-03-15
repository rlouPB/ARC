/* eslint-disable no-unused-expressions */
({
  handleOnError: function (component, event, helper) {
    //RecordEditform error
    var params = event.getParams();
    helper.toggleSpinner(component, 0);
    console.log(params);
  },

  save: function (component, event, helper) {
    helper.toggleSpinner(component, 0);
    let contact = component.get("v.contact"),
      recordTypeName = component.get("v.contactRecordTypeName");

    //empty error message every time save clicked
    component.set("v.errorMessage", "");
    var isContactFieldsValid;
    console.log(JSON.stringify(contact));
    if (recordTypeName === "Professional") {
      //both fields error message show
      isContactFieldsValid = helper.validateIsRequired(
        component,
        { FirstName: "First Name", LastName: "Last Name" },
        contact
      );
    } else {
      //both fields error message show
      isContactFieldsValid = helper.validateIsRequired(
        component,
        { LastName: "Last Name" },
        contact
      );
    }

    if (isContactFieldsValid) {
      helper.saveContact(component, contact, helper);
      //component.find("newContactForm").submit(contact);
    } else {
      helper.toggleSpinner(component, 0);
      helper.showErrorMessage(component);
    }
  },
  onFieldChange: function (component, event, helper) {
    console.log("onFieldChange");
    if (!event) return;
    if (!event.getSource().get("v.fieldName")) return;

    console.log("changing " + event.getSource().get("v.fieldName"));

    let contact = component.get("v.contact"),
      // selectedRecordType =  component.get("v.selectedRecordType"),
      objectApiName = "Contact";

    contact = helper.setValueBasedOnFieldType(contact, objectApiName, event);

    component.set("v.contact", contact);
  },

  onAddressChange: function (component, event, helper) {
    helper.populateStateOptions(component, event, helper);
  },
  cancel: function (component, event, helper) {
    var evt = component.getEvent("closeModalView");
    evt.fire();
  },
  load: function (component, event, helper) {
    var duration = 0;
    helper.showSpinner(component, helper, duration);
    window.setTimeout(
      $A.getCallback(function () {
        helper.hideSpinner(component, helper, duration);
      }),
      duration
    );
  },
  handleError: function (component, event, helper) {
    var params = event.getParams();
    helper.toggleSpinner(component, 0);
  },
  doInit: function (component, event, helper) {
    let searchText = component.get("v.searchText");
    let contact = component.get("v.contact");
    if (searchText && searchText != "") {
      let searchTerms = searchText.split(" ");
      contact.FirstName = searchTerms[0];
      contact.LastName = "";
      if (searchTerms.length >= 3) {
        contact.FirstName += " " + searchTerms[1];
        contact.LastName = searchTerms[2];
      } else if (searchTerms.length == 2) {
        contact.LastName = searchTerms[1];
      }
    }
    component.set("v.contact", contact);
    helper.populateDefaultFieldValues(component, event, helper);
    helper.populateStateCountryOptions(component, event, helper);
  }
});
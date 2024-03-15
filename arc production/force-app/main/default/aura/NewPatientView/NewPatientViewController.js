({
  doInit: function (component, event, helper) {
    console.log("NewPatientViewController doInit...");

    let serviceType = component.get("v.newActivity").Service_Type__c;

    let searchText = component.get("v.searchText");

    if (searchText && searchText != "") {
      let searchTerms = searchText.split(" ");

      let patient = component.get("v.patient");
      patient.FirstName = searchTerms[0];
      patient.LastName = "";
      patient.Service_Type__c = serviceType;

      if (searchTerms.length >= 3) {
        patient.FirstName += " " + searchTerms[1];
        patient.LastName = searchTerms[2];
      } else if (searchTerms.length == 2) {
        patient.LastName = searchTerms[1];
      }
      component.set("v.patient", patient);
    }

    helper.populateDefaultFieldValues(component, event, helper);

    // component.set("v.newActivity", newActivity.Service_Type__c);
    // component.set("v.newActivity", newActivity);

    //To get Related contact recordType
    helper.callApexMethod(
      component,
      "getContactRecordTypeDetails",
      null,
      function (result) {
        let contactRecordTypes = (collection) => {
          return collection
            .filter((record) => record.Name == "Patient")
            .map((record) => {
              let recordMap = { label: record.Name, value: record.Id };
              return recordMap;
            });
        };

        const relatedContactRecordTypeList = contactRecordTypes(
          result.relatedContactRecordTypes
        );
        component.set(
          "v.relatedContactRecordType",
          relatedContactRecordTypeList[0]
        );
      },
      function (error) {
        helper.showCustomToast(component, { type: "error", title: error });
      }
    );
  },

  load: function (component, event, helper) {
    console.log("NewPatientViewController load...");

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
    console.log("NewPatientViewController handleError...");
    var params = event.getParams();
    helper.toggleSpinner(component, 0);
  },

  onFieldChange: function (component, event, helper) {
    console.log("NewPatientViewController onFieldChange...");
    let relatedContact = component.get("v.relatedContact");

    if (event.getParams().hasOwnProperty("checked")) {
      relatedContact[event.getSource().get("v.fieldName")] =
        event.getParam("checked");
    } else {
      relatedContact[event.getSource().get("v.fieldName")] =
        event.getParam("value");
    }
    component.set("v.relatedContact", relatedContact);
  },

  updatePatientName: function (component, event, helper) {
    console.log("NewPatientViewController updatePatientName...");
    var inputCmp = event.getSource();
    var inputId = inputCmp.get("v.name");
    component.find(inputId).set("v.value", inputCmp.get("v.value"));
  },

  setPatientModel: function (component, event, helper) {
    console.log("NewPatientViewController setPatientModel...");
    var patient = component.get("v.patient");
    var inputCmp = event.getSource();

    if (inputCmp.get("v.fieldName") === "Name") {
      patient["FirstName"] = event.getParams().firstName;
      patient["LastName"] = event.getParams().lastName;
      patient["salutation"] = event.getParams().salutation;
    }

    if (event.getParams().hasOwnProperty("checked")) {
      patient[inputCmp.get("v.fieldName")] = event.getParam("checked");
    } else {
      patient[inputCmp.get("v.fieldName")] = event.getParam("value");
    }

    component.set("v.patient", patient);
  },

  initializeForm: function (component, event, helper) {
    console.log("NewPatientViewController initializeForm...");
    let relatedContact = component.get("v.relatedContact");
    relatedContact["Role__c"] = component.find("role").get("v.value");
    component.set("v.relatedContact", relatedContact);
  },

  save: function (component, event, helper) {
    console.log("NewPatientViewController save...");
    helper.toggleSpinner(component, 0);
    var patient = component.get("v.patient");
    var newActivity = component.get("v.newActivity");
    var relatedContact = component.get("v.relatedContact");
    var relatedContactRecordType = component.get("v.relatedContactRecordType");
    var showSpinner = false;
    //var requiredFieldsForRelatedContact = {'Role__c' : 'Role'};
    var requiredFieldsForPatient = { LastName: "LastName" };

    relatedContact.RecordTypeId = relatedContactRecordType.value || "";
    var isRelatedValid = true; //helper.validateRequiredFields(component, relatedContact, requiredFieldsForRelatedContact);
    var isPatientValid = helper.validateRequiredFields(
      component,
      helper,
      patient,
      requiredFieldsForPatient
    );

    if (isRelatedValid && isPatientValid) {
      helper.callApexMethod(
        component,
        "saveContactDetails",
        {
          con: patient,
          relatedContact: relatedContact,
          hasAccount: false,
          serviceType: newActivity.Service_Type__c
        },
        function (response) {
          helper.toggleSpinner(component, 0);

          var evt = component.getEvent("closeModalView");
          evt.setParams({
            data: { label: response.accountName, value: response.accountId }
          });
          evt.fire();
        },
        function (error) {
          helper.showCustomToast(component, { type: "error", title: error });
          helper.toggleSpinner(component, 0);
        },
        showSpinner
      );
    } else {
      helper.toggleSpinner(component, 0);
      helper.showErrorMessages(component);
    }
  },

  cancel: function (component, event, helper) {
    var evt = component.getEvent("closeModalView");
    evt.fire();
  },

  handleChangeServiceType: function (component, event) {
    console.log("NewPatientViewController handleChangeServiceType...");
    var selectedOptionValue = event.getParam("value");
    component.set("v.serviceType", selectedOptionValue);
  }
});
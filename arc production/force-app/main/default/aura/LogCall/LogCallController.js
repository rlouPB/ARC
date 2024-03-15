({
  doInit: function (component, event, helper) {
    var recordId = component.get("v.recordId");

    if (recordId) {
      component.set("v.patientIsSelected", true);
    }

    var params = helper.parseURL();
    if (params && params.noteId) {
      component.set("v.noteId", params.noteId);
      helper.getActivityByNoteId(component, params.noteId, helper);
    } else {
      helper.resetNewActivity(component);
    }

    helper.setCallerOptions(component, recordId);
    helper.setProfessionalContactOptions(component);
    helper.setPatientOptions(component);
    helper.setSubjectFilter(component);
    helper.initializeRequiredFields(component, event, helper);
    helper.getContactRecordTypeDetails(component, event, helper);
  },

  doneScriptsLoading: function (component, event, helper) {
    component.set("v.loading", false);
  },

  saveActionLogCall: function (component, event, helper) {
    if (component.get("v.patientIsSelected") && component.get("v.callerIsSelected")) {
      component.set("v.hasCheckedForRelationship", false);
      helper.checkForRelationship(component, event, helper, helper.autoSaveRelationshipCallback);
    } else {
      helper.saveActionLogCall(component, event, helper);
    }
  },

  callerIsPatient: function (component, event, helper) {
    var newActivity = component.get("v.newActivity");
    component.set("v.isSaveDisabled", true);

    if (newActivity 
    && newActivity.Account__c 
    && helper.isValidAccountId(newActivity.Account__c)) {
      helper.callApexMethod(
        component,
        "getPatientDetails",
        { patientId: newActivity.Account__c },
        function (result) {
          newActivity.Contact__c = result.Id;
          // newActivity.Service_Type__c = "Residential";

          var contactLookupCheck = component.find("contactLookup");
          var contactLookup;
          if (Array.isArray(contactLookupCheck)) {
            contactLookup = contactLookupCheck[0];
          } else {
            contactLookup = contactLookupCheck;
          }

          if (contactLookup) {
            // var displayField = contactLookup.get("v.displayField") || '';

            // if(!result[displayField]) {
            //     displayField = 'Distinguished_Name__c';
            // }
            var selectedCallerRecord = {};
            selectedCallerRecord.label = result.Distinguished_Name__c;
            selectedCallerRecord.value = result.Id;
            selectedCallerRecord.isRecord = true;

            contactLookup.setSelectedRecord(selectedCallerRecord);
          }

          component.set("v.newActivity", newActivity);
        },
        null
      );
    } else if (newActivity && newActivity.Account__c) {
      newActivity.Contact__c = newActivity.Account__c;

      var contactLookup = component.find("contactLookup");

      if (contactLookup) {
        contactLookup.setLookupFieldName(newActivity.Contact__c);
      }
      component.set("v.newActivity", newActivity);
    }
    helper.checkForRelationship(component, event, helper, helper.autoSaveRelationshipCallback, true, true);
  },

  onNowClick: function (component, event, helper) {
    let newDatetimeValue = moment().format("YYYY-MM-DDTHH:mm:ss");

    var newActivity = component.get("v.newActivity");
    newActivity.Call_Date_Time__c = newDatetimeValue;

    component.set("v.lastNowValue", newDatetimeValue);
    component.set("v.dateTimeSetByNow", true);

    component.set("v.newActivity", newActivity);
    helper.enableSaveButton(component, false);
    helper.setAutosaveOn(component, event, helper);
  },

  handleChangeNote: function (component, event, helper) {
    let expr = event.getParam("expression");
    let newValue = event.getParam("value");
    let oldValue = event.getParam("oldValue");
    var obj = component.get("v.newActivity");

    helper.setPatientOptions(component);

    //if datetime doesn't match what the Now button did, reset Utc
        if (component.get("v.dateTimeSetByNow") && obj.Call_Date_Time__c != component.get("v.lastNowValue")) {
      component.set("v.dateTimeSetByNow", false);
      component.set("v.lastNowValue", "");
    }

    switch (expr) {
      case "v.newActivity.Call_Type__c":
        if (newValue == "Non-Starter")
          helper.addRequiredField(component, "Non_starter_Reason__c", "Non-starter Reason");
        else
          helper.removeRequiredField(component, "Non_starter_Reason__c", "Non-starter Reason");
        break;

      case "v.newActivity.Call_Status__c":
        if (newValue == "Completed") {
          helper.addRequiredField(component, "Call_Type__c", "Call Type");
          helper.checkContactLookupRequired(component, obj);
        } else {
          helper.removeRequiredField(component, "Call_Type__c", "Call Type");
          // helper.removeRequiredField(component, 'Caller_Name__c', 'Person Spoken To');
        }
        break;

      case "v.newActivity.Account__c":
        if (newValue && newValue != oldValue && !newValue.startsWith("001")) {
          component.set("v.patientSearchText", newValue);
        }

        break;

      case "v.newActivity.Contact__c":
        if (newValue && newValue != oldValue && !newValue.startsWith("003")) {
          component.set("v.callerSearchText", newValue);
        }

        break;
    }
    //replace entire object, save is disabled
    if (expr === "v.newActivity") {
      helper.enableSaveButton(component, true);
    } else { //change a field
      helper.enableSaveButton(component, false);
      helper.setAutosaveOn(component, event, helper);
    }
  },

  handleChangeType: function (component, event) {
    var selectedOptionValue = event.getParam("value");
    component.set("v.callType", selectedOptionValue);
  },

  enableSaveButton: function (component, event, helper) {
    helper.enableSaveButton(component, false);
    helper.setAutosaveOn(component, event, helper);
  },

  patientRecordChange: function (component, event, helper) {
    component.set("v.hasCheckedForRelationship", false);
    var selectedPatientRecord = component.get("v.selectedPatientRecord");
    if (selectedPatientRecord && selectedPatientRecord.value && selectedPatientRecord.value.startsWith("001")) {
      component.set("v.patientIsSelected", true);
      helper.setCallerOptions(component, selectedPatientRecord.value);
      component.set("v.patientSearchText", selectedPatientRecord.label);

      var obj = component.get("v.newActivity");
      helper.checkContactLookupRequired(component, obj);
    } else {
      // helper.removeRequiredField(component, 'Caller_Name__c', 'Person Spoken To');
      component.set("v.patientIsSelected", false);
    }

    helper.checkForRelationship(component, event, helper, helper.autoSaveRelationshipCallback, true, true);
  },

  callerRecordChange: function (component, event, helper) {
        component.set("v.hasCheckedForRelationship", false);

    var selectedCallerRecord = component.get("v.selectedCallerRecord");

    if (selectedCallerRecord && selectedCallerRecord.value && selectedCallerRecord.value.startsWith("003")) {
      component.set("v.callerIsSelected", true);
      // newActivity.Caller_Name__c = selectedCallerRecord.label;

      var relatedContact = component.get("v.relatedContact");
      relatedContact.Contact__c = selectedCallerRecord.value;
      component.set("v.relatedContact", relatedContact);
    } else {
      component.set("v.callerIsSelected", false);
      var newActivity = component.get("v.newActivity");
      if (newActivity.Contact__c && newActivity.Contact__c.length == 18 && newActivity.Contact__c.startsWith("003")) {
        newActivity.Contact__c = "";
      }
      component.set("v.newActivity", newActivity);

      component.set("v.relatedContact", { sobjectType: "Related_Contact__c" });
    }

    helper.checkForRelationship(component, event, helper, helper.autoSaveRelationshipCallback, true, true);
  },

  handlePopulateLogACall: function (component, event, helper) {

    const noteId = event.getParam("noteId"),
      noteRecordtypeName = event.getParam("noteRecordtypeName"),
      isFromCallSearch = event.getParam("isFromCallSearch"),
      recordId = component.get("v.recordId");
        if ((!noteRecordtypeName || noteRecordtypeName == component.get("v.noteRecordtypeName")) && isFromCallSearch) {
      if (component.get("v.isSaveDisabled")) {
        if (noteId) helper.getActivityByNoteId(component, noteId, helper);
        else helper.resetNewActivity(component, true);
        if (recordId) {
          //helper.setCallerOptions(component,recordId);
        }
        component.set("v.isSaveDisabled", true);
      } else {
        component.set("v.showStartNewCallModal", true);
        component.set("v.modalFromCallSearchId", noteId);
      }
    }
  },

  onStartNewCall: function (component, event, helper) {
    if (!component.get("v.isSaveDisabled")) {
      component.set("v.showStartNewCallModal", true);
      component.set("v.modalFromCallSearchId", "");
    } else {
      helper.resetNewActivity(component, true);
      component.set("v.isSaveDisabled", true);
      component.set("v.isAutosaveComplete", false);
      helper.setAutosaveOff(component, event, helper);
    }
  },

  onStartNewActionClick: function (component, event, helper) {

    const localId = event.getSource().getLocalId(),
      modalFromCallSearchId = component.get("v.modalFromCallSearchId");

    if (localId === "savechanges") {
      component.set("v.noReloadOnSave", true);
      component.set("v.isSaveDisabled", true);
      helper.saveActionLogCall(component, event, helper, modalFromCallSearchId);
    } else if (localId === "throwawaychanges") {
      component.set("v.isSaveDisabled", true);
      helper.resetNewActivity(component, true);
    }

    if (modalFromCallSearchId != "") {
      helper.getActivityByNoteId(component, modalFromCallSearchId, helper);
    }
    component.set("v.showStartNewCallModal", false);
    component.set("v.modalFromCallSearchId", "");
  },

  handleCloseModal: function (component, event, helper) {
    var data = event.getParams();
    if (data.data && data.data.value) {
      let newActivity = component.get("v.newActivity");
      var wasCompleted = component.get("v.wasCompleted");
      if (newActivity.Call_Status__c === "Logged" && wasCompleted) {
        newActivity.Call_Status__c = "Completed";
        component.set("v.newActivity", newActivity);
      }

      component.set("v.wasCompleted", false);
      component.set("v.hasCheckedForRelationship", true);
      component.set("v.hasRelationship", true);
      helper.checkForRelationship(component, event, helper, helper.autoSaveRelationshipCallback, false);
    } else {
      component.set("v.isSaveDisabled", false);
    }
  }
});
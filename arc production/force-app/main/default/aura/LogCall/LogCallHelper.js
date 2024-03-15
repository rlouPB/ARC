({
  parseURL: function () {
    var url = window.location.href,
      params = {},
      match;
    var regex = new RegExp("[?&]" + "c__noteId" + "(=([^&#]*)|&|#|$)");

    var results;
    if (regex.exec(url) != null) {
      results = regex.exec(url);
    }

    if (!results) return null;

    if (!results[2]) return "";

    if (results[2]) {
      params.noteId = decodeURIComponent(results[2].replace(/\+/g, " "));
    }

    return params;
  },

  getActivityByNoteId: function (component, noteId, helper) {
    console.log("LogCallHelper getActivityByNoteId...");

    component.set("v.isNoteLoaded", false);

    helper.callApexMethod(
      component,
      "getPatientNoteDetails",
      { patientNoteId: noteId },
      function (result) {
        var newActivity = result;
        if (newActivity && newActivity.RecordType.Name == "Admissions Notes") {
          // component.set("v.isComponentLoaded",false);
          let isPatientPicked = helper.isValidAccountId(newActivity.Account__c);
          let recordId = component.get("v.recordId");

          //if patient picked but not currently displaying patient file page, redirect right now
          if (isPatientPicked && !recordId) {
            helper.redirectToPatient(newActivity.Account__c, newActivity.Id);
            return;

            //else if displaying Patient File page
          } else if (recordId) {
            //else if patient not picked, just populate search text from Patient Name field
          } else {
            component.set("v.patientSearchText", newActivity.Patient_Name__c);

            //This looks weird, but it is required by LookupComponent.
            //LookupComponent uses the same field to read search text and to populate the result
            //So, if Account__c is populated with an account Id, it should stay that way.
            //But if it's blank in the record, it should be temporarily populated with the patient name text.
            //This will be fixed before sending back to Salesforce.
            //TODO: Fix lookupComponent to allow using in a more convenient way when you want to save both the search text AND the record Id

            newActivity.Account__c = newActivity.Patient_Name__c;
          }

          //if contact picked, fill pill
          if (newActivity.Contact__c) {
            var selectedCallerRecord = {};
            selectedCallerRecord.label =
              newActivity.Contact__r.Distinguished_Name__c || "";
            selectedCallerRecord.value = newActivity.Contact__c;
            selectedCallerRecord.isRecord = true;
            component.set("v.selectedCallerRecord", selectedCallerRecord);
          } //no contact picked, populate search text
          else {
            newActivity.Contact__c = newActivity.Caller_Name__c;
            var contactLookup = component.find("contactLookup");
            if (contactLookup) {
              contactLookup.setLookupFieldName(newActivity.Contact__c);
            }
            component.set("v.callerSearchText", newActivity.Caller_Name__c);
          }

          // if(!newActivity.Subject)
          // {
          //     newActivity.Subject = '';
          // }

          component.set("v.newActivity", newActivity);
          component.set("v.isNoteLoaded", true);
        }
      },
      null,
      true
    );
  },

  redirectToPatient: function (accountId, noteId) {
    console.log("LogCallHelper redirectToPatient...");
    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      url: "/lightning/r/Account/" + accountId + "/view?c__noteId=" + noteId
    });
    urlEvent.fire();
  },

  isValidAccountId: function (recordId) {
    console.log("LogCallHelper isValidAccountId...");
    if (!recordId) {
      return false;
    }

    var prefix = recordId.substring(0, 3);
    return (
      prefix === "001" && (recordId.length === 15 || recordId.length === 18)
    );
  },

  isValidContactId: function (recordId) {
    console.log("LogCallHelper isValidContactId...");
    if (!recordId) {
      return false;
    }

    var prefix = recordId.substring(0, 3);

    return (
      prefix === "003" && (recordId.length === 15 || recordId.length === 18)
    );
  },

  showMyToast: function (component, event, message, type, sec) {
    console.log("LogCallHelper showMyToast...");
    let toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      mode: "sticky",
      message: message,
      duration: sec,
      type: type
    });
    toastEvent.fire();
  },

  initializeRequiredFields: function (component, event, helper) {
    console.log("LogCallHelper initializeRequiredFields...");
    let reqFieldMap = {
      Call_Date_Time__c: { label: "Call Date/Time", required: true },
      Call_Method__c: { label: "Call Method", required: true },
      Call_Status__c: { label: "Call Status", required: true },
      Account__c: { label: "Patient Name", required: true },
      Contact__c: { label: "Person Spoken To", required: true }
    };
    component.set("v.requiredFields", reqFieldMap);
  },

  checkContactLookupRequired: function (component, obj) {
    console.log("LogCallHelper checkContactLookupRequired...");
    // the call must be both Completed and have a Patient record selected
    var isPass = true;
    if (!obj.Account__c || !this.isValidAccountId(obj.Account__c))
      isPass = false;
    if (!obj.Call_Status__c || obj.Call_Status__c != "Completed")
      isPass = false;

    let fields = component.get("v.requiredFields");
  },

  addRequiredField: function (component, fieldName, fieldLabel) {
    console.log("LogCallHelper addRequiredField...");
    let reqFieldMap = component.get("v.requiredFields");
    reqFieldMap[fieldName] = { label: fieldLabel, required: true };
    component.set("v.requiredFields", reqFieldMap);
  },

  removeRequiredField: function (component, fieldName, fieldLabel) {
    console.log("LogCallHelper removeRequiredField...");
    let reqFieldMap = component.get("v.requiredFields");
    reqFieldMap[fieldName] = { label: fieldLabel, required: false };
    component.set("v.requiredFields", reqFieldMap);
  },

  validateRequiredFields: function (component, helper, obj) {
    console.log("LogCallHelper validateRequiredFields...");
    if (!obj) {
      component.set("v.Errormsg", "No record to validate! Contact support.");
      return false;
    }

    let fields = component.get("v.requiredFields");
    let errorMessage = "";

    let isRequiredFieldsValid = Object.keys(fields).reduce(function (
      validSoFar,
      field
    ) {
      if (fields[field].required) {
        var isPass = obj[field] ? true : false;
        if (!isPass) {
          if (errorMessage === "") {
            errorMessage = fields[field].label;
          } else {
            errorMessage = errorMessage + ", " + fields[field].label;
          }
          component.set("v.Errormsg", errorMessage);
        }
        return validSoFar && isPass;
      } else {
        return validSoFar;
      }
    },
    true);

    return isRequiredFieldsValid;
  },

  enableSaveButton: function (component, isDisabled) {
    console.log("LogCallHelper enableSaveButton...");
    let isComponentLoaded = component.get("v.isComponentLoaded");
    if (isComponentLoaded) {
      component.set("v.isSaveDisabled", isDisabled);
    }
  },

  setCallerOptions: function (component, recordId) {
    console.log("LogCallHelper setCallerOptions...");
    var callerAdditionalOptions = [
      {
        label: "Create Relationship",
        value: "newContact",
        isRecord: false,
        componentName: "c:newRelatedContactRecord",
        attr: {
          recordId: recordId
        }
      }
    ];
    var callerFilter = [
      {
        fieldName: "Account__c",
        condition: "=",
        value: recordId
      }
    ];

    component.set("v.callerFilter", callerFilter);
    component.set("v.callerAdditionalOptions", callerAdditionalOptions);
  },

  setSubjectFilter: function (component) {
    console.log("LogCallHelper setSubjectFilter...");
    var subjectFilter = [
      {
        fieldName: "Field__c",
        condition: "=",
        value: "Basic_Note__c.Subject__c"
      }
    ];

    component.set("v.subjectFilter", subjectFilter);
  },

  setProfessionalContactOptions: function (component) {
    console.log("LogCallHelper setProfessionalContactOptions...");
    var recordId = component.get("v.recordId");
    var professionalContactFilter = [
      {
        fieldName: "RecordType.Name",
        condition: "=",
        value: "Professional"
      }
    ];
    var professionalContactAdditionalOptions = [
      {
        label: "Create Professional Contact",
        value: "newContact",
        isRecord: false,
        componentName: "c:NewBasicContact",
        attr: {
          contactRecordTypeName: "Professional"
        }
      }
    ];

    component.set("v.professionalContactFilter", professionalContactFilter);
    component.set(
      "v.professionalContactAdditionalOptions",
      professionalContactAdditionalOptions
    );
  },

  setPatientOptions: function (component) {
    console.log("LogCallHelper setPatientOptions...");
    var recordId = component.get("v.recordId");
    var patientFilter = [
      {
        fieldName: "Patient__r.RecordType.Name",
        condition: "=",
        value: "Patient"
      }
    ];

    var patientAdditionalOptions = [
      {
        label: "Advanced Search",
        value: "advanceSearch",
        isRecord: false,
        componentName: "c:AdvancedSearchView",
        attr: {
          context: "patient"
        }
      },
      {
        label: "Create New Patient",
        value: "newPatient",
        isRecord: false,
        componentName: "c:NewPatientView",
        attr: {
          newActivity: component.get("v.newActivity")
        }
      }
    ];

    component.set("v.patientFilter", patientFilter);
    component.set("v.patientAdditionalOptions", patientAdditionalOptions);
  },

  fetchAccountServiceType: function (recordId) {
    console.log("LogCallHelper fetchAccountServiceType...");
    var action = component.get("c.getAccountServiceTyoe");
    action.setParams({
      patientId: recordId
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        if (!checkOnly) {
          successCallback(component, event, helper, response.getReturnValue());
        } else {
          //  component.set("v.hasRelationship", response.getReturnValue());
        }
      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("Error message: " + errors[0].message);
          }
        } else {
          console.log("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  },

  resetNewActivity: function (component) {
    console.log("LogCallHelper resetNewActivity...");
    // let newActivity = component.get("v.newActivity"),
    //     patientNote = component.get("v.patientNote"),
    var recordId = component.get("v.recordId");
    // helper.fetchAccountServiceType(recordId);

    let isStandalone = component.get("v.formFactor") == "LARGE";
    var newActivity = {
      sobjectType: "Basic_Note__c",
      Call_Date_Time__c: "",
      Calling_Number__c: "",
      Call_Method__c: "",
      Call_Type__c: "",
      Call_Status__c: "Logged",
      Non_starter_Reason__c: "",
      Patient_City__c: "",
      Caller_Gender__c: "",
      Patient_State__c: "",
      Patient_Country__c: "",
      Caller_Country__c: "",
      Patient_Gender__c: "",
      Length_of_Call__c: "",
      Subject__c: "",
      Service_Type__c: "Residential",
      Caller_Affect_and_Presentation__c: ""
    };
    var patientLookup = component.find("patientLookup");

    if (recordId) {
      newActivity.Account__c = recordId;
      newActivity.Call_Type__c = "Inquiry";
      // newActivity.Service_Type__c = component.get("v.serviceType");
    } else {
      if (patientLookup) {
        patientLookup.closePill();
      }
    }

    var contactLookup = component.find("contactLookup");
    if (contactLookup) {
      contactLookup.closePill();
    }

    var subjectLookup = component.find("subjectLookup");
    if (subjectLookup) {
      subjectLookup.closePill();
    }

    var patientNote = {
      Caller_Affect_and_Presentation__c: ""
      // ,
      // 'Text_Narrative_Notes__c':''
    };

    component.set("v.newActivity", newActivity);
    component.set("v.patientNote", patientNote);
    component.set("v.patientSearchText", "");
    component.set("v.callerSearchText", "");
    component.set("v.serviceType", "Residential");
    component.set("v.isNoteLoaded", true);
  },

  setAutosaveOn: function (component, event, helper) {
    console.log("LogCallHelper setAutosaveOn...");
    if (!component.get("v.autosaveId") && !component.get("v.isSaveDisabled")) {
      component.set(
        "v.autosaveId",
        window.setInterval(
          $A.getCallback(function () {
            helper.autosaveDraft(component, event, helper);
          }),
          component.get("v.autosaveInterval")
        )
      );
    }
  },

  setAutosaveOff: function (component, event, helper) {
    console.log("LogCallHelper setAutosaveOff...");

    window.clearInterval(component.get("v.autosaveId"));
    component.set("v.autosaveId", null);
  },

  autosaveDraft: function (component, event, helper) {
    console.log("LogCallHelper autosaveDraft...");

    if (
      component.get("v.isComponentLoaded") &&
      !component.get("v.isSaveDisabled")
    ) {
      let lastSuccessfulSaveTime = component.get("v.lastSuccessfulSaveTime");
      let previousSaveLockoutLength = component.get(
        "v.previousSaveLockoutLength"
      );

      let timeSinceLastSave = lastSuccessfulSaveTime
        ? (lastSuccessfulSaveTime.diff() / 1000) * -1
        : null;
      //if (component.get('v.loading') || component.get('v.isAutosaving'))
      if (timeSinceLastSave && timeSinceLastSave < previousSaveLockoutLength) {
        console.log(
          "save already in progress. Draft save aborted. Last save: " +
            moment(lastSuccessfulSaveTime) +
            " (" +
            timeSinceLastSave +
            " seconds ago)"
        );
        return;
      }
      // let modalFromCallSearchId = component.get('v.modalFromCallSearchId');
      let newActivity = component.get("v.newActivity");

      if (
        newActivity.Rich_Text_Notes__c &&
        newActivity.Rich_Text_Notes__c.length >
          component.get("v.autosaveMinimumNoteLength")
      ) {
        helper.checkForRelationship(
          component,
          event,
          helper,
          helper.autoSaveRelationshipCallback,
          true
        );
      }
    } else {
      helper.setAutosaveOff(component, event, helper);
    }
  },

  saveActionLogCall: function (
    component,
    event,
    helper,
    modalFromCallSearchId,
    isDraftSave
  ) {
    console.log("LogCallHelper saveActionLogCall...");
    var newActivity = component.get("v.newActivity"),
      patientNote = component.get("v.patientNote"),
      recordId = component.get("v.recordId");

    component.set("v.isAutosaveComplete", false);

    if (isDraftSave) {
      component.set("v.isAutosaving", true);
    } else {
      component.set("v.isSaving", true);
    }

    //if datetime set by now, need to adjust time zone
    if (component.get("v.dateTimeSetByNow")) {
      let callDateTime = moment(newActivity.Call_Date_Time__c)
        .tz("UTC")
        .format();
      newActivity.Call_Date_Time__c = callDateTime;
    }

    var recordExists = !$A.util.isUndefinedOrNull(newActivity);
    var fieldsValidated = this.validateRequiredFields(
      component,
      helper,
      newActivity
    );

    isDraftSave = isDraftSave ? true : false;
    var passedValidation = recordExists && (isDraftSave || fieldsValidated);

    if (passedValidation) {
      var accountId = recordId;
      if (helper.isValidAccountId(newActivity.Account__c)) {
        accountId = newActivity.Account__c;
      } else {
        newActivity.Patient_Name__c = component.get("v.patientSearchText");
        newActivity.Account__c = null;
      }

      if (!helper.isValidContactId(newActivity.Contact__c)) {
        newActivity.Caller_Name__c = component.get("v.callerSearchText");
        newActivity.Contact__c = null;
      }

      component.set(
        "v.saveAttemptCount",
        component.get("v.saveAttemptCount") + 1
      );

      helper.enableSaveButton(component, true);
      var showToast = true;
      this.hideCustomToast(component);

      this.callApexMethod(
        component,
        "createLogCall",
        {
          patientNoteStr: JSON.stringify(newActivity),
          accountId: accountId,
          isDraftSave: isDraftSave
        },
        function (result) {
          var message;
          if (newActivity.Id) {
            message = "Admission Call has been updated successfully.";
          } else {
            message = "Admission Call has been created successfully.";
          }

          var patientIsSelected = component.get("v.patientIsSelected");
          var callerIsSelected = component.get("v.callerIsSelected");
          var hasRelationship = component.get("v.hasRelationship");

          if (patientIsSelected && callerIsSelected) {
            var selectedPatientRecord = component.get(
              "v.selectedPatientRecord"
            );
            var selectedCallerRecord = component.get("v.selectedCallerRecord");
            var patientId;

            if (recordId) {
              patientId = recordId;
            }

            if (selectedPatientRecord && selectedPatientRecord.value) {
              patientId = selectedPatientRecord.value;
            }

            if (patientId && selectedCallerRecord.value && !hasRelationship) {
              component.set("v.patientId", patientId);
              component.set("v.showCreateRelationshipModal", true);
              showToast = false;
            }
          }

          if (recordId) {
            //Fire to refresh call search
            $A.get("e.c:onPopulateLogACall")
              .setParams({ noteId: null, isFromCallSearch: false })
              .fire();
          }

          if (!component.get("v.noReloadOnSave")) {
            if (!result.Account__c)
              newActivity.Account__c = result.Patient_Name__c;
            if (!result.Contact__c)
              newActivity.Contact__c = result.Caller_Name__c;
            newActivity.Id = result.Id;
            newActivity.LastModifiedDate = result.LastModifiedDate;
            newActivity.LastModifiedBy = result.LastModifiedBy;
            newActivity.Auto_Saved__c = result.Auto_Saved__c;

            if (recordId) {
              let evt = $A.get("e.c:refreshPatient");
              evt.fire();
            } else if (!isDraftSave) {
              var isValidAcctId = helper.isValidAccountId(
                newActivity.Account__c
              );
              if (isValidAcctId && hasRelationship) {
                // console.log(
                //   "urlEvent",
                //   "/lightning/r/Account/" +
                //     newActivity.Account__c +
                //     "/view?c__noteId=" +
                //     newActivity.Id
                // );
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                  url:
                    "/lightning/r/Account/" +
                    newActivity.Account__c +
                    "/view?c__noteId=" +
                    newActivity.Id
                });
                urlEvent.fire();
              }
            }
            component.set("v.newActivity", newActivity);
            component.set("v.patientNote", patientNote);
          } else if (modalFromCallSearchId == "") {
            helper.resetNewActivity(component, true);
          }

          let timeStamp = moment();

          component.set("v.noReloadOnSave", false);
          component.set("v.loading", false);
          component.set("v.isAutosaving", false);
          component.set("v.isSaving", false);
          component.set("v.lastSuccessfulSaveTime", timeStamp);
          component.set("v.saveAttemptCount", 0);
          if (isDraftSave) {
            component.set("v.isAutosaveComplete", true);
          } else {
            if (showToast) {
              component.find("notifLib").showToast({
                title: "Success!",
                message: message
              });
            }
          }
        },
        function (error) {
          helper.showCustomToast(component, {
            type: "error",
            title: "Error while saving a record",
            message: error
          });
          component.set("v.loading", false);
          helper.enableSaveButton(component, false);
        },
        false
      );
    } else {
      this.showCustomToast(component, {
        type: "error",
        title: "Please review the errors in the page.",
        message: "Required fields missing: " + component.get("v.Errormsg")
      });

      component.set("v.loading", false);
    }
  },

  checkForRelationship: function (
    component,
    event,
    helper,
    successCallback,
    isDraft,
    checkOnly
  ) {
    console.log("LogCallHelper checkForRelationship...");
    var patientIsSelected = component.get("v.patientIsSelected");
    var callerIsSelected = component.get("v.callerIsSelected");
    var hasCheckedForRelationship = component.get(
      "v.hasCheckedForRelationship"
    );
    if (isDraft) {
      isDraft = true;
    } else {
      isDraft = false;
    }
    if (checkOnly) {
      checkOnly = true;
    } else {
      checkOnly = false;
    }
    if (patientIsSelected && callerIsSelected) {
      if (!hasCheckedForRelationship) {
        var selectedPatientRecord = component.get("v.selectedPatientRecord");
        var selectedCallerRecord = component.get("v.selectedCallerRecord");
        var recordId = component.get("v.recordId");

        var patientId;

        if (recordId) {
          patientId = recordId;
        }

        if (selectedPatientRecord && selectedPatientRecord.value) {
          patientId = selectedPatientRecord.value;
        }

        if (patientId && selectedCallerRecord.value) {
          var action = component.get("c.hasRelationship");
          action.setParams({
            patientId: patientId,
            contactId: selectedCallerRecord.value
          });
          action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
              if (!checkOnly) {
                successCallback(
                  component,
                  event,
                  helper,
                  response.getReturnValue()
                );
              } else {
                component.set("v.hasRelationship", response.getReturnValue());
                component.set("v.hasCheckedForRelationship", true);
              }
            } else if (state === "INCOMPLETE") {
              // do something
            } else if (state === "ERROR") {
              var errors = response.getError();
              if (errors) {
                if (errors[0] && errors[0].message) {
                  console.log("Error message: " + errors[0].message);
                }
              } else {
                console.log("Unknown error");
              }
            }
          });
          $A.enqueueAction(action);
        }
      } else {
        if (!checkOnly) {
          var hasRelationship = component.get("v.hasRelationship");
          helper.autoSaveRelationshipCallback(
            component,
            event,
            helper,
            hasRelationship,
            isDraft
          );
        }
      }
    } else {
      // set relationship to true if there isn't both patient and caller
      component.set("v.hasRelationship", true);

      if (!checkOnly) {
        var hasRelationship = component.get("v.hasRelationship");
        helper.autoSaveRelationshipCallback(
          component,
          event,
          helper,
          hasRelationship,
          isDraft
        );
      }
    }
  },

  autoSaveRelationshipCallback: function (
    component,
    event,
    helper,
    hasRelationship,
    isDraft
  ) {
    console.log("LogCallHelper autoSaveRelationshipCallback...");
    let modalFromCallSearchId = component.get("v.modalFromCallSearchId");
    component.set("v.hasCheckedForRelationship", true);
    component.set("v.hasRelationship", hasRelationship);

    if (!hasRelationship) {
      let newActivity = component.get("v.newActivity");
      if (newActivity.Call_Status__c === "Completed") {
        component.set("v.wasCompleted", true);
        newActivity.Call_Status__c = "Logged";
        component.set("v.newActivity", newActivity);
      }
    }

    helper.saveActionLogCall(
      component,
      event,
      helper,
      modalFromCallSearchId,
      isDraft
    );
  },

  closeRelationshipModal: function (component, event, helper) {
    console.log("LogCallHelper closeRelationshipModal...");
    var closeEvent = component.getEvent("closeModalEvent");

    var data = {
      instanceName: "createRelationship"
    };
    closeEvent.setParams({
      data: data
    });
    closeEvent.fire();
  },

  getContactRecordTypeDetails: function (component, event, helper) {
    console.log("LogCallHelper getContactRecordTypeDetails...");
    var action = component.get("c.getContactRecordTypeDetails");
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        let contactRecordTypes = (collection) => {
          return collection
            .filter((record) => record.Name != "Patient")
            .map((record) => {
              let recordMap = { label: record.Name, value: record.Id };
              return recordMap;
            });
        };

        const contactRecordTypeList = contactRecordTypes(
          result.contactRecordTypes
        );
        const relatedContactRecordTypeList = contactRecordTypes(
          result.relatedContactRecordTypes
        );

        component.set("v.contactRecordTypeList", contactRecordTypeList);
        component.set(
          "v.relatedContactRecordTypeList",
          relatedContactRecordTypeList
        );

        const contactRecordTypeRecord = contactRecordTypeList.find(
          (record) => record.label === "Professional"
        );
        const relatedContactRecordTypeRecord =
          relatedContactRecordTypeList.find(
            (record) => record.label === contactRecordTypeRecord.label
          );

        var selectedRecordType = {};
        selectedRecordType.label = contactRecordTypeRecord.label;
        selectedRecordType.value = contactRecordTypeRecord.value;
        selectedRecordType.relatedValue = relatedContactRecordTypeRecord.value;

        component.set("v.selectedRecordType", selectedRecordType);
      } else if (state === "INCOMPLETE") {
        // do something
      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("Error message: " + errors[0].message);
          }
        } else {
          console.log("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  }
});
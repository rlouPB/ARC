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
    component.set("v.isNoteLoaded", false);
    // console.log('getActivityByNoteId...');
    helper.callApexMethod(
      component,
      "getPatientNoteDetails",
      { basicNoteId: noteId },
      function (result) {
        // console.log('activity', result);
        var newActivity = result;
        // console.log("newActivity: " + JSON.stringify(newActivity));
        if (newActivity) {
          if (
            newActivity.RecordType.Name == component.get("v.noteRecordtypeName")
          ) {
            component.set("v.isComponentLoaded", false);
            if (newActivity.Patient_Note__r) {
              component.set("v.patientNote", newActivity.Patient_Note__r);
            }
            if (!newActivity.Subject) {
              newActivity.Subject = "";
            }

            component.set("v.newActivity", newActivity);
            // console.log('84 Set newActivity ' + JSON.stringify(newActivity));
            component.set("v.isComponentLoaded", true);
          } else {
          }
          component.set("v.isNoteLoaded", true);
        }
      },
      null,
      false
    );
  },

  isValidNoteId: function (recordId) {
    // console.log('isValidAccountId...');
    if (!recordId) {
      return false;
    }

    var prefix = recordId.substring(0, 3);
    // console.log('recordId', recordId, prefix, recordId.length);
    return (
      prefix === "00T" && (recordId.length === 15 || recordId.length === 18)
    );
  },

  showMyToast: function (component, event, message, type, sec) {
    // console.log('showMyToast...');
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
    // console.log('initializeRequiredFields...');
    let reqFieldMap = {
      Call_Date_Time__c: { label: "Call Date/Time", required: true },
      Call_Status__c: { label: "Call Status", required: true }
      // 'Call_Method__c' :      { label : 'Call Method',    required : true},
      // 'Patient_Name__c' {label: : 'Patient Name', required=true},
      // 'Caller_Name__c' : {label : 'Person Spoken To', required=true}
    };
    component.set("v.requiredFields", reqFieldMap);
  },
  addRequiredField: function (component, fieldName, fieldLabel) {
    // console.log('addRequiredField...');
    let reqFieldMap = component.get("v.requiredFields");
    reqFieldMap[fieldName] = { label: fieldLabel, required: true };
    component.set("v.requiredFields", reqFieldMap);
  },

  removeRequiredField: function (component, fieldName, fieldLabel) {
    // console.log('removeRequiredField...');
    let reqFieldMap = component.get("v.requiredFields");
    reqFieldMap[fieldName] = { label: fieldLabel, required: false };
    component.set("v.requiredFields", reqFieldMap);
  },

  setSubjectFilter: function (component) {
    var subjectFilter = [
      {
        fieldName: "Field__c",
        condition: "=",
        value: "Basic_Note__c.Subject__c"
      }
    ];

    component.set("v.subjectFilter", subjectFilter);
  },

  validateRequiredFields: function (component, helper, obj) {
    // console.log('validateRequiredFields...');
    let fields = component.get("v.requiredFields");
    // console.log('Required fields' + JSON.stringify(fields));
    let errorMessage = ""; //component.get("v.Errormsg");

    let isRequiredFieldsValid = Object.keys(fields).reduce(function (
      validSoFar,
      field
    ) {
      if (fields[field].required) {
        var isPass =
          (obj[field] && fields[field].label != "Person Spoken To") ||
          (fields[field].label == "Person Spoken To" &&
            helper.isValidContactId(obj[field]));
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
    console.log("validateRequiredFields complete...");
    return isRequiredFieldsValid; // && isContactLookupValid;
  },

  enableSaveButton: function (component, isDisabled) {
    // console.log('enableSaveButton...');
    let isComponentLoaded = component.get("v.isComponentLoaded");
    if (isComponentLoaded) {
      component.set("v.isSaveDisabled", isDisabled);
    }
  },

  resetNewActivity: function (component, isSetTheValue) {
    // console.log('resetNewActivity...');
    // let newActivity = component.get("v.newActivity"),
    // patientNote = component.get("v.patientNote"),
    // recordId = component.get("v.recordId");
    // let isStandalone = component.get('v.formFactor') == 'LARGE';
    var newActivity = {
      sobjectType: "Note",
      Call_Date_Time__c: "",
      Call_Type__c: "Inquiry",
      Call_Status__c: "Logged",
      Subject__c: ""
    };
    component.set("v.newActivity", newActivity);

    // patientNote = {
    //     'Caller_Affect_and_Presentation__c':'',
    //     'Rich_Text_Notes__c':''
    // };

    // component.set("v.patientNote", patientNote);

    var subjectLookup = component.find("subjectLookup");
    if (subjectLookup) {
      subjectLookup.closePill();
    }

    component.set("v.isNoteLoaded", true);
    return newActivity;
  },

  setAutosaveOn: function (component, event, helper) {
    if (!component.get("v.autosaveId")) {
      console.log("lognote autosave on");
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
    window.clearInterval(component.get("v.autosaveId"));
    component.set("v.autosaveId", null);
  },
  autosaveDraft: function (component, event, helper) {
    if (component.get("v.loading") || component.get("v.isAutosaving")) {
      console.log("save already in progress. Draft save aborted");
      return;
    }
    if (
      component.get("v.isComponentLoaded") &&
      !component.get("v.isSaveDisabled")
    ) {
      let modalFromCallSearchId = component.get("v.modalFromCallSearchId");
      let newActivity = component.get("v.newActivity");
      //let patientNote = component.get('v.patientNote');
      if (
        newActivity.Rich_Text_Notes__c &&
        newActivity.Rich_Text_Notes__c.length >
          component.get("v.autosaveMinimumNoteLength")
      ) {
        helper.saveActionLogNote(
          component,
          event,
          helper,
          modalFromCallSearchId,
          true
        );
      }
    } else {
      console.log("turning off auto save");
      helper.setAutosaveOff(component, event, helper);
    }
  },
  saveActionLogNote: function (
    component,
    event,
    helper,
    modalFromCallSearchId,
    isDraftSave,
    resetAfterSave
  ) {
    var newActivity = component.get("v.newActivity"),
      patientNote = component.get("v.patientNote"),
      recordId = component.get("v.recordId");

    component.set("v.isAutosaveComplete", false);
    if (isDraftSave) {
      component.set("v.isAutosaving", true);
    } else {
      component.set("v.loading", true);
    }

    this.hideCustomToast(component);

    //if datetime set by now, need to adjust time zone
    if (component.get("v.dateTimeSetByNow")) {
      let noteDateTime = moment(newActivity.Call_Date_Time__c)
        .tz("UTC")
        .format();
      newActivity.Call_Date_Time__c = noteDateTime;
    }

    if (
      !$A.util.isUndefinedOrNull(newActivity) &&
      (isDraftSave ||
        this.validateRequiredFields(component, helper, newActivity))
    ) {
      if (isDraftSave) isDraftSave = true;
      else isDraftSave = false;
      this.hideCustomToast(component);
      this.callApexMethod(
        component,
        "createLogNote",
        {
          patientNoteStr: JSON.stringify(newActivity),
          accountId: recordId,
          isDraftSave: isDraftSave
        },
        function (result) {
          // console.log('result------' + JSON.stringify(result));
          var message;
          if (newActivity.Id) {
            message = "Admission Note has been updated successfully.";
          } else {
            message = "Admission Note has been created successfully.";
          }
          if (recordId) {
            //Fire to refresh call search
            $A.get("e.c:onPopulateLogACall")
              .setParams({ noteId: null, isFromCallSearch: false })
              .fire();
          }

          //reload Note data for this saved Note unless the No Reload On Save flag is true
          if (!component.get("v.noReloadOnSave")) {
            newActivity.Id = result.Id;
            newActivity.LastModifiedDate = result.LastModifiedDate;
            newActivity.LastModifiedBy = result.LastModifiedBy;
            newActivity.Auto_Saved__c = result.Auto_Saved__c;
            //patientNote.Id = result.Patient_Note__c;

            component.set("v.newActivity", newActivity);
          } else if (modalFromCallSearchId == "") {
            //if don't reload on save, and there's no Id, start a new note
            helper.resetNewActivity(component, true);
          }

          component.set("v.noReloadOnSave", false);
          component.set("v.loading", false);
          component.set("v.isAutosaving", false);
          if (isDraftSave) {
            component.set("v.isAutosaveComplete", true);
          } else {
            component.find("notifLib").showToast({
              title: "Success!",
              message: message
            });
          }
          helper.enableSaveButton(component, true);
        },
        function (error) {
          helper.showCustomToast(component, {
            type: "error",
            title: "Error while saving a record",
            message: error
          });
          component.set("v.loading", false);
          // console.log("No longer loading...");
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
      // console.log("No longer loading...");
    }
  }
});
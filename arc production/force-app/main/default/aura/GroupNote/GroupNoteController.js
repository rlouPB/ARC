({
  init: function (component, event, helper) {
    helper.getGroupNote(component, event, helper);
    helper.setFilters(component);
    //helper.hideSpinner(component);
  },

  handleSelectedItemEvent: function (component, event, helper) {
    var newRecordId = component.get("v.selectedRecordPatient").value;
    var lstGroupAttendance = component.get("v.lstGroupAttendance");
    var recordExists = false;
    if (lstGroupAttendance) {
      for (var i = 0; i < lstGroupAttendance.length; i++) {
        if (lstGroupAttendance[i].Patient__c == newRecordId) {
          recordExists = true;
        }
      }
    }
    if (recordExists == false) {
      var params = event.getParams();
      var sourceInstanceName = params.sourceInstanceName;
      var selectedObj = params.selectedObj;

      var action = component.get("c.getGroupAttendanceInstance");
      action.setParams({
        "accId": component.get("v.selectedRecordPatient").value,
        "groupNoteId": component.get("v.objGroupNote.Id"),
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var lstGA;
          if (component.get("v.lstGroupAttendance") == undefined) lstGA = [];
          else lstGA = component.get("v.lstGroupAttendance");
          lstGA.push(response.getReturnValue());
          component.set("v.lstGroupAttendance", lstGA);
        }
      });

      $A.enqueueAction(action);
    } else {
      var childCmp = component.find("gaComponent");
      childCmp.duplicatePatient(newRecordId);
    }
  },

  changeOwner: function (component, event, helper) {
    helper.changeOwner(component, event, helper);
  },

  groupMeet: function (component, event, helper) {
    var option = event.getSource().get("v.value");

    if (option == "No") {
      component.set("v.isGroupMeet", true);
    } else if (option == "Yes" || option == "None") {
      component.set("v.isGroupMeet", false);
      component.set("v.objGroupNote.Reason_Group_Did_Not_Meet__c", "None");
      component.set("v.isGroupMeetChanged", true);
    }
  },

  updateGroupNoteJS: function (component, event, helper) {
    component.set("v.calledFromAutoSave", false);
    component.set("v.calledFromSaveButton", true);
    component.set("v.isCmpDirty", true);
    component.set("v.unsavedChanged", false);
    helper.upsertGroupNote(component, event, helper);
    component.set("v.hasClickedSave", true);
    window.clearInterval(component.get("v.setIntervalId"));
  },

  finalizeGroupNote: function (component, event, helper) {
    let popup = component.find("popup");

    popup
      .confirm(
        "Are you sure you want to finalize this note?",
        "Confirm",
        "warn"
      )
      .then((resp) => {
        if (resp) {
          component.set("v.unsavedChanged", false);
          var now = Date();
          var finalizedUser = $A.get("$SObjectType.CurrentUser.Id");
          component.set("v.objGroupNote.Status__c", "Finalized");
          component.set("v.isReadOnly", true);
          helper.finalizeGroupNote(component, event, helper);
        }
      });
  },

  closeModal: function (component, event, helper) {
    let closeEvent = component.getEvent("closeModalEvent");
    closeEvent.setParam("data", "groupNote");
    closeEvent.fire();
  },

  noteChangeBS: function (component, event, helper) {
    if (!component.get("v.isRecordLoaded") || !component.get("v.setIntervalId"))
      return;

    window.clearInterval(component.get("v.setIntervalId"));
    var briefSummary = component.get(
      "v.objGroupNote.Brief_Narrative_Summary__c"
    );
    var bsLength = 0;
    if (briefSummary != undefined) {
      bsLength = briefSummary.length;
    }
    var bsloaded = component.get("v.bsLoaded");
    component.set("v.unsavedChanged", true);
    var oldvalue = JSON.stringify(event.getParam("oldValue"));
    var currentValueLength = 0;
    if (event.getParam("value").Brief_Narrative_Summary__c != undefined)
      currentValueLength = event.getParam("value").Brief_Narrative_Summary__c
        .length;
    var oldValueLength = 0;
    if (event.getParam("oldValue").Brief_Narrative_Summary__c != undefined)
      oldValueLength = event.getParam("oldValue").Brief_Narrative_Summary__c
        .length;
    if (
      component.get("v.isReadOnly") == false &&
      bsLength >= component.get("v.autoSaveMinLength") &&
      component.get("v.hasRecordUpdated") == true
    ) {
      component.set("v.isCmpDirty", true);
      if (
        component.get("v.objGroupNote.Meeting__c") != undefined &&
        component.get("v.isRecordLoaded") == true
      ) {
        if (component.get("v.isGroupMeetChanged") == false) {
          if (component.get("v.controlRecursive") == true) {
            component.set("v.controlRecursive", false);
          } else {
            component.set("v.calledFromAutoSave", true);
            var timeInerval = component.get("v.setTimeInterval");
            var interval = window.setInterval(
              $A.getCallback(function () {
                if (!component.isValid()) {
                  window.clearInterval(interval);
                  return;
                }

                helper.upsertGroupNote(component, event, helper);
                component.set("v.isTimeIntervalSet", true);
              }),
              timeInerval
            );
          }
        } else {
          component.set("v.isGroupMeetChanged", false);
        }
      }
      component.set("v.setIntervalId", interval);
    }
    if (component.get("v.bsLoaded") == false) {
      component.set("v.bsLoaded", true);
    }
    if (component.get("v.hasClickedSave") == true) {
      component.set("v.hasClickedSave", false);
    }
  },

  noteChangePS: function (component, event, helper) {
    if (!component.get("v.isRecordLoaded") || !component.get("v.setIntervalId"))
      return;
    window.clearInterval(component.get("v.setIntervalId"));
    var patientSpecific = component.get(
      "v.objGroupNote.Patient_Specific_Concerns_and_Follow_up__c"
    );
    var psLength = 0;
    if (patientSpecific != undefined) {
      psLength = patientSpecific.length;
    }
    component.set("v.unsavedChanged", true);
    var psloaded = component.get("v.psLoaded");
    var oldvalue = JSON.stringify(event.getParam("oldValue"));
    var currentValueLength = 0;
    if (
      event.getParam("value").Patient_Specific_Concerns_and_Follow_up__c !=
      undefined
    )
      currentValueLength = event.getParam("value")
        .Patient_Specific_Concerns_and_Follow_up__c.length;
    var oldValueLength = 0;
    if (
      event.getParam("oldValue").Patient_Specific_Concerns_and_Follow_up__c !=
      undefined
    )
      oldValueLength = event.getParam("oldValue")
        .Patient_Specific_Concerns_and_Follow_up__c.length;
    if (
      component.get("v.isReadOnly") == false &&
      psLength >= component.get("v.autoSaveMinLength") &&
      component.get("v.hasRecordUpdated") == true
    ) {
      component.set("v.isCmpDirty", true);
      if (
        component.get("v.objGroupNote.Meeting__c") != undefined &&
        component.get("v.isRecordLoaded") == true
      ) {
        if (component.get("v.isGroupMeetChanged") == false) {
          if (component.get("v.controlRecursive") == true) {
            component.set("v.controlRecursive", false);
          } else {
            var timeInerval = component.get("v.setTimeInterval");
            component.set("v.calledFromAutoSave", true);
            var interval = window.setInterval(
              $A.getCallback(function () {
                if (!component.isValid()) {
                  window.clearInterval(interval);
                  return;
                }

                helper.upsertGroupNote(component, event, helper);
                component.set("v.isTimeIntervalSet", true);
              }),
              timeInerval
            );
          }
        } else {
          component.set("v.isGroupMeetChanged", false);
        }
      }
      component.set("v.setIntervalId", interval);
    }
    if (component.get("v.psLoaded") == false) {
      component.set("v.psLoaded", true);
    }
    if (component.get("v.hasClickedSave") == true) {
      component.set("v.hasClickedSave", false);
    }
  },

  handleDestroy: function (component, event, handler) {
    window.clearInterval(component.get("v.setIntervalId"));
    event.stopPropagation();
  },

  closingQuickAction: function (component, event, helper) {
    if (component.get("v.unsavedChanged") == true) {
      component.find("notifLib").showNotice({
        "variant": "warning ",
        "header": "Unsaved Changes will be lost!",
        "message": "Please save the unsaved changes",
        closeCallback: function () {
          /* var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();*/
        },
      });
    }
  },
});
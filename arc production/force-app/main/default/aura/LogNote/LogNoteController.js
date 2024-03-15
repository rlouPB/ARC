({
  doInit: function (component, event, helper) {
    helper.initializeRequiredFields(component, event, helper);
    helper.setSubjectFilter(component);

    var params = helper.parseURL();
    if (params) {
      helper.getActivityByNoteId(component, params.noteId, helper);
    } else {
      helper.resetNewActivity(component);
    }
  },

  doneScriptsLoading: function (component, event, helper) {
    component.set("v.loading", false);
  },

  saveActionLogNote: function (component, event, helper) {
    helper.saveActionLogNote(component, event, helper);
  },

  onNowClick: function (component, event, helper) {
    let newDatetimeValue = moment().format("YYYY-MM-DDTHH:mm:ss");

    var newActivity = component.get("v.newActivity");
    newActivity.Call_Date_Time__c = newDatetimeValue;

    component.set("v.lastNowValue", newDatetimeValue);
    component.set("v.dateTimeSetByNow", true);

    component.set("v.newActivity", newActivity);
  },

  handleChangeNote: function (component, event, helper) {
    let expr = event.getParam("expression");
    let newValue = event.getParam("value");
    let oldValue = event.getParam("oldValue");
    var obj = component.get("v.newActivity");

    //if datetime doesn't match what the Now button did, reset Utc
    if (
      component.get("v.dateTimeSetByNow") &&
      obj.Call_Date_Time__c != component.get("v.lastNowValue")
    ) {
      component.set("v.dateTimeSetByNow", false);
      component.set("v.lastNowValue", "");
    }
    helper.enableSaveButton(component, false);
  },

  enableSaveButton: function (component, event, helper) {
    helper.enableSaveButton(component, false);
    helper.setAutosaveOn(component, event, helper);
  },
  handlePopulateLogANote: function (component, event, helper) {
    const noteId = event.getParam("noteId"),
      noteRecordtypeName = event.getParam("noteRecordtypeName"),
      isFromCallSearch = event.getParam("isFromCallSearch"),
      recordId = component.get("v.recordId");
    if (
      noteRecordtypeName == component.get("v.noteRecordtypeName") &&
      isFromCallSearch
    ) {
      if (component.get("v.isSaveDisabled")) {
        if (noteId) helper.getActivityByNoteId(component, noteId, helper);
        else helper.resetNewActivity(component, true);
        if (recordId) {
        }
        component.set("v.isSaveDisabled", true);
      } else {
        component.set("v.showStartNewNoteModal", true);
        component.set("v.modalFromCallSearchId", noteId);
      }
    }
  },

  onStartNewNote: function (component, event, helper) {
    if (!component.get("v.isSaveDisabled")) {
      component.set("v.modalFromCallSearchId", "");
      component.set("v.showStartNewNoteModal", true);
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
      //either Save and New or Save and load selected from call search
      component.set("v.noReloadOnSave", true);
      component.set("v.isSaveDisabled", true);
      helper.saveActionLogNote(component, event, helper, modalFromCallSearchId);
    } else if (localId === "throwawaychanges") {
      component.set("v.isSaveDisabled", true);
      helper.resetNewActivity(component, true);
    }

    if (modalFromCallSearchId != "") {
      helper.getActivityByNoteId(component, modalFromCallSearchId, helper);
    }
    component.set("v.showStartNewNoteModal", false);
    component.set("v.modalFromCallSearchId", "");
  }
});
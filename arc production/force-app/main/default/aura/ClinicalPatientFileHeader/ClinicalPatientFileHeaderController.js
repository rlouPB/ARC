/* eslint-disable no-unused-expressions */
({
  init: function (component, event, helper) {
    helper.retrievePatientFileHeaderSetting(component).then($A.getCallback(function(result){
      let accountFields = JSON.parse(result.config);
      component.set("v.recordFields", accountFields);
      component.set("v.programStatus", result.programStatus);
      helper.shouldShowClinicalPatientFile(component);
    }))
  },
  handleRecordUpdated: function (component, event, helper) {
    var eventParams = event.getParams();
    console.log("event fired " + JSON.stringify(event.getParams()));
    if (eventParams.changeType === "LOADED") {
      component.set("v.isRecordLoaded", true);
    } //if (eventParams.changeType === 'CHANGED') {
    else {
      //reload when any of these three records is updated
      component.find("recordLoader").reloadRecord(true);
    }
  }
});
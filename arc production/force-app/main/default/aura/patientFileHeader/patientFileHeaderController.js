({
  handleRecordUpdated: function (component, event, helper) {
    var eventParams = event.getParams();
    console.log("event fired " + JSON.stringify(event.getParams()));
    if (eventParams.changeType === "LOADED") {
      component.set("v.isRecordLoaded", true);
      // window.setTimeout($A.getCallback(function() {
      //     helper.toggleSpinner(component, 0);
      // }),1000);
    } //if (eventParams.changeType === 'CHANGED') {
    else {
      //reload when any of these three records is updated
      component.find("recordLoader").reloadRecord(true);
      // helper.toggleSpinner(component, 0);
    }
  },
});
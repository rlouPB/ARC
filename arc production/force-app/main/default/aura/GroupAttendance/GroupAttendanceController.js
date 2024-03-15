({
  doInit: function (component, event, helper) {
    console.log("gnote", JSON.stringify(component.get("v.objGroupNote")));
    helper.setFilters(component);
    helper.countAttended(component, event, helper);
    helper.clearPill(component, event, helper);
    // helper.getAttendanceTracking(component, event, helper);
    if (component.get("v.objGroupNote.Status__c") == "Finalized") {
      component.set("v.isReadOnly", true);
    }
  },

  reCountAttended: function (component, event, helper) {
    helper.countAttended(component, event, helper);
  },

  handleSelectedItemEvent: function (component, event, helper) {
    console.log("selectedItem ");
    helper.selectedPatient(component, event, helper);
    event.stopPropagation();
  },

  xClicked: function (component, event, helper) {
    var ctarget = event.currentTarget;
    var id_str = ctarget.dataset.value;
    console.log("itste", id_str);
    var lstGroupAttendance = component.get("v.lstGroupAttendance");
    var newList = [];
    lstGroupAttendance.forEach(function (item) {
      if (item.gatt.Patient__c != id_str) {
        newList.push(item);
      }
    });

    component.set("v.lstGroupAttendance", newList);
  },

  removeMember: function (component, event, helper) {
    var dupRecId = component.get("v.duplicateRecordId");
    if (dupRecId) {
      document.getElementById(dupRecId).classList.remove("highlighted");
    }
  },

  showSpinner: function (component, event, helper) {
    // make Spinner attribute true for display loading spinner
    component.set("v.Spinner", true);
  },

  // this function automatic call by aura:doneWaiting event
  hideSpinner: function (component, event, helper) {
    // make Spinner attribute to false for hide loading spinner
    component.set("v.Spinner", false);
  },
});
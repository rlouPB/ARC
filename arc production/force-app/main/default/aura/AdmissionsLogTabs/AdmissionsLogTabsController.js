({
  doInit: function (component, event, helper) {
    console.log("AdmissionsLogTabsController doInit...");
    let params = helper.parseURL(component);
    console.log("doInit", params);
    console.log("v.recordId", component.get("v.recordId"));

    if (params && params.noteId) {
      component.set("v.noteId", params.noteId);
      component.find("noteLoader").reloadRecord(true);
    }
  },

  handlePopulateLogACall: function (component, event, helper) {
    console.log("AdmissionsLogTabsController handlePopulateLogACall...");
    let params = event.getParams();
    console.log(
      "AdmissionsLogTabsController handlePopulateLogACall params: " +
        JSON.stringify(params)
    );
    if (params.isFromCallSearch) {
      component.set("v.noteId", params.noteId);
      component.set("v.noteRecordtypeName", params.noteRecordtypeName);
      component.set("v.isFromCallSearch", params.isFromCallSearch);
      if (params.noteRecordtypeName)
        helper.selectTab(component, component.get("v.noteRecordtypeName"));
      else component.find("noteLoader").reloadRecord(true);
    }
  },

  handleNoteLoaded: function (component, event, helper) {
    console.log("AdmissionsLogTabsController handleNoteLoaded...");
    console.log(
      "v.noteRecordtypeName " + component.get("v.noteRecordtypeName")
    );
    helper.selectTab(component, component.get("v.noteRecordtypeName"));
  }
});
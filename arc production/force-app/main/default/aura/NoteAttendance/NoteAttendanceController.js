({
  doInit: function (component, event, helper) {
    helper.getStartOfMonth(component, event, helper);
    var uID = $A.get("$SObjectType.CurrentUser.Id");
    component.set("v.userID", uID);
    //helper.getDateStrings(component, event, helper);
    helper.getMeetings(component, event, helper);
  },
  handleAttendanceCommentChange: function (component, event, helper) {
    let theNote = component.get("v.theNote");
    // console.log('handleAttendanceCommentChange is called, value:'+event.getParam("value"));
    // console.log('handleAttendanceCommentChange is called, theNote:'+JSON.stringify(theNote));
    helper.updateAttendanceComments(component, event, helper);
  },

  openCustomCalendar: function (component, event, helper) {
    component.set("v.showCalendarModal", true);
  },

  closeCustomCalendar: function (component, event, helper) {
    if (event.getParam("data") == "CustomCalendar") {
      component.set("v.showCalendarModal", false);
      helper.getMeetings(component, event, helper);
    }
  },
  updateAggregatedAttendanceFields: function (component, event, helper) {
    //calculate the aggregated Patient Note attendance fields and populate into theNote
    helper.updateAggregatedAttendanceFields(component, event, helper);
  }
});
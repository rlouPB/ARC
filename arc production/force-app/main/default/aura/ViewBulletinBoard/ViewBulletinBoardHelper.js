/* eslint-disable no-undef */
/* eslint-disable no-redeclare */
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  closeModal: function (component, response) {
    console.log("ViewBulletinBoardHelper closeModal...");
    component.set("v.showModal", false);
    if (response.Id !== "") {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        title: "Success",
        message: "Bulletin Board item successfully added.",
        duration: 2000,
        type: "success"
      });
      toastEvent.fire();
      $A.get("e.force:refreshView").fire();
    } else {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        title: "Error",
        message: "Error adding Bulletin Board item.",
        duration: 2000,
        type: "error"
      });
      toastEvent.fire();
    }
  }

  // handleFormSubmit: function (component) {
  // console.log("ViewBulletinBoardHelper handleFormSubmit...");
  //   var showValidationError = false;
  //   var fields = component.find("newBulletinItem");
  //   var vaildationFailReason = "";

  //   fields.forEach(function (field) {
  //     if (
  //       field.get("v.fieldName") === "Section__c" &&
  //       $A.util.isEmpty(field.get("v.value"))
  //     ) {
  //       showValidationError = true;
  //       vaildationFailReason = "This field is required.";
  //     }

  //     if (
  //       field.get("v.fieldName") === "Display_Start_Date__c" &&
  //       $A.util.isEmpty(field.get("v.value"))
  //     ) {
  //       showValidationError = true;
  //       vaildationFailReason = "This field is required.";
  //     }

  //     if (
  //       field.get("v.fieldName") === "Label__c" &&
  //       $A.util.isEmpty(field.get("v.value"))
  //     ) {
  //       showValidationError = true;
  //       vaildationFailReason = "This field is required.";
  //     }

  //     if (
  //       field.get("v.fieldName") === "Display_End_Date__c" &&
  //       $A.util.isEmpty(field.get("v.value"))
  //     ) {
  //       showValidationError = true;
  //       vaildationFailReason = "This field is required.";
  //     }
  //   });

  //   if (!showValidationError) {
  //     component.set("v.loading", true);
  //     component.find("newBulletinItemForm").submit();
  //   } else {
  //     component.set("v.loading", false);
  //   }
  // }
});
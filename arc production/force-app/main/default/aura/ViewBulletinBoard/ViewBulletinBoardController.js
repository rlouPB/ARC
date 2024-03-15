/* eslint-disable no-undef */
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  closeModal: function (component) {
    console.log("ViewBulletinBoardController closeModal...");
    component.set("v.showModal", false);
  },

  handleErrors: function (component, error) {
    console.log("ViewBulletinBoardController handleErrors...");
    component.set("v.loading", false);
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: "Error",
      message: error.getParams().message,
      duration: 2000,
      type: "error"
    });
    toastEvent.fire();
  },

  handleSuccess: function (component, event, helper) {
    console.log("ViewBulletinBoardController handleSuccess...");
    var param = event.getParam("response");
    var response = {};
    response.Id = param.id;
    helper.closeModal(component, response);
  },

  save: function (component, event) {
    console.log("ViewBulletinBoardController save...");
    event.preventDefault();
    var theForm = component.find("newBulletinItemForm");
    theForm.submit();
  },
  saveEditedForm: function (component, event) {
    console.log("ViewBulletinBoardController save...");
    event.preventDefault();
    var theForm = component.find("editBulletinItemForm");
    theForm.submit();
  },

  showModal: function (component) {
    console.log("ViewBulletinBoardController showModal...");
    component.set("v.showModal", true);
  },
  showEditModal: function (component, event) {
    console.log("ViewBulletinBoardController showModal...");
    var itemId = event.getSource().get('v.value');
    component.set("v.showEditModal", true);
    component.set("v.currentItemId", itemId);
  },
  closeEditModal: function (component) {
    console.log("ViewBulletinBoardController closeModal...");
    component.set("v.showEditModal", false);
  }
});
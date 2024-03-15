/* eslint-disable no-unused-expressions */
({
  init: function (cmp, event, helper) {
    console.log("ViewMessageController init...");
    helper.updateStatus(cmp, "Read", cmp.get("v.id"), true);

    if (cmp.get("v.id") != "" && cmp.get("v.type") != "") {
      helper.fetch(cmp, cmp.get("v.id"), cmp.get("v.clientId"));
    }
  },

  handlePrint: function (cmp, event, helper) {
    window.print();
  },
  handlePreview: function (cmp, event, helper) {
    console.log("ViewMessageController handlePreview...");

    let id = event.getParam("id");
    let messageType = event.getParam("messageType");
    let isRead = event.getParam("isRead");
    let clientId = event.getParam("clientId");

    if (id != cmp.get("v.id")) {
      cmp.set("v.id", id);
      cmp.set("v.type", messageType);

      helper.fetch(cmp, id, clientId);
    }
  },

  handleRead: function (cmp, event, helper) {
    console.log("ViewMessageController handleRead...");
    let id = event.getSource().get("v.value");

    helper.updateStatus(cmp, "Read", id, true);
  },

  handleUnread: function (cmp, event, helper) {
    console.log("ViewMessageController handleUnread...");

    let id = event.getSource().get("v.value");

    helper.updateStatus(cmp, "Read", id, false);
  },

  handleReply: function (cmp, event, helper) {
    console.log("ViewMessageController handleReply...");

    let messageId = event.getSource().get("v.value");
    let label = event.getSource().get("v.label");
    helper.showMessageModal(cmp, {
      type: cmp.get("v.type"),
      label: label,
      messageId: messageId
    });
  },

  handleDelete: function (cmp, event, helper) {
    console.log("ViewMessageController handleDelete...");

    let id = event.getSource().get("v.value");
    // this.dispatchEvent(new CustomEvent("modalclosed"));

    helper.updateStatus(cmp, "Delete", id, true);
    //comment temp 210205 JN. Don't think this is needed
    // $A.get("e.force:closeQuickAction").fire();
  },
  handleUnDelete: function (cmp, event, helper) 
  {
    let id = event.getSource().get("v.value");
    helper.updateStatus(cmp, "UnDelete", id, true);
  },

  toggleAllRecipients: function (cmp) {
    console.log("ViewMessageController toggleAllRecipients...");

    if (cmp.get("v.message.displayMore") == true) {
      cmp.set("v.message.displayMore", false);
    } else {
      cmp.set("v.message.displayMore", true);
    }
  }
});
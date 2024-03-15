/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  init: function (component, event, helper) {
    console.log("UserMessagesController init...");
    let page = component.get("v.page");
    helper.fetch(component, "", page);
    helper.subscribe(component, event);
    //221013 JN this is done by UserInbox, doesn't seem to work here
    //helper.getMessageCounts(component);
  },

  emptyBin: function (component, event, helper) {
    console.log("UserMessagesController emptyBin...");
    var params = event.getParam("arguments");
    if (params) {
      var deleteStatus = params[0];

      if (deleteStatus) {
        let allData = component.get("v.allData");
        let ids = allData.map((message) => message.id);
        helper.deleteBin(component, ids);
      }
    }
  },

  filter: function (component, event, helper) {
    console.log("UserMessagesController filter...");
    var params = event.getParam("arguments");
    if (params) {
      var param = params[0];
      let allData = component.get("v.allData");
      
      let messageFilter = component.get("v.messageFilter");
      let messageProfileFilter = component.get("v.messageProfileFilter");
      let page = component.get("v.page");
      helper.fetch(component, "", page);

      if (messageFilter === "All") {
        if (messageProfileFilter === "AllTypes") {
          component.set("v.data", allData);
        } else {
          let displayData = allData.filter((message) => message.read === false);
          let displayData2 = displayData.filter((message) => message.messageProfile === messageProfileFilter);
          component.set("v.data", displayData2);
        }
      } else {
        let displayData = allData.filter((message) => message.read === true);

        if (messageProfileFilter === "AllTypes") {
          component.set("v.data", displayData);
        } else {
          let displayData2 = displayData.filter((message) => message.messageProfile === messageProfileFilter);
          component.set("v.data", displayData2);
        }
      }
    }
  },

  handleCheck: function (component, event, helper) {
    console.log("UserMessagesController handleCheck...");
    let id = event.target.id;
    let checked = event.target.checked;

    helper.updateStatus(component, "Read", id, checked, false);
  },

  handleDelete: function (component, event, helper) {
    console.log("UserMessagesController handleDelete...");
    let id = event.getSource().get("v.value");

    helper.updateStatus(component, "Delete", id, true, false);
    helper.fetch(component, "", component.get("v.page"));
  },

  handleNewCreate: function (component, event, helper) {
    let type = event.getParam("type");
    console.log("UserMessagesController handleNewCreate...event type " + type + " component type " + component.get('v.type'));


    if (type === component.get("v.type")) {
      helper.fetch(component, "", 0);
    }

    // if ((type == "REFRESH_ALERT")) {
    //   helper.fetch(component, "", 0);
    // }
  },

  handlePortalNotification: function (component, event, helper) {
    console.log("UserMessagesController handlePortalNotification...");
  },

  handlePreviewUpdate: function (component, event, helper) {
    console.log("UserMessagesController handlePreviewUpdate...");
    console.log("UserMessagesController handlePreviewUpdate event.getParams: " + JSON.stringify(event.getParams()));
    console.log("UserMessagesController handlePreviewUpdate v.type: " + component.get("v.type"));

    let update = event.getParam("update");
    let type = event.getParam("messageType");
    let id = event.getParam("id");
    let page = component.get("v.page");

    if (type === component.get("v.type") && update) {
      helper.fetch(component, "", page);
    } else {
      component.set("v.activeSelect", id);
    }
  },

  handleReply: function (component, event, helper) {
    console.log("UserMessagesController handleReply...");
    let messageId = event.getSource().get("v.value");
    let label = event.getSource().get("v.label");
    let allData = component.get("v.allData");
    component.set("v.isReply", true);
    component.set("v.label", label);

    if (messageId !== null) {
      allData.forEach((element) => {
        if (element.messageId === messageId) {
          component.set("v.selected", JSON.stringify(element));
          component.set("v.selectedMessageProfile", element.messageProfile);
        }
      });
    }

    helper.showMessageModal(component, {
      type: component.get("v.type"),
      label: component.get("v.label"),
      messageId: messageId,
      messageProfile: component.get("v.selectedMessageProfile"),
      focus: "inputBody"
    });
  },

  handleSubjectMessage: function (component, event, helper) {
    console.log("UserMessagesController handleSubjectMessage...");
    let selectedItem = event.currentTarget;
    let messageId = selectedItem.dataset.id;
    console.log("UserMessagesController handleSubjectMessage selectedItem: " + selectedItem);
    console.log("UserMessagesController handleSubjectMessage messageId: " + messageId);

    helper.showViewMessageModal(component, {
      type: component.get("v.type"),
      id: messageId,
      clientId: component.get("v.clientId"),
      closeCallback: function () {
        console.log("closeCallback");
      }
    });
  },

  handleMessageDelete: function (component, event, helper) {
    console.log("UserMessagesController handleMessageDelete...");
    console.log(component.find("overlayLibUserMsg"));
    let id = event.getSource().get("v.id");
    console.log(id);
    helper.updateStatus(component, "Delete", id, true, false);

    // var modalPromise = 
    // component.get("v.modalPromise").then(function (modal) {
    //   modal.close();
    // });
    // if (modalPromise)
    // {
    //   modalPromise.then(function (modal) {
    //     modal.close();
    //   });
    // }
  },

  handleUnDelete: function (component, event, helper) {
    console.log("UserMessagesController handleUnDelete...");
    let id = event.getSource().get("v.value");

    helper.updateStatus(component, "UnDelete", id, false, false);
  },

  next: function (component, event, helper) {
    console.log("UserMessagesController next...");
    var params = event.getParam("arguments");
    if (params) {
      var page = params[0];
      let searchTerm = component.get("v.searchTerm");
      helper.fetch(component, searchTerm, page);

      return false;
    }
  },

  preview: function (component, event, helper) {
    console.log("UserMessagesController preview...");
    if (component.get("v.hidePreview") === true) {
      // Do nothing
    } else {
      let selectedItem = event.currentTarget;

      let id = selectedItem.dataset.id;

      if (id === "") return;

      let allData = component.get("v.allData");

      let message = allData.find((message) => message.id === id);

      component.set("v.activeSelect", id);

      if (message.read) {
        helper.sendPreviewEvent(component, id, true);
      } else {
        helper.updateStatus(component, "Read", id, true, true);
      }
    }
  },

  previous: function (component, event, helper) {
    console.log("UserMessagesController previous...");
    var params = event.getParam("arguments");
    if (params) {
      var page = params[0];
      let searchTerm = component.get("v.searchTerm");
      helper.fetch(component, searchTerm, page);

      return false;
    }
  },

  searchInbox: function (component, event, helper) {
    console.log("UserMessagesController searchInbox...");
    var params = event.getParam("arguments");
    if (params) {
      var searchTerm = params[0];
      component.set("v.searchTerm", searchTerm);
      helper.fetch(component, searchTerm, 0);

      return false;
    }
  },

  sortByName: function (component, event, helper) {
    console.log("UserMessagesController sortByName...");
    let target = event.currentTarget;
    let column = target.getAttribute("data-column");
    helper.sortBy(component, column);
  }

  // removeComponent: function (cmp, event) {
  //   cmp.set("v.showModal", false);
  //   /*
  //       //Get the parameter(modal) you defined in the event, and destroy the component
  //       var component = event.getParam("component");
  //       component.destroy();
  //       */
  // }
});
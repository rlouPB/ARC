/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-expressions */
({
  doInit: function (cmp, event, helper) {
    console.log("CreateMessageController doInit...");
    let userLookupFilter = [
      {
        fieldName: "IsActive",
        condition: "=",
        value: true
      },
      {
        fieldName: "UserType",
        condition: "=",
        value: "Standard"
      },
      {
        fieldName: "UserRoleId",
        condition: "!=",
        value: ""
      }
    ];

    let groupLookupFilter = [
      {
        fieldName: "Active__c",
        condition: "=",
        value: true
      },
      {
        fieldName: "Primary_Function__c",
        condition: "=",
        value: "Staff"
      }
    ];

    cmp.set("v.userLookupFilter", userLookupFilter);
    cmp.set("v.groupLookupFilter", groupLookupFilter);

    let messageId = cmp.get("v.messageId");

    if (cmp.get("v.type") === "Clinical Alert") {
      cmp.set("v.messageId", "");
    }

    if (messageId !== "") {
      helper.reply(cmp, event, messageId);
    }

    helper.addGroup(cmp);
  },

  handleUserEvent: function (cmp, event, helper) {
    console.log("CreateMessageController handleUserEvent...");
    console.log("CreateMessageController handleUserEvent params: " + JSON.stringify(event.getParams()));

    let type = event.getParam("type");
    if (type === "Send") {
      if (cmp.get("v.type") === "Clinical Alert") {
        helper.alert(cmp, event);
      } else {
        helper.send(cmp, event);
      }
    }
  },

  handleSelectedUserChange: function (cmp, event, helper) {
    console.log("CreateMessageController handleSelectedUserChange...");
    helper.dirty(cmp, event);
    helper.addUser(cmp);
  },

  handleSelectedGroupChange: function (cmp, event, helper) {
    console.log("CreateMessageController handleSelectedGroupChange...");
    helper.dirty(cmp, event);
    helper.addGroup(cmp);
  },

  handleUserPillRemove: function (cmp, event, helper) {
    console.log("CreateMessageController handleUserPillRemove...");
    let name = event.getParam("item").name;
    let items = cmp.get("v.userPillItems");
    let item = event.getParam("index");
    items.splice(item, 1);
    cmp.set("v.userPillItems", items);
  },

  handleGroupPillRemove: function (cmp, event, helper) {
    console.log("CreateMessageController handleGroupPillRemove...");
    let name = event.getParam("item").name;
    let items = cmp.get("v.groupPillItems");
    let item = event.getParam("index");
    items.splice(item, 1);
    cmp.set("v.groupPillItems", items);
  },

  onRender: function (cmp, event, helper) {
    console.log("CreateMessageController onRender...");
  },

  acquireFocus: function (cmp) {
    console.log("CreateMessageController acquireFocus...");
    if (!cmp.get("v.loading")) {
      setTimeout(
        $A.getCallback(() => {
          try {
            cmp.isValid() && cmp.find("inputBody").focus();
          } catch (e) {}
        }),
        500
      );
    }
  }
});
/* eslint-disable no-unused-expressions */
({
  send: function (cmp, event) {
    console.log("CreateMessageHelper send...");
    cmp.set("v.loading", true);
    let message = {
      type: cmp.get("v.type"),
      subject: cmp.get("v.subject"),
      body: cmp.get("v.body"),
      patientNoteId: cmp.get("v.patientNoteId"),
      isReply: cmp.get("v.isReply"),
      replied: cmp.get("v.replied"),
      messageProfile: cmp.get("v.messageProfile")
    };
    let userRecipients = cmp.get("v.userPillItems").map((r) => r.value);
    let groupRecipients = cmp.get("v.groupPillItems").map((r) => r.value);


    if (userRecipients.length === 0 && groupRecipients.length === 0) 
    {
      cmp.find("notifLib").showToast({
        variant: "error",
        title: "Error!",
        message: "A recipient is required."
      });
      cmp.set('v.loading', false);
      return;
    }

    let action = cmp.get("c.send2");

    action.setParams({
      sClientRecipients: null,
      sUserRecipients: JSON.stringify(userRecipients),
      sClientGroupRecipients: null,
      sUserGroupRecipients: JSON.stringify(groupRecipients),
      sMessage: JSON.stringify(message),
      sIsReply: JSON.stringify(cmp.get("v.isReply")),
      sReplied: cmp.get("v.replied"),
      sMessageProfile: "Staff",
      sHasNotification: false,
      sNotificationMessage: null
    });

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        cmp.find("notifLib").showToast({
          variant: "success",
          title: "Success!",
          message: "Message sent successfully!"
        });

        cmp.find("overlayLib").notifyClose();

        let e = $A.get("e.c:MessageEvent");

        e.setParams({
          type: cmp.get("v.type")
        });

        e.fire();
        cmp.set("v.loading", false);
      } else if (state === "ERROR") {
        let errors = response.getError();
        cmp.find("notifLib").showToast({
          variant: "error",
          title: "Error!",
          message: errors[0].message
        });
      }
    });

    $A.enqueueAction(action);
  },

  reply: function (cmp, event, id) {
    console.log("CreateMessageHelper reply...");
    let type = cmp.get("v.type");

    cmp.set("v.loading", true);
    cmp.set("v.isReply", true);
    cmp.set("v.replied", true);

    let action = cmp.get("c.getMessageDetails");

    action.setParams({
      messageId: id
    });

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        let message = response.getReturnValue();
        let userPillItems = [];
        let groupPillItems = [];
        let replySpacer = "<br/><br/>";
        replySpacer += "--------------------------";
        replySpacer += "<br/><br/>";

        if (message.Body__c !== null && message.Body__c !== undefined) {
          cmp.set("v.body", replySpacer.concat(message.Body__c));
        } else {
          cmp.set("v.body", message.Body__c);
        }
        // console.log("body: " + body);
        // Move v.body (message.Body__c) to read-only area below text area
        cmp.set("v.subject", "RE: " + message.Subject__c);

        userPillItems.push({
          label: message.Owner.Name,
          value: message.Owner.Id
        });

        if (cmp.get("v.label") === "Reply All") {
          if (message.Message_Recipients__r != null && type !== "Clinical Alert") {
            message.Message_Recipients__r.forEach((r) => {
              if (r.User__c) {
                userPillItems.push({
                  label: r.User__r.Name,
                  value: r.User__c
                });
              } else {
                groupPillItems.push({
                  label: r.Group_Membership__r.Name,
                  value: r.Group_Membership__c
                });
              }
            });
          }
        }

        cmp.set("v.userPillItems", userPillItems);
        cmp.set("v.groupPillItems", groupPillItems);
        cmp.set("v.loading", false);
      } else if (state === "ERROR") {
        let errors = response.getError();
        cmp.find("notifLib").showToast({
          variant: "error",
          title: "Error!",
          message: errors[0].message
        });
      }
    });

    $A.enqueueAction(action);
  },

  addUser: function (cmp) {
    console.log("CreateMessageHelper addUser...");
    let selectedUser = cmp.get("v.selectedUser");

    if (selectedUser && selectedUser.value) {
      let userPillItems = cmp.get("v.userPillItems");
      if (Array.isArray(userPillItems)) {
        let hasItem = false;
        userPillItems.forEach((element) => {
          if (element.name === selectedUser.value) {
            hasItem = true;
          }
        });
        if (!hasItem) {
          userPillItems.push({
            label: selectedUser.label,
            value: selectedUser.value
          });
          cmp.set("v.userPillItems", userPillItems);
        }
      }
    }
  },

  addGroup: function (cmp) {
    console.log("CreateMessageHelper addGroup...");
    let selectedGroup = cmp.get("v.selectedGroup");

    if (selectedGroup && selectedGroup.value) {
      let groupPillItems = cmp.get("v.groupPillItems");
      if (Array.isArray(groupPillItems)) {
        let hasItem = false;
        groupPillItems.forEach((element) => {
          if (element.name === selectedGroup.value) {
            hasItem = true;
          }
        });
        if (!hasItem) {
          groupPillItems.push({
            label: selectedGroup.label,
            value: selectedGroup.value
          });
          cmp.set("v.groupPillItems", groupPillItems);
        }
      }
    }
  },
  dirty: function (cmp) {
    console.log("CreateMessageHelper dirty...");
    let e = $A.get("e.c:MessageEvent");

    e.setParams({
      type: "Dirty"
    });

    e.fire();
  },
  alert: function (cmp, event) {
    console.log("CreateMessageHelper alert...");
    let message = {
      type: cmp.get("v.type"),
      subject: cmp.get("v.subject"),
      body: cmp.get("v.body"),
      patient: cmp.get("v.clientId"),
      patientNoteId: cmp.get("v.patientNoteId"),
      isReply: cmp.get("v.isReply"),
      messageProfile: cmp.get("v.messageProfile")
    };

    let userRecipients = cmp.get("v.userPillItems").map((r) => r.value);
    let groupRecipients = cmp.get("v.groupPillItems").map((r) => r.value);

    let action = cmp.get("c.send2");

    action.setParams({
      sClientRecipients: null,
      sUserRecipients: JSON.stringify(userRecipients),
      sClientGroupRecipients: null,
      sUserGroupRecipients: JSON.stringify(groupRecipients),
      sMessage: JSON.stringify(message),
      sIsReply: JSON.stringify(cmp.get("v.isReply")),
      sMessageProfile: "Staff",
      sHasNotification: false,
      sNotificationMessage: null
    });

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        cmp.find("notifLib").showToast({
          variant: "success",
          title: "Success!",
          message: "Alert sent successfully!"
        });

        cmp.find("overlayLib").notifyClose();

        let e = $A.get("e.c:MessageEvent");

        e.setParams({
          type: cmp.get("v.type")
        });

        e.fire();
      } else if (state === "ERROR") {
        let errors = response.getError();
        cmp.find("notifLib").showToast({
          variant: "error",
          title: "Error!",
          message: errors[0].message
        });
      }
    });

    $A.enqueueAction(action);
  }
});
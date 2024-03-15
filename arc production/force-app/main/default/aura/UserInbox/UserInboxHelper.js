/* eslint-disable no-redeclare */
/* eslint-disable no-undef */
/* eslint-disable guard-for-in */
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  callAlertMethod: function (cmp, event) {
    console.log("UserInboxHelper callAlertMethod...");
    cmp.set("v.messageType", "Alert");
    this.updateMessageCount(cmp, "Clinical Alert");
    
    

    // var childCmp = cmp.find("alert");
    // childCmp.reInit();
  },

  callInboxMethod: function (cmp, event) {
    console.log("UserInboxHelper callInboxMethod...");
    cmp.set("v.messageType", "Inbox");
    this.updateMessageCount(cmp, "Standard Message");
    // var childCmp = cmp.find("standard");
    // childCmp.reInit();
  },

  callRecycleMethod: function (cmp, event) {
    console.log("UserInboxHelper callRecycleMethod...");
    cmp.set("v.messageType", "Deleted");
    this.updateMessageCount(cmp, "Deleted Message");
    // var childCmp = cmp.find("deleted");
    // childCmp.reInit();
  },

  callSentMethod: function (cmp, event) {
    console.log("UserInboxHelper callSentMethod...");
    cmp.set("v.messageType", "Sent");
    this.updateMessageCount(cmp, "Sent Message");
    // var childCmp = cmp.find("sentMsg");
    // childCmp.reInit();
  },

  getFamilyMessaging: function (cmp) {
    console.log("UserInboxHelper getFamilyMessaging...");
    let action = cmp.get("c.hasFamilyPortalMessaging");
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        let hasFamily = response.getReturnValue();
        cmp.set("v.familyMessaging", hasFamily);
      }
    });
    $A.enqueueAction(action);
  },

  initializeMessageCount: function (cmp) {
    console.log("UserInboxHelper initializeMessageCount...");
    let action = cmp.get("c.getMessageCountsMap");

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        var countMap = response.getReturnValue();
        cmp.set("v.messageCountMap", countMap);
        this.updateMessageCount(cmp, "All");
      } else if (state === "ERROR") {
        let errors = response.getError();
      }
    });

    $A.enqueueAction(action);
  },

  getPatientMessaging: function (cmp) {
    console.log("UserInboxHelper getPatientMessaging...");
    let action = cmp.get("c.hasPatientPortalMessaging");
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        let hasPatient = response.getReturnValue();
        cmp.set("v.patientMessaging", hasPatient);
      }
    });
    $A.enqueueAction(action);
  },

  getUnread: function (cmp, type, unreadType) {
    console.log("UserInboxHelper getUnread...");
    let action = cmp.get("c.getUnread");

    action.setParams({
      type: type
    });

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        let unread = response.getReturnValue();
        cmp.set(`v.${unreadType}`, unread);

        if (type !== "Clinical Alert") {
          if (cmp.find("inbox")) {
            var tabLabel = cmp.find("inbox").get("v.label");
            tabLabel[0].set("v.value", "Inbox (" + unread + ")");
          }
          this.getUnread(cmp, "Clinical Alert", "alertsUnread");
        } else {
          if (cmp.find("alerts")) {
            var tabLabel = cmp.find("alerts").get("v.label");
            tabLabel[0].set("v.value", "Alerts (" + unread + ")");
          }
          cmp.set("v.loading", false);
        }
      } else if (state === "ERROR") {
        console.error("getUnread error: ", error);
      }
    });

    $A.enqueueAction(action);
  },

  handleEvent: function (cmp, received) {
    console.log("UserInboxHelper handleEvent... " + JSON.stringify(received));
    try {
      let payload = received.data.payload;
      let recipient = payload.Recipient__c;
      let messageType = payload.Message_Type__c;

      if (recipient === $A.get("$SObjectType.CurrentUser.Id")) {
        if (messageType === "Clinical Alert") {
          let unread = cmp.get("v.alertsUnread");
          unread = unread + 1;
          cmp.set("v.alertsUnread", unread);
          var tabLabel = cmp.find("alerts").get("v.label");
          tabLabel[0].set("v.value", "Alerts (" + unread + ")");
        } else if (messageType === "Standard Message") {
          let unread = cmp.get("v.inboxUnread");
          unread = unread + 1;
          cmp.set("v.inboxUnread", unread);
          var tabLabel = cmp.find("inbox").get("v.label");
          tabLabel[0].set("v.value", "Inbox (" + unread + ")");
        }
      }
    } catch (e) {
      //error here will be null reference on cmp or cmp.find('inbox') or cmp.find('alerts')
      console.error(e);
    }
  },

  showMessageModal: function (cmp, type, audience) {
    console.log("UserInboxHelper showMessageModal...");

    var createMessage;
    var createMessageFooter;

    if (audience === "Staff") {
      $A.createComponents([["c:CreateMessage", { type: type }], ["c:CreateMessageFooter"]], function (components, status) {
        if (status === "SUCCESS") {
          createMessage = components[0];
          createMessageFooter = components[1];

          cmp.find("overlayLibUserInbox").showCustomModal({
            header: "Create Message",
            footer: createMessageFooter,
            body: createMessage,
            showCloseButton: false
          });
        }
      });
    } else if (audience === "Family") {
      $A.createComponents([["c:CreateFamilyMessage", { type: type, audience: audience }], ["c:CreateFamilyMessageFooter"]], function (components, status) {
        if (status === "SUCCESS") {
          createMessage = components[0];
          createMessageFooter = components[1];

          cmp.find("overlayLibUserInbox").showCustomModal({
            header: "Create " + audience + "-Focused Message",
            footer: createMessageFooter,
            body: createMessage,
            showCloseButton: false
          });
        }
      });
    } else if (audience === "Patient") {
      $A.createComponents([["c:CreateClientMessage", { type: type, audience: audience }], ["c:CreateClientMessageFooter"]], function (components, status) {
        if (status === "SUCCESS") {
          createMessage = components[0];
          createMessageFooter = components[1];

          cmp.find("overlayLibUserInbox").showCustomModal({
            header: "Create " + audience + "-Focused Message",
            footer: createMessageFooter,
            body: createMessage,
            showCloseButton: false
          });
        }
      });
    }
  },

  subscribe: function (cmp, event) {
    console.log("UserInboxHelper subscribe...");
    const empApi = cmp.find("empApi");

    empApi.onError(
      $A.getCallback((error) => {
        console.error("EMP API error: ", error);
      })
    );

    const channel = "/event/SentMessageEvent__e";

    const replayId = -1;

    empApi
      .subscribe(
        channel,
        replayId,
        $A.getCallback((eventReceived) => {
          this.handleEvent(cmp, eventReceived);
        })
      )
      .then((subscription) => {});
  },

  updateMessageCount: function (cmp, type) 
  {
    console.log("UserInboxHelper updateMessageCount...");
    let msgType = cmp.get("v.messageType");
    let remainder = 0;
    let maxPage = 0;
    let maxRecord = cmp.get("v.selectedCount");
    let offset = cmp.get("v.offset");

    this.filter(cmp, cmp.get("v.messageType"), cmp.get("v.messageFilter"), cmp.get("v.messageProfileFilter"));

    let selectedView = cmp.get("v.selectedView");

    if (type === "Sent Message" || type === "SentMsg") {
      maxRecord = cmp.get("v.messageCountMap")[cmp.get("v.selectedView")];
      remainder = maxRecord % offset;
      maxPage = Math.floor(maxRecord / offset);

      if (remainder !== 0) {
        cmp.set("v.sentMsgMaxPage", maxPage);
      } else {
        cmp.set("v.sentMsgMaxPage", maxPage - 1);
      }
    } else if (type === "Deleted Message") {
      maxRecord = cmp.get("v.messageCountMap")[cmp.get("v.selectedView")];
      remainder = maxRecord % offset;
      maxPage = Math.floor(maxRecord / offset);

      if (remainder !== 0) {
        cmp.set("v.deletedMaxPage", maxPage);
      } else {
        cmp.set("v.deletedMaxPage", maxPage - 1);
      }
    } else if (type === "Clinical Alert") {
      var alertFilter = cmp.get('v.alertFilter');
      if (alertFilter == 'All') alertFilter = '';
      cmp.set("v.selectedView", alertFilter + "ClinicalAlert");
      maxRecord = cmp.get("v.messageCountMap")[cmp.get("v.selectedView")];
      remainder = maxRecord % offset;
      maxPage = Math.floor(maxRecord / offset);

      if (remainder !== 0) {
        cmp.set("v.alertMaxPage", maxPage);
      } else {
        cmp.set("v.alertMaxPage", maxPage - 1);
      }
    } else {
      maxRecord = cmp.get("v.messageCountMap")[cmp.get("v.selectedView")];
      remainder = maxRecord % offset;
      maxPage = Math.floor(maxRecord / offset);

      if (remainder !== 0) {
        cmp.set("v.standardMaxPage", maxPage);
      } else {
        cmp.set("v.standardMaxPage", maxPage - 1);
      }
    }

    cmp.set("v.selectedCount", maxRecord);
    cmp.set("v.currentFrom", 1);

    if (maxRecord <= offset) {
      cmp.set("v.disableNext", true);
      cmp.set("v.currentTo", maxRecord);
    } else {
      cmp.set("v.disableNext", false);
      cmp.set("v.currentTo", offset);
    }

    if (maxRecord === undefined) {
      cmp.set("v.disableNext", true);
    }
  },

  filter: function (cmp, type, msgType, profileType) {
    console.log("UserInboxHelper filter...");
    if (msgType === "Unread") {
      type = "Unread";
    }

    if (profileType === "AllTypes") {
      profileType = "Messages";
    }

    cmp.set("v.selectedView", type + profileType);
  }
});
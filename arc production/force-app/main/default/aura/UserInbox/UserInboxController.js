/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  init: function (cmp, event, helper) {
    console.log("UserInboxController init...");
    cmp.set("v.loading", true);
    // cmp.set("v.previousSelectedTabId", cmp.get("v.selectedTabId"));
    helper.getFamilyMessaging(cmp);
    helper.getPatientMessaging(cmp);
    helper.getUnread(cmp, "Standard Message", "inboxUnread");
    helper.subscribe(cmp, event);
    helper.initializeMessageCount(cmp, "All");
  },

  previous: function (cmp, event, helper) {
    console.log("UserInboxController previous...");
    cmp.set("v.disablePrevious", true);

    let type = event.getSource().get("v.value");

    if (type === "sent") {
      type = "sentMsg";
    }

    let box = cmp.find(type);
    let offset = cmp.get("v.offset");
    let maxRecord = cmp.get("v.selectedCount");
    let currentFrom = cmp.get("v.previousFrom");
    let currentTo = cmp.get("v.previousTo");
    let previousFrom = 0;
    let previousTo = 0;
    let currentPage = cmp.get(`v.${type}CurrentPage`);
    let maxPage = cmp.get(`v.${type}MaxPage`);
    let nextPage = currentPage;
    currentPage--;

    cmp.set(`v.${type}CurrentPage`, currentPage);

    let previousPage = currentPage - 1;

    if (currentPage > 0) {
      if (currentPage <= maxPage) {
        cmp.set("v.currentFrom", currentFrom);
        cmp.set("v.currentTo", currentTo);

        previousFrom = currentFrom - offset;
        previousTo = currentTo - offset;

        cmp.set("v.previousFrom", previousFrom);
        cmp.set("v.previousTo", previousTo);

        cmp.set("v.disablePrevious", false);
        cmp.set("v.disableNext", false);
      }
    } else {
      cmp.set("v.previousFrom", previousFrom);
      cmp.set("v.previousTo", previousTo);
      cmp.set("v.currentFrom", 1);

      if (maxRecord <= offset) {
        currentTo = maxRecord;
        cmp.set("v.disableNext", true);
      } else {
        currentTo = offset;
        cmp.set("v.disableNext", false);
      }
    }

    cmp.set("v.currentTo", currentTo);

    console.log("pagination v.previousFrom: " + cmp.get("v.previousFrom"));
    console.log("pagination v.previousTo: " + cmp.get("v.previousTo"));
    console.log("pagination v.currentFrom: " + cmp.get("v.currentFrom"));
    console.log("pagination v.currentTo: " + cmp.get("v.currentTo"));
    console.log("pagination v.disablePrevious: " + cmp.get("v.disablePrevious"));
    console.log("pagination v.disableNext: " + cmp.get("v.disableNext"));
    console.log("pagination currentPage: " + currentPage);
    console.log("pagination maxPage: " + maxPage);

    let result = box.previous(currentPage);
  },

  next: function (cmp, event, helper) {
    console.log("UserInboxController next...");
    cmp.set("v.disablePrevious", false);

    let type = event.getSource().get("v.value");

    if (type === "sent") {
      type = "sentMsg";
    }

    let box = cmp.find(type);
    let offset = cmp.get("v.offset");
    let maxRecord = cmp.get("v.selectedCount");
    let currentFrom = cmp.get("v.currentFrom");
    let currentTo = cmp.get("v.currentTo");
    let currentPage = cmp.get(`v.${type}CurrentPage`);
    let maxPage = cmp.get(`v.${type}MaxPage`);
    let previousPage = currentPage;
    currentPage++;

    let nextPage = currentPage + 1;

    cmp.set(`v.${type}CurrentPage`, currentPage);
    cmp.set("v.previousFrom", currentFrom);
    cmp.set("v.previousTo", currentTo);

    if (maxPage - currentPage > 0) {
      currentFrom = currentFrom + offset;
      currentTo = currentTo + offset;
      cmp.set("v.disableNext", false);
    } else {
      currentFrom = currentFrom + offset;
      currentTo = maxRecord;
      cmp.set("v.disableNext", true);
    }

    cmp.set("v.currentFrom", currentFrom);
    cmp.set("v.currentTo", currentTo);

    console.log("pagination v.previousFrom: " + cmp.get("v.previousFrom"));
    console.log("pagination v.previousTo: " + cmp.get("v.previousTo"));
    console.log("pagination v.currentFrom: " + cmp.get("v.currentFrom"));
    console.log("pagination v.currentTo: " + cmp.get("v.currentTo"));
    console.log("pagination v.disablePrevious: " + cmp.get("v.disablePrevious"));
    console.log("pagination v.disableNext: " + cmp.get("v.disableNext"));
    console.log("pagination currentPage: " + currentPage);
    console.log("pagination maxPage: " + maxPage);

    let result = box.next(currentPage);
  },

  //run on making tab active
  activateTab: function (cmp, event, helper) {
    console.log("UserInboxController activateTab...");
    var previousSelectedTabId = cmp.get("v.previousSelectedTabId");
    var src = event.getSource().get("v.id");

    //run if this is a change of active tab
    if (previousSelectedTabId !== src) {
      //on switch, make sure it calls/fetches the server for a new allData, but don't let it do that twice. if activeTab is not changing, don't refresh the list
      //reInit UserMessages component for the new tab if necessary
      cmp.set("v.disablePrevious", true);
      cmp.set("v.messageFilter", "All");
      cmp.set("v.messageProfileFilter", "AllTypes");

      switch (src) {
        case "inbox":
          cmp.set("v.standardCurrentPage", 0);
          helper.callInboxMethod(cmp, event);
          break;

        case "alerts":
          cmp.set("v.alertCurrentPage", 0);
          helper.callAlertMethod(cmp, event);
          break;

        case "sent":
          cmp.set("v.sentMsgCurrentPage", 0);
          helper.callSentMethod(cmp, event);
          break;

        case "recycle":
          cmp.set("v.deletedCurrentPage", 0);
          helper.callRecycleMethod(cmp, event);
          break;

        default:
      }
    }

    cmp.set("v.previousSelectedTabId", src);
  },

  emptyRecycleBin: function (cmp, event, helper) {
    console.log("UserInboxController emptyRecycleBin...");
    let bin = cmp.find("deleted");
    bin.emptyBin(true);
  },

  handleClinicalAlert: function (cmp, event, helper) {
    console.log("UserInboxController handleClinicalAlert...");
    helper.showMessageModal(cmp, "Clinical Alert");
  },

  handleCustomMessage: function (cmp, event, helper) {
    console.log("UserInboxController handleCustomMessage...");
    let audience = event.getParam("value");

    if (audience === "Family") {
      helper.showMessageModal(cmp, "Standard Message", "Family");
    } else if (audience === "Patient") {
      helper.showMessageModal(cmp, "Standard Message", "Patient");
    }
  },

  handlePageEvent: function (cmp, event, helper) {
    console.log("UserInboxController handlePageEvent...");
    let type = event.getParam("type");
    if (event.getParam('messageCountMap'))
    {
      cmp.set('v.messageCountMap', event.getParam('messageCountMap'));
      helper.updateMessageCount(cmp, type);
    } else
    {
      let page = event.getParam("page");

      if (type !== "") {
        if (type === "Standard Message") {
          cmp.set("v.standardCurrentPage", page);
        }

        if (type === "Sent Messages") {
          cmp.set("v.sentMsgCurrentPage", page);
        }

        if (type === "Deleted Messages") {
          cmp.set("v.deletedCurrentPage", page);
        }
      }
    }
  },

  handleStandardMessage: function (cmp, event, helper) {
    console.log("UserInboxController handleStandardMessage...");
    helper.showMessageModal(cmp, "Standard Message", "Staff");
  },

  handleUnreadEvent: function (cmp, event) {
    console.log("UserInboxController handleUnreadEvent...");
    let type = event.getParam("type");
    let count = event.getParam("count");

    if (type !== "") {
      if (type === "Standard Message") {
        cmp.set("v.inboxUnread", count);
        if (cmp.find("inbox")) {
          var tabLabel = cmp.find("inbox").get("v.label");
          tabLabel[0].set("v.value", "Inbox (" + count + ")");
        }
      }

      if (type === "Clinical Alert") {
        cmp.set("v.alertsUnread", count);
        if (cmp.find("alerts")) {
          var tabLabel = cmp.find("alerts").get("v.label");
          tabLabel[0].set("v.value", "Alerts (" + count + ")");
        }
      }

      let e = $A.get("e.c:UtilityBarEvent");

      e.setParams({
        unreadAlerts: cmp.get("v.alertsUnread"),
        unreadMessages: cmp.get("v.inboxUnread")
      });

      e.fire();

      //   cmp.find("overlayLibViewMsg").notifyClose();
    }
  },

  onChangeSearchText: function (cmp, event) {
    // console.log("UserInboxController onChangeSearchText...");
    let container = event.target.id;

    var queryTerm = cmp.find(`${container}-search`).get("v.value");
    //if (!queryTerm || queryTerm.length <= 2) return;
    if (!queryTerm) queryTerm = '';
    cmp.set(`v.${container}Searching`, true);

    // if (container === "sentMsg") {
    //   let box = cmp.find("sentMsg");
    //   let result = box.searchInbox(queryTerm);
    //   cmp.set(`v.${container}Searching`, result);
    // } else {
    let box = cmp.find(container);
    let result = box.searchInbox(queryTerm);
    cmp.set(`v.${container}Searching`, result);
    // }
  },

  updateAlertFilter: function (cmp, event, helper) {
    console.log("UserInboxController updateAlertFilter...");
    let type = event.getSource().get("v.value");
    cmp.set("v.alertFilter", type);
    let alert = cmp.find("alert");
    alert.filterMessages(type);
  },

  updateMessageFilter: function (cmp, event, helper) {
    console.log("UserInboxController updateMessageFilter...");
    let type = event.getSource().get("v.value");

    if (type === "sent") {
      type = "sentMsg";
    }

    cmp.set("v.messageFilter", type);
    cmp.set(`v.${type}CurrentPage`, 0);
    let currentPage = cmp.get(`v.${type}CurrentPage`);
    helper.updateMessageCount(cmp, type);
    let standard = cmp.find("standard");
    standard.filterMessages(type);
  },

  updateMessageProfileFilter: function (cmp, event, helper) {
    console.log("UserInboxController updateMessageProfileFilter...");
    let type = event.getSource().get("v.value");

    cmp.set("v.messageProfileFilter", type);
    cmp.set(`v.${type}CurrentPage`, 0);
    let currentPage = cmp.get(`v.${type}CurrentPage`);
    helper.updateMessageCount(cmp, type);

    if (cmp.get("v.messageType") === "Inbox") {
      let standard = cmp.find("standard");
      standard.filterMessages(type);
    } else if (cmp.get("v.messageType") === "Sent") {
      let sent = cmp.find("sentMsg");
      sent.filterMessages(type);
    } else if (cmp.get("v.messageType") === "Deleted") {
      let deleted = cmp.find("deleted");
      deleted.filterMessages(type);
    }
  }
});
/* eslint-disable no-unused-expressions */
({
  subscribe: function (cmp, event) {
    const empApi = cmp.find("empApi");

    empApi.onError(
      $A.getCallback((error) => {
        console.error("EMP API error: ", error);
      })
    );

    this.getUnread(cmp);

    const channel = "/event/SentMessageEvent__e";

    const replayId = -1;

    empApi
      .subscribe(
        channel,
        replayId,
        $A.getCallback((eventReceived) => {
          this.check(cmp, eventReceived);
        })
      )
      .then((subscription) => {
        console.log("Subscribed to channel ", subscription.channel);
      });
  },
  check: function (cmp, received) {
    let payload = received.data.payload;

    let recipient = payload.Recipient__c;

    let messageType = payload.Message_Type__c;

    if (recipient == cmp.get("v.activeUser")) {
      let unread = cmp.get("v.unread");

      if (messageType == "Standard Message" && cmp.get("v.barId") == "messages") {
        var utilityAPI = cmp.find("messages");

        utilityAPI.setUtilityHighlighted({ highlighted: true });

        unread = unread + 1;

        cmp.set("v.unread", unread);

        utilityAPI.setUtilityLabel({ label: "Messages" + " (" + unread + ")" });

        cmp.set("v.badgeMessage", "Unread Messages" + " (" + unread + ")");
      }

      if (messageType == "Clinical Alert" && cmp.get("v.barId") == "alerts") {
        var utilityAPI = cmp.find("alerts");

        utilityAPI.setUtilityHighlighted({ highlighted: true });

        unread = unread + 1;

        cmp.set("v.unread", unread);

        utilityAPI.setUtilityLabel({ label: "Alerts" + " (" + unread + ")" });

        cmp.set("v.badgeMessage", "Unread Alerts" + " (" + unread + ")");
      }
    }
  },
  getUnread: function (cmp) {
    let action = cmp.get("c.getUnread");

    action.setParams({
      type: cmp.get("v.type")
    });

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        let unread = response.getReturnValue();

        cmp.set("v.unread", unread);

        let barId = cmp.get("v.barId");

        let utilityAPI = cmp.find(barId);

        let type = cmp.get("v.type");

        if (type == "Standard Message") {
          var label = "Messages";
        } else {
          var label = "Alerts";
        }

        utilityAPI.setUtilityLabel({ label: label + " (" + unread + ")" });

        this.sendUnread(type, unread);

        if (unread > 0) {
          cmp.set("v.badgeMessage", "Unread " + label + " (" + unread + ")");
        }
      } else if (state === "ERROR") {
      }
    });

    $A.enqueueAction(action);
  },
  sendUnread: function (type, count) {
    let e = $A.get("e.c:MessageUnreadEvent");

    e.setParams({
      count: count,
      type: type
    });

    e.fire();
  },
  registerUtilityHandler: function (cmp, event, barId) {
    const that = this;

    const fetch = function () {
      that.getMessages(cmp, event);
    };

    barId.onUtilityClick({ eventHandler: fetch });
  },
  getMessages: function (cmp, event) {
    let action = cmp.get("c.getMessages");

    action.setParams({
      type: cmp.get("v.type"),
      searchTerm: "",
      page: 0,
      sortAsc: "DESC",
      field: "CreatedDate",
      unreadOnly: true,
      patientId: ""
    });

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        let messages = response.getReturnValue();

        messages = messages.map((message) => {
          return {
            id: message.Id,
            sent: message.Message__r.CreatedDate,
            from: message.Message__r.Owner.Name,
            subject: message.Message__r.Subject__c
          };
        });

        cmp.set("v.data", messages);
      }
    });

    $A.enqueueAction(action);
  },
  sendPreviewEvent: function (cmp, event) {},
  showViewMessageModal: function (cmp, message) {
    var createMessage;

    $A.createComponents([["c:ViewMessage", message]], function (components, status) {
      if (status === "SUCCESS") {
        createMessage = components[0];

        cmp.find("overlayLib").showCustomModal({
          body: createMessage,
          showCloseButton: true
        });
      }
    });
  }
});
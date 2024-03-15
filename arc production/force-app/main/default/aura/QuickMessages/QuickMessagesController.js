/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  init: function (cmp, event, helper) {
    let user = $A.get("$SObjectType.CurrentUser.Id");
    cmp.set("v.activeUser", user);
    cmp.set("v.badgeMessage", "No Unread Alerts");

    $A.createComponent(
      "lightning:utilityBarAPI",
      {
        "aura:id": cmp.get("v.barId")
      },
      function (barId, status, errorMessage) {
        if (status === "SUCCESS") {
          cmp.set("v.utilityId", cmp.get("v.barId"));
          console.log("v.utilityId: " + cmp.get("v.utilityId"));

          var body = cmp.get("v.body");

          body.push(barId);

          cmp.set("v.body", body);

          helper.registerUtilityHandler(cmp, event, barId);

          helper.subscribe(cmp, event);

          helper.getUnread(cmp);
        }
      }
    );
  },

  handleUtilityBarEvent: function (cmp, event, helper) {
    console.log("event.getParams: " + JSON.stringify(event.getParams()));
    // helper.getUnread(cmp);
    let barId = cmp.get("v.barId");
    let utilityAPI = cmp.find(barId);
    if (barId == "messages") {
      utilityAPI.setUtilityLabel({ label: "Messages (" + event.getParam("unreadMessages") + ")" });
    } else {
      utilityAPI.setUtilityLabel({ label: "Alerts (" + event.getParam("unreadAlerts") + ")" });
    }
  },

  handleViewMessage: function (cmp, event) {
    event.preventDefault();

    let navService = cmp.find("navService");

    let pageReference = {
      type: "standard__navItemPage",
      attributes: {
        apiName: "Messaging"
      }
    };

    cmp.set("v.pageReference", pageReference);

    navService.navigate(pageReference);

    cmp.set("v.badgeMessage", "No new messages");

    cmp.set("v.newMessage", false);

    var utilityAPI = cmp.find(cmp.get("v.utilityId"));
    utilityAPI.minimizeUtility();
  },
  preview: function (cmp, event, helper) {
    let selectedItem = event.currentTarget;

    let messageId = selectedItem.dataset.id;

    helper.showViewMessageModal(cmp, { type: cmp.get("v.type"), id: messageId });
  }
});
/* eslint-disable no-unused-expressions */
/* eslint-disable vars-on-top */
({
  fetch: function (cmp, id, clientId) {
    console.log("ViewMessageHelper fetch...");
    cmp.set("v.loading", true);
    var newMessage;
    if (!id || id == "") {
      //don't call the server if the id is blank, just blank out v.message
      newMessage = {
        id: "",
        read: true,
        messageId: "",
        fromId: "",
        from: "",
        subject: "",
        sent: "",
        body: "",
        messageType: "",
        displayMore: false
      };
      cmp.set("v.message", newMessage);

      cmp.set("v.loading", false);
    } else {
      let action = cmp.get("c.preview");

      action.setParams({
        messageId: id,
        patientView: clientId != null && clientId != ""
      });

      action.setCallback(this, function (response) {
        let state = response.getState();

        if (state === "SUCCESS") {
          let message = response.getReturnValue();

          // console.log("message : ", message);

          if (message.allRecipients.length <= 1) {
            cmp.set("v.showReplyAll", false);
          } else {
            cmp.set("v.showReplyAll", true);
          }

          //if not patient view and there are recipients, concatenate recipient names
          if ((clientId == null || clientId == "") && message.allRecipients.length > 0) {
            var allGroups = message.allRecipients
              .filter(function (thisMessage) {
                return thisMessage.Added_As_Group_Member__c;
              })
              .map(function (thisMessage) {
                return thisMessage.Added_Under_Group_Name__c;
              });

            var uniqueGroups = [...new Set(allGroups)];

            var allRecipients = message.allRecipients
              .filter(function (thisMessage) {
                return !thisMessage.Added_As_Group_Member__c;
              })
              .map(function (thisMessage) {
                return thisMessage.User__r.Name;
              })
              .concat(uniqueGroups);

            let recipients = [];

            for (let groupName of allRecipients) {
              let memberNames = message.allRecipients
                .filter(function (thisUser) {
                  return thisUser.Added_Under_Group_Name__c == groupName;
                })
                .map(function (thisMessage) {
                  return thisMessage.User__r.Name;
                })
                .join(", ");

              recipients.push({
                name: groupName + ", ",
                members: memberNames
              });
            }

            var lastName = recipients[recipients.length - 1].name;

            recipients[recipients.length - 1].name = lastName.slice(0, lastName.length - 2);

            //Match Receipient with Current User
            var userId = $A.get("$SObjectType.CurrentUser.Id");
            let index = 0;

            for (let i = 0; i < message.allRecipients.length; i++) {
              const element = message.allRecipients[i];
              if (element.User__c == userId) {
                index = i;
                break;
              }
            }

            newMessage = {
              id: message.allRecipients[index].Id,
              read: message.allRecipients[index].Read__c,
              messageId: message.allRecipients[index].Message__c,
              to: recipients, // + (allRecipients.length > 4 ? ", " : ""),
              // allTo           : allRecipients.join(", "),
              displayMore: false,
              toCount: allRecipients.length,
              fromId: message.allRecipients[index].Message__r.OwnerId,
              from: message.allRecipients[index].Message__r.Owner.Name,
              subject: message.allRecipients[index].Message__r.Subject__c,
              sent: message.allRecipients[index].Message__r.CreatedDate,
              body: message.allRecipients[index].Message__r.Body__c,
              messageType: message.allRecipients[index].Message__r.Type__c
              // patientNoteId   : message.allRecipients[index].Message__r.Patient_Note__c,
              // patientNoteType   : message.allRecipients[index].Message__r.Patient_Note__r.Type__c,
            };
            var messageLinks = cmp.get('v.messageLinks');
            if (message.allRecipients[0].Message__r.Contact__c != null && message.allRecipients[0].Message__r.Contact__c != "") {
              newMessage.clientId = message.allRecipients[0].Message__r.Contact__c;
              newMessage.patientName = message.allRecipients[0].Message__r.Contact__r.Distinguished_Name__c;
              var patientUrl = "/" + newMessage.clientId;
              cmp.set("v.patientUrl", patientUrl);
              messageLinks.patientUrl = patientUrl;
              // messageLinks.patientName = message.Contact__r.Name;
              messageLinks.patientName = newMessage.patientName;
            }

            if (message.allRecipients[0].Message__r.Patient_Note__c != null && message.allRecipients[0].Message__r.Patient_Note__c != "") {
              newMessage.patientNoteId = message.allRecipients[0].Message__r.Patient_Note__c;
              newMessage.patientNoteType = message.allRecipients[0].Message__r.Patient_Note__r.Type__c;
              var patientNoteUrl = "/" + newMessage.patientNoteId;
              cmp.set("v.patientNoteUrl", patientNoteUrl);
              messageLinks.patientNoteUrl = patientNoteUrl;
              messageLinks.patientNoteType = message.allRecipients[0].Message__r.Patient_Note__r.Type__c;
            }

            // console.log("setting prescription. . .");
            // console.log("message2 : ", message);
            // console.log("message.allRecipients[0].Message__r.Prescription__c : ", message.allRecipients[0].Message__r.Prescription__c);

            if (message.allRecipients[0].Message__r.Prescription__c != null && message.allRecipients[0].Message__r.Prescription__c != "") {
              newMessage.prescriptionId = message.allRecipients[0].Message__r.Prescription__c;
              var prescriptionUrl = "/" + newMessage.prescriptionId;
              cmp.set("v.prescriptionUrl", "/" + newMessage.prescriptionId);
              messageLinks.prescriptionUrl = prescriptionUrl;
              messageLinks.prescriptionLabel = 'Prescription';
            }
            cmp.set('v.messageLinks', messageLinks);
            // console.log("newMessage.prescriptionId : ", newMessage.prescriptionId);
          } else {
            //patient view or no recipients

            newMessage = {
              id: message.Id,
              // read       : true,
              read: message.Read__c,
              messageId: message.Id,
              fromId: message.OwnerId,
              from: message.Owner.Name,
              subject: message.Subject__c,
              sent: message.CreatedDate,
              body: message.Body__c,
              messageType: message.Type__c,
              clientId: message.Contact__c,
              patientName: message.Contact__r.Name,
              patientNoteId: message.Patient_Note__c,
              patientNoteType: message.Patient_Note__r.Type__c,
              prescriptionId: message.Prescription__c
            };
          }

          cmp.set("v.message", newMessage);

          cmp.set("v.loading", false);
        } else if (state === "ERROR") {
          let errors = response.getError();
        }
        cmp.set("v.loading", false);
      });

      $A.enqueueAction(action);
    }
  },

  updateStatus: function (cmp, type, id, value) {
    console.log("ViewMessageHelper updateStatus...");
    // console.log("ViewMessageHelper updateStatus id: " + id);
    // console.log("ViewMessageHelper updateStatus type: " + type);
    // console.log("ViewMessageHelper updateStatus value: " + value);
    //only do this is there is a messageId to update the status of
    if (id && id != "") {
      let action = cmp.get("c.updateStatus");

      action.setParams({
        messageRecipientId: id,
        updateType: type,
        value: value
      });

      action.setCallback(this, function (response) {
        let state = response.getState();

        if (state === "SUCCESS") {
          let previousMessage = cmp.get("v.message");
          var newMessage = {};

          if (type == "Read") {
            newMessage = {
              id: previousMessage.id,
              read: value,
              to: previousMessage.to,
              fromId: previousMessage.fromId,
              from: previousMessage.from,
              subject: previousMessage.subject,
              sent: previousMessage.sent,
              body: previousMessage.body,
              messageType: previousMessage.messageType
            };
          }

          if (type == "Delete") {
            newMessage = {
              id: null,
              read: null,
              fromId: null,
              to: null,
              from: null,
              subject: null,
              body: null,
              messageType: previousMessage.messageType
            };

            cmp.find("notifLib").showToast({
              variant: "success",
              title: "Success!",
              message: "Message Deleted"
            });

            this.sendDelete(cmp, id);
          }
          this.getUnread(cmp);

          cmp.set("v.message", newMessage);

          if (type != "Delete") {
            let e = $A.get("e.c:MessagePreviewEvent");

            e.setParams({
              id: id,
              messageType: newMessage.messageType,
              update: true
            });

            e.fire();
          }
        }
      });

      $A.enqueueAction(action);
    }
  },

  getUnread: function (cmp) {
    console.log("ViewMessageHelper getUnread...");
    let action = cmp.get("c.getUnread");

    action.setParams({
      type: cmp.get("v.type")
    });

    action.setCallback(this, function (response) {
      let state = response.getState();

      if (state === "SUCCESS") {
        let unread = response.getReturnValue();

        // cmp.set('v.unread', unread);

        let type = cmp.get("v.type");

        if (type == "Standard Message") {
          var label = "Messages";
        } else {
          var label = "Alerts";
        }

        this.sendUnread(type, unread);

        // if(unread > 0) {
        //     cmp.set('v.badgeMessage', "Unread " + label  +  ' (' + unread + ')');
        // }
      }
    });

    $A.enqueueAction(action);
  },

  sendDelete: function (cmp, id) {
    console.log("ViewMessageHelper sendDelete...");
    let e = $A.get("e.c:MessageDeleteEvent");

    e.setParams({
      id: id
    });

    e.fire();
  },

  sendUnread: function (type, count) {
    console.log("ViewMessageHelper sendUnread...");
    let e = $A.get("e.c:MessageUnreadEvent");

    e.setParams({
      count: count,
      type: type
    });

    e.fire();
  },

  showMessageModal: function (cmp, message) {
    console.log("ViewMessage showMessageModal...");
    var createMessage;
    var createMessageFooter;

    $A.createComponents([["c:CreateMessage", message], ["c:CreateMessageFooter"]], function (components, status) {
      if (status === "SUCCESS") {
        createMessage = components[0];
        createMessageFooter = components[1];

        cmp.find("overlayLibViewMsg").showCustomModal({
          header: "Create Message",
          footer: createMessageFooter,
          body: createMessage,
          showCloseButton: false
        });
      }
    });
  }
});
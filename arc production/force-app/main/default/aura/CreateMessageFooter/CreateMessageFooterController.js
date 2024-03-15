/* eslint-disable no-unused-expressions */
({
    handleCancel: function(cmp, event, helper) {
        console.log("CreateMessageFooter handleCancel...");
        if (cmp.get("v.dirty")) {
            var cancelConfirmation;

            $A.createComponent(
                "c:MessageConfirmation", {},
                function(content, status) {
                    if (status === "SUCCESS") {
                        cancelConfirmation = content;
                        cmp.find("overlayLib").showCustomModal({
                            body: cancelConfirmation,
                            showCloseButton: false
                        });
                    }
                }
            );
        } else {
            let e = $A.get("e.c:MessageEvent");

            e.setParams({
                type: "Cancel"
            });

            e.fire();
        }
    },

    handleSend: function(cmp, event, helper) {
        console.log("CreateMessageFooter handleSend...");
        let e = $A.get("e.c:MessageEvent");

        e.setParams({
            type: "Send"
        });

        e.fire();
    },

    handleMessageEvent: function(cmp, event, helper) {
        console.log("CreateMessageFooter handleMessageEvent...");
        console.log(
            "CreateMessageFooter handleMessageEvent params: " +
            JSON.stringify(event.getParams())
        );

        let type = event.getParam("type");

        if (type === "Cancel") {
            cmp.find("overlayLib").notifyClose();
        }

        if (type === "Dirty") {
            cmp.set("v.dirty", true);
        }
    }
});
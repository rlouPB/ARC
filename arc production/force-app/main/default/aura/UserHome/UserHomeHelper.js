/* eslint-disable no-unused-expressions */
({
    setDisplay: function(component, chosenTab) {
        component.set("v.displayIRISHome", "false");
        component.set("v.displayMessages", "false");
        component.set("v.displayOpenItems", "false");
        component.set("v.displayPatients", "false");
        component.set("v.displayStaff", "false");
        component.set("v.displaySchedule", "false");
        component.set("v.displayVariance", "false");

        switch (chosenTab) {
            case "IRISHomeDiv":
                component.set("v.displayIRISHome", "true");
                break;
            case "MessagesDiv":
                component.set("v.displayMessages", "true");
                break;
            case "OpenItemsDiv":
                component.set("v.displayOpenItems", "true");
                break;
            case "PatientsDiv":
                component.set("v.displayPatients", "true");
                break;
            case "StaffDiv":
                component.set("v.displayStaff", "true");
                break;
            case "ScheduleDiv":
                component.set("v.displaySchedule", "true");
                break;
            case "VarianceDiv":
                component.set("v.displayVariance", "true");
                break;
            default:
                component.set("v.displayIRISHome", "true");
        }
    },

    getSummaryInfo: function(component) {
        var action = component.get("c.getSummaryInfo");

        var self = this;
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set(
                    "v.overdueTags",
                    actionResult.getReturnValue().overdueTags
                );
                component.set(
                    "v.dueNext7Days",
                    actionResult.getReturnValue().dueNext7Days
                );
                component.set("v.totalOpen", actionResult.getReturnValue().totalOpen);
                // These summary items are not currently supported
                // component.set('v.unreadAlerts', actionResult.getReturnValue().unreadAlerts);
                // component.set('v.unreadMessages', actionResult.getReturnValue().unreadMessages);
                // component.set('v.meetingsToday', actionResult.getReturnValue().meetingsToday);
            }
        });
        $A.enqueueAction(action);
    },

    apex: function(cmp, actionName, params) {
        let me = this;
        return new Promise(function(resolve, reject) {
            cmp.set("v.loading", true);
            let action = cmp.get(`c.${actionName}`);
            if (params) action.setParams(params);
            action.setCallback(this, function(resp) {
                if (resp.getState() == "SUCCESS") {
                    resolve(resp.getReturnValue());
                } else reject(resp.getError());
                cmp.set("v.loading", false);
            });
            $A.enqueueAction(action);
        });
    },
    initialize: function(cmp) {
        let me = this;
        me.apex(cmp, "initializeComponentData").then(
            $A.getCallback(function(data) {
                cmp.set(
                    "v.hasSwapPatientPictureBookForStaff",
                    data.hasSwapPatientPictureBookForStaff
                );
                cmp.set(
                    "v.userInViewConsultPendingGroup",
                    data.userInViewConsultPendingGroup
                );
                if(data.hasMedOfficePermission ) {
                    cmp.set(
                        'v.displayOpenItems', 'true'
                    );
                    cmp.set(
                        'v.displayIRISHome', 'false'
                    );
                }
                console.log('data.userInViewConsultPendingGroup : ', data.userInViewConsultPendingGroup)
            })
        );
    }
});
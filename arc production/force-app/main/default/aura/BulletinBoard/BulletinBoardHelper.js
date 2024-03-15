/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
    getUserPermissions: function(component) {
        var action = component.get("c.hasClinical");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var isPermSetClinical = response.getReturnValue();
                component.set("v.isPermSetClinical", isPermSetClinical);
                this.getPermissionsVarianceGeneral(component);
                this.getPermissionsVarianceMedication(component);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Something went wrong, Please check with your admin");
            }
        });
        $A.enqueueAction(action);
    },

    getPermissionsVarianceGeneral: function(component) {
        var action = component.get("c.hasVarianceGeneral");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var isPermSetVarianceGeneral = response.getReturnValue();
                component.set("v.isPermSetVarianceGeneral", isPermSetVarianceGeneral);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Something went wrong, Please check with your admin");
            }
        });
        $A.enqueueAction(action);
    },

    getPermissionsVarianceMedication: function(component) {
        var action = component.get("c.hasVarianceMedication");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var isPermSetVarianceMedication = response.getReturnValue();
                component.set(
                    "v.isPermSetVarianceMedication",
                    isPermSetVarianceMedication
                );
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Something went wrong, Please check with your admin");
            }
        });
        $A.enqueueAction(action);
    },

    loadBulletSectionList: function(component) {
        var action = component.get("c.getBulletSections");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var bulletSectionList = response.getReturnValue();
                component.set("v.bulletSectionList", bulletSectionList);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Something went wrong, Please check with your admin");
            }
        });
        $A.enqueueAction(action);
    }
});
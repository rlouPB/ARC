/* eslint-disable no-unused-expressions */
({
    init: function(component, event, helper) {
        var today = $A.localizationService.formatDate(
            new Date(),
            "EEEE, MM/DD/YYYY"
        );
        component.set("v.todaysDate", today);

        //component.set('v.displayOpenItems', 'true');
        helper.getSummaryInfo(component);
        helper.initialize(component);
    },

    buttonClick: function(component, event, helper) {
        //var clickedID = event.currentTarget.dataset.id;
        helper.setDisplay(component, event.currentTarget.dataset.id);
    },

    collapseButtons: function(component, event, helper) {
        var isTrue = component.get("v.buttonsCollapsed");
        if (isTrue == true) {
            component.set("v.buttonsCollapsed", false);
        } else {
            component.set("v.buttonsCollapsed", !component.get("v.buttonsCollapsed"));
        }
    }
});
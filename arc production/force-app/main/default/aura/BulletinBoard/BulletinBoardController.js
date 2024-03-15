/* eslint-disable no-unused-expressions */
({
    doInit: function(component, event, helper) {
        helper.getUserPermissions(component);
        helper.loadBulletSectionList(component);
    }
});
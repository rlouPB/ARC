/* eslint-disable no-unused-expressions */
({
    afterRender: function(cmp, helper) {
        console.log("CreateMessageRenderer afterRender...");
        this.superAfterRender();
    }
});
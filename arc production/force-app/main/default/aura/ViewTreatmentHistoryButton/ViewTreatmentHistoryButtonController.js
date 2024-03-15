({
    handleShowViewTreatmentHistoryModal : function(component, event, helper) {
        let recordId = component.get("v.recordId");
        var modalBody;
        $A.createComponent("c:ViewTreatmentHistory",
        {
            "recordId" : recordId
        },
        function(content, status){
            if(status === "SUCCESS"){
                modalBody = content;
                component.find("overlayLib").showCustomModal({
                    header : "View Treatment History",
                    body : modalBody,
                    showCloseButton : true,
                    cssClass : "slds-modal_large",
                    closeCallback : function(){
                        console.log("View Treatment History Modal is Closed");
                    }
                });
            }
        });
    }
})
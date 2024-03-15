({
	uploadContent : function(component, event, helper) {
        let params = event.getParam('arguments'),
            file,
            onSuccess = params.contentUploaderCallback,
            onError = params.errorCallback;
        
        if(params && !$A.util.isUndefinedOrNull(params.contentDocument)) {
           file =  params.contentDocument;
        } else {
            if(component.find("fileId").get("v.files")) {
            	file = component.find("fileId").get("v.files")[0];  
            } else {
                onSuccess(null);
                return;
            }           
        }
        if(helper.checkIfContentIsValid(component,file,helper)) {
            helper.uploadHelper(component, event, file, onSuccess, onError, helper);
        } else {
            onError();
        }
	},
    handleFileChange: function(component, event, helper) {
        var fileName = 'No file selected!';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    }
})
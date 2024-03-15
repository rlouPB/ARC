({
	createDocLinks : function(component, event, helper) 
    {
		// console.log('createDocLinks');
        //make ContentDocumentLinks for upload files and additionalRelatedIds
        var uploadedFiles = event.getParam("files");
        let additionalRelatedIds = component.get('v.additionalRelatedIds');
        
        //if (!additionalRelatedIds || additionalRelatedIds.length == 0) return;
        
        let newDocLinks = [];
        uploadedFiles.forEach( function(file) 
            {
                newDocLinks.push(file.documentId);
            });    

        let action = component.get('c.createDocLinks');
        
        let params = {
            'contentDocumentIds': newDocLinks,
            'additionalRelatedIds': additionalRelatedIds
        };
        action.setParams(params);
        
        action.setCallback(this, response=>{
            if (response.getState() ==  "SUCCESS" && response.getReturnValue() == 'Success') 
            {
                let refreshEvent = component.getEvent('uploadFinished');
                refreshEvent.setParams({'data': 'Files'});
                refreshEvent.fire();	   
                //successCallback(response.getReturnValue());
            } else if (response.getState() == "ERROR") {
                // if (errorCallback) {
                //     errorCallback(this.getErrorMessage(response.getError()));
                // } else {
                //     self.handleError(response.getError(), self);        
                // }
                console.log('error', JSON.stringify(response.getError()));
            } else 
            {
                //display error message
                console.log('error', response.getReturnValue());
            } 
        
            // if (isShowSpinner) {
            //     self.hideSpinner(component.getSuper().find("mySpinner"));   
            // }
        });
        $A.enqueueAction(action);

    }

})
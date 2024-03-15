({
    
    uploadHelper: function(component, event,file) {
        
        let contentUploader = component.find('contentUploader'),
            self =  this;
        
        contentUploader.uploadFiles(file,$A.getCallback(function(response){
            let record = component.get("v.record");
            if(!record.Photo_Document_Id__c){
                record.Photo_Document_Id__c = response.contentDocumentId;
                record.Photo_Version_Id__c = response.contentVersionId;
                component.set("v.record",record); 
                self.handleSaveRecord(component, event,response.contentVersionId);
            } else {
                self.toggleSpinner(component, 0); 
                component.set("v.isPhotoIdFieldValid",true);
                component.set('v.pictureSrc', '/sfc/servlet.shepherd/version/download/' 
                              + response.contentVersionId +'?t='+new Date().getTime());
                self.showCustomToast(component,{'type':'success','title':'SUCCESS','message':'Profile Picture Successfully Updated','autoClose':true,'duration':2000});
            }
        }),$A.getCallback(function(error){
               self.toggleSpinner(component, 0); 
        }));
		
    },
    toggleSpinner : function(component, duration) {
		window.setTimeout($A.getCallback(function() {
            if (component.find("spinner")) {
                var spinnerCls = component.find("spinner").get("v.class");
                if (spinnerCls) {
                    if (spinnerCls === 'slds-show') {
                        component.find("spinner").set("v.class", "slds-hide");    
                    } else {
                        component.find("spinner").set("v.class", "slds-show");    
                    }
                } else{
                    component.find("spinner").set("v.class", "slds-hide");    
                }
            }
          }), duration);	   
	},

    onDragLeave : function(component){
        if(component.get("v.isDraggedOver")){
            component.set("v.isDraggedOver",false);
        }
        if($A.util.hasClass(component.find('dragSpace'),'dashedBorder')) {
            $A.util.removeClass(component.find('dragSpace'),'dashedBorder');  
            $A.util.addClass(component.find('dragMessage'),'slds-hide');  
        }
    },
    close: function(component){
        $A.util.removeClass(component.find('showImageModal'),'slds-fade-in-open');
        $A.util.removeClass(component.find('showBackdrop'),'slds-backdrop_open');
    },
    handleSaveRecord: function(component, event,versionId) {
        console.log('If you want');
        let self = this;
        component.find("recordLoader").saveRecord($A.getCallback(function(saveResult) {
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                component.set('v.pictureSrc', '/sfc/servlet.shepherd/version/download/' 
                              + versionId +'?t='+new Date().getTime());
                self.toggleSpinner(component, 0); 
                component.set("v.isPhotoIdFieldValid",true);
                self.showCustomToast(component,{'type':'success','title':'SUCCESS','message':'Profile Picture Successfully Updated','autoClose':true,'duration':2000});
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },
})
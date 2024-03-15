({
    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    
    uploadHelper: function(component, event, file, onSuccess, onError, helper) {
        
        //let self = this;
 		//create a FileReader object 
        var objFileReader = new FileReader();
        //set onload function of FileReader object   
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
 		
            fileContents = fileContents.substring(dataStart);
            //call the uploadProcess method 
            helper.uploadProcess(component, file, fileContents, onSuccess, onError, helper);
        });
 		objFileReader.readAsDataURL(file);
    },
 	
    uploadProcess: function(component, file, fileContents, onSuccess, onError, helper) {
        
        // set a default size or startpostiton as 0 
        let startPosition = 0;
        // calculate the end size or endPostion using Math.min() function which is return the min. value   
        let endPosition = Math.min(fileContents.length, startPosition + helper.CHUNK_SIZE);
 
        // start with the initial chunk, and set the attachId(last parameter)is null in begin
        helper.uploadInChunk(component, file, fileContents, startPosition, endPosition, '', onSuccess, onError, helper, component.get("v.contentId"));
    },
 	
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId, onSuccess, onError, helper, contentId) {
        //call the apex method 'uploadCVCDL'
        let getchunk = fileContents.substring(startPosition, endPosition),
            action,
            params = {
                parentId: component.get("v.parentId"),
                fileName: file.name,
                base64Data: encodeURIComponent(getchunk),
                contentType: file.type,
                fileId: attachId
            };
        
        if(contentId){
            action = component.get("c.updateContent");  
            params.contentDocumentId = contentId;
        } else {
           action = component.get("c.saveChunk");  
            if('contentDocumentId' in params){
               delete params['contentDocumentId'];
           }
        }
        
        /****Apex call****/
        action.setParams(params);
 		
        // set call back 
        action.setCallback(this, function(response) {
            console.log('response:::::::',response.getReturnValue());
            //store the response / Attachment Id   
            if(response.getReturnValue()) {
            	attachId = response.getReturnValue().contentVersionId;
            }
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('response:::',response);
                // update the start position with end postion
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + helper.CHUNK_SIZE);
                // check if the start postion is still less then end postion 
                // then call again 'uploadInChunk' method , 
                // else, diaply alert msg and hide the loading spinner
                if (startPosition < endPosition) {
                    if(contentId != null){
                        contentId = null;
                    }
                    helper.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId, onSuccess, onError, helper,contentId);
                }  else {
                    onSuccess(response.getReturnValue());
                }
            //handle the response errors        
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast('Error while Saving Image : ' +errors[0].message,'error');
            			console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                onError(errors);
            }
        });
        //enqueue the action
        $A.enqueueAction(action);
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
    bytesToSize : function (bytes) {
        let sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        if (bytes == 0) return '0 Byte';
        let i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
        return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
    },
    checkIfContentIsValid : function(component,file,helper){
        const fileType = component.get("v.fileType"); 
        if (fileType == 'image' && !file.type.match(/(image.*)/)) {
            this.showToast('File type not supported. Accepted File formats : .jpg, .jpeg, and .png','error');
            return  false;
        }
        
		        
        // check the selected file size, if select file size greter then MAX_FILE_SIZE,
        // then show a alert msg to user,hide the loading spinner and return from function  
        if (file.size > this.MAX_FILE_SIZE) {
            component.set("v.showLoadingSpinner", false);
            this.showToast('File size cannot exceed more than ' + this.bytesToSize(this.MAX_FILE_SIZE) + '\n' + ' Selected file size: ' + this.bytesToSize(file.size) ,'error');
            //this.showToast(component,{'type':'error','title':'Error while Uploading Profile Image','message':'Alert : File size cannot exceed ' + this.bytesToSize(this.MAX_FILE_SIZE) + '\n' + ' Selected file size: ' + this.bytesToSize(file.size)});
            return false;
        }   
        return true; 
    },
    showToast : function(message,type){
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "type": type,
            "message": message,
             "mode": 'sticky'
        });
        resultsToast.fire();
    }
})
({  
    // Load current profile picture
    onInit: function(component,event,helper) {
        if(component.get("v.photoIdField")) {
            helper.callApexMethod(
            component,
            "getProfilePicture",
            {'parentId':component.get("v.parentRecordId"),'documentId':component.get("v.photoIdField")},
            function (result) {
                if (result && result.Id) {
                    component.set('v.pictureSrc', '/sfc/servlet.shepherd/version/download/' 
                                  + result.Id+'?t='+new Date().getTime());
                    component.set("v.isPhotoIdFieldValid",true);
                }
                 helper.toggleSpinner(component, 0);
            },
            function(error){
                helper.toggleSpinner(component, 0); 
                helper.showCustomToast(component,{'type':'error','title':'Error while Loading Profile Image','message':error});
            }
        );
        } else {
           helper.toggleSpinner(component, 0);  
        }
    },
    
    onDragOver: function(component, event) {
        if(!component.get("v.isDraggedOver")){
            component.set("v.isDraggedOver",true);  
        }
        
        if(!$A.util.hasClass(component.find('dragSpace'),'dashedBorder')){
          $A.util.addClass(component.find('dragSpace'),'dashedBorder');  
          $A.util.removeClass(component.find('dragMessage'),'slds-hide'); 
        }
        
        event.preventDefault();
    },

    onDrop: function(component, event, helper) {
		event.stopPropagation();
        event.preventDefault();
        
        helper.onDragLeave(component);
        
        event.dataTransfer.dropEffect = 'copy';
        
        let files = event.dataTransfer.files;
		console.log(files);
        if(component.get('v.pictureSrc') === '') {
            helper.toggleSpinner(component, 0); 
        	helper.uploadHelper(component,event,files[0]);    
        } else {
            component.set('v.isOpenAlertModal',true);
            component.set('v.fileToUpload',files[0]);
        }
        
	},
    confirm : function(component,event,helper){
        helper.toggleSpinner(component, 0); 
    	helper.uploadHelper(component, event, component.get('v.fileToUpload'));  
        component.set('v.isOpenAlertModal',false);
    },
    cancel : function(component){
       component.set('v.isOpenAlertModal',false); 
    },
    showBiggerImage: function(component,event,helper){
        event.stopPropagation();
        if( component.get("v.isPhotoIdFieldValid")) {
            $A.util.addClass(component.find('showBackdrop'),'slds-backdrop_open');
            $A.util.addClass(component.find('showImageModal'),'slds-fade-in-open');
        }
    },
    close: function(component,event,helper){
       helper.close(component);
    },
    onDragLeave: function(component,event,helper){
		helper.onDragLeave(component);
         
    },
    preventFromClose: function(component,event,helper){
        event.stopPropagation();
    },
    handleRecordUpdated: function(component, event, helper) {
        //not sure what if anything to do here
    }
})
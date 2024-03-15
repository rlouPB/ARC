({
	showToast : function(component, event, helper) {
        let params = event.getParam('arguments'),
			toastProperties = component.get("v.toastProperties");
        
        if(params && params.toastProperties) {
            component.set("v.toastProperties",params.toastProperties);
            
            let autoClose = params.toastProperties.autoClose,
           		autoCloseDelay = params.toastProperties.duration;
            

            helper.showToast(component,event); 
            
            if(autoClose == true && autoCloseDelay > 0) {
                window.setTimeout($A.getCallback(function(){
                   helper.hideToast(component,event);  
                }),autoCloseDelay
              );
            }
            
        }
	},
    closeToast : function(component, event, helper) {
      helper.hideToast(component,event); 
      event.stopPropagation();
    }
})
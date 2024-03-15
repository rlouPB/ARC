({
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
})
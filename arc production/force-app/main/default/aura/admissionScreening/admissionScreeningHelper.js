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
    setFixedHeader : function(component) {
        //temp
        // return;
            
        if(component.get("v.selectedQuestions").length > 0 
          || component.get("v.allQuestions").length > 0 ){
            

            const globalId = component.getGlobalId(),
                parentnode = document.getElementById(globalId),
                thElements = parentnode.getElementsByTagName('th'),
                tdElements = parentnode.getElementsByTagName('td'),
                tableContent = component.find("tableContent").getElement(),
                tableFixedheight =  400;

            
            if(tableContent.offsetHeight > tableFixedheight && thElements.length > 0){
                let lastHeaderWidth = tableContent.offsetWidth;
                for (let i = 0; i < thElements.length; i++) {
                    lastHeaderWidth = lastHeaderWidth - tdElements[i].offsetWidth;
                    tdElements[i].style.width = tdElements[i].offsetWidth  + 'px';
                    
                    if(i !== thElements.length - 1) {
                        thElements[i].style.width = tdElements[i].style.width;
                    }
                    
                }
                
            }
        }
    }
    
})
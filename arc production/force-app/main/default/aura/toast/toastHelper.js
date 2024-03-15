({
	hideToast : function(component,event) {
        var toastContainer = component.find('toastContainer');
        
        if(!($A.util.hasClass(toastContainer,'slds-hide'))) {
   			$A.util.addClass(toastContainer,'slds-hide');
        }
	},
    showToast : function(component,event){
        var toastContainer = component.find('toastContainer');
        $A.util.removeClass(toastContainer,'slds-hide');
    }
})
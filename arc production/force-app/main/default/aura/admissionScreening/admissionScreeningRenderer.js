({
    rerender : function (component, helper) {
        this.superRerender();
        
        window.setTimeout($A.getCallback(function(){
            helper.setFixedHeader(component);
        }),500);
  
    },
})
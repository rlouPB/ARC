({
	afterRender : function(component, helper) {
        this.superAfterRender();
        component.set("v.isComponentLoaded",true);
        console.log('isComponentLoaded');
    }
})
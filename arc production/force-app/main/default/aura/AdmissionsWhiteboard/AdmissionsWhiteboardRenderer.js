({
	    
    unrender: function (component,helper) {
        this.superUnrender();
        console.log('clear interval due to unrender');

        window.clearInterval(component.get("v.update_id"));
    }
})
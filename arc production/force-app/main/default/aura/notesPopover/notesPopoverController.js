({
	
    handleMouseOut : function(component, event, helper) {
		// component.set('v.hovering',false);
		//debugger;
		// console.log('mouse out');
		let evt = component.getEvent("mouseLeaveNotes");
        evt.fire();
	},
    handleMouseOver : function(component, event, helper) {
		// component.set('v.hovering',true);
		// console.log('mouse over');
		let evt = component.getEvent("mouseOverNotes");
        evt.fire();
	}
})
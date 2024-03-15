({
	doInit : function(component, event, helper)
	{
		helper.getLabels(component, event, helper);
		helper.getData(component, event, helper);
	},

	refreshList : function(component, event, helper)
	{
		helper.refreshList(component, event, helper);
	},
    
	sortByThis : function(component, event, helper)
	{
        let target = event.currentTarget;
		let columnName = target.getAttribute("data-columnName")
        helper.sortBy(component, columnName);
	}
})
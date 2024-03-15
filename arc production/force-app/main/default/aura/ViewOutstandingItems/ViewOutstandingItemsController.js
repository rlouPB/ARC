({
	init: function (component, event, helper) {
		var userSearchFilter = [
			{
				fieldName: "IsActive",
				condition: "=",
				value: true,
			},
			{
				fieldName: "Profile.Name",
				condition: "=",
				value: "RiggsClinical",
			},
		];
		component.set("v.userSearchFilter", userSearchFilter);

		var currentUserID = $A.get("$SObjectType.CurrentUser.Id");
		var currentUserName = $A.get("$SObjectType.CurrentUser.Name");
		console.log("currentUserName: " + currentUserName);
		var currentUser = { isRecord: true, label: currentUserName, value: currentUserID };
		component.set("v.selectedUserRecord", currentUser);

		helper.getResults(component);
	},

	sortByName: function (component, event, helper) {
		let target = event.currentTarget;
		let columnName = target.getAttribute("data-columnName");
		helper.sortBy(component, columnName);
	},

	handleUserSelectionChange: function (component, event, helper) {
		helper.getResults(component);
	},

	handleCheckboxChange: function (component, event, helper) {
		helper.getFilteredResults(component);
	},
});
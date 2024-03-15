({
	onInit: function (cmp, e, h) {
		console.log("PatientTitleSetterCmpController onInit...");
		document.title = cmp.get("v.title");
		cmp.set("v.currentUrl", window.location.href);

		h.callApexMethod(cmp, "getPageTitle", { recordId: cmp.get("v.recordId") }, function (result) {
			if (result) {
				cmp.set("v.title", result);
				document.title = cmp.get("v.title");
			}
		});

		window.history.replaceState({}, cmp.get("v.title"), cmp.get("v.currentUrl"));
	},

	onRender: function (cmp, e, h) {
		console.log("PatientTitleSetterCmpController onRender...");
		document.title = cmp.get("v.title");
	},

	onLocationChange: function (cmp, e, h) {
		console.log("PatientTitleSetterCmpController onLocationChange...");
	},
});
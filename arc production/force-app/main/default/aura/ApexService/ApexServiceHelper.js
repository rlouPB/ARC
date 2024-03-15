({
	showSpinner: function (component, displayText, size, variant) {
		console.log("ApexServiceHelper showSpinner...");
		let spinnerCmp = component.getSuper().find("mySpinner");
		if (displayText) {
			spinnerCmp.set("v.alternativeText", displayText);
			spinnerCmp.set("v.title", displayText);
		}
		if (size) spinnerCmp.set("v.size", size);
		if (variant) spinnerCmp.set("v.variant", variant);
		spinnerCmp.set("v.class", "slds-show");
	},

	hideSpinner: function (component) {
		console.log("ApexServiceHelper hideSpinner...");
		let spinnerCmp = component.getSuper().find("mySpinner");
		spinnerCmp.set("v.class", "slds-hide");
	},

	showToast: function (params) {
		console.log("ApexServiceHelper showToast...");
		var toastEvent = $A.get("e.force:showToast");
		if (toastEvent) {
			toastEvent.setParams(params);
			toastEvent.fire();
		} else {
			alert(JSON.stringify(params));
		}
	},

	showCustomToast: function (component, params) {
		console.log("ApexServiceHelper showCustomToast...");
		let toast = component.getSuper().find("toast");
		if (toast) toast.showToast(params);
	},

	hideCustomToast: function (component) {
		console.log("ApexServiceHelper hideCustomToast...");
		let toast = component.getSuper().find("toast");
		if (toast) toast.hideToast();
	},

	callApexMethod: function (component, methodName, params, successCallback, errorCallback, isShowSpinner) {
		console.log("ApexServiceHelper callApexMethod...");
		let self = this;
		let action = component.get("c." + methodName);

		if (isShowSpinner) {
			self.showSpinner(component);
		}

		if (params) {
			action.setParams(params);
		}

		action.setCallback(this, (response) => {
			if (response.getState() == "SUCCESS") {
				successCallback(response.getReturnValue());
			} else if (response.getState() == "ERROR") {
				if (errorCallback) {
					errorCallback(this.getErrorMessage(response.getError()), component);
				} else {
					self.handleError(response.getError(), self);
				}
				// console.log("error", JSON.stringify(response.getError()));
			}
			if (isShowSpinner) {
				self.hideSpinner(component);
			}
		});
		$A.enqueueAction(action);
	},

	handleError: function (errors, self) {
		console.log("ApexServiceHelper handleError...");
		let errorMessage = self.getErrorMessage(errors);

		this.showToast({
			title: "Error!!!",
			message: errorMessage,
			type: "error",
			mode: "sticky",
		});
	},

	getErrorMessage: function (errors) {
		console.log("ApexServiceHelper getErrorMessage...");
		let errorMessage = "";
		if (errors && Array.isArray(errors) && errors.length > 0) {
			errors.forEach((error) => {
				if (error.message) {
					errorMessage += error.message + "\n";
				}
				if (error.pageErrors && error.pageErrors.length > 0) {
					error.pageErrors.forEach((pageError) => {
						errorMessage += pageError.message + "\n";
					});
				} else if (error.fieldErrors) {
					let fields = Object.keys(error.fieldErrors);

					fields.forEach((fieldError) => {
						if (Array.isArray(error.fieldErrors[fieldError])) {
							let fieldErrors = error.fieldErrors[fieldError];
							fieldErrors.forEach((err) => {
								errorMessage += err.message;
							});
						}
					});
				}
			});
		}
		return errorMessage != "" ? errorMessage : "Unknown error";
	},
});
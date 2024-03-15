/* eslint-disable no-unused-expressions */
({
	fireActionEvent: function (component, event, helper, action) {
		var dischargeSectionActionEvent = component.getEvent(
			"dischargeSectionActionEvent"
		);
		var instanceName = component.get("v.instanceName");
		dischargeSectionActionEvent.setParams({
			action: action,
			instanceName: instanceName
		});
		dischargeSectionActionEvent.fire();
	},
	// This method only calculates the UI controlling attributes, this does NOT update the data
	calculatePermission: function (component, event, helper) {
		var dischargeSection = component.get("v.dischargeSection");
		var dischargeDisposition = component.get("v.dischargeDisposition");
		// As long as Discharge Disposition is cancel or finalized, it is not editable nor re-openable
		if (
			dischargeDisposition.dischargeDispositionObj.Status__c == "Cancelled" ||
			dischargeDisposition.dischargeDispositionObj.Status__c == "Finalized" 
		) {
			component.set("v.isEditable", false);
			component.set("v.isReopenable", false);
			component.set("v.isResponsibleWorkerChangeable", false);
		}
		// If it is not cancelled or finalized, it can be editable or reopenable
		else {
			var currentUser = component.get("v.currentUser");
			var responsibleSocialWorker = component.get("v.responsibleSocialWorker");
			// If it is System Administrator, it is editable
			// TODO Please make sure to put the Administrator back to the logic
			// currentUser.Profile.Name.indexOf('Administrator')!=-1 ||

			console.log(
				"currentUser.Id:" +
					currentUser.Id +
					", Owner Id:" +
					dischargeSection.dischargeSectionObj.OwnerId +
					", social worker:" +
					responsibleSocialWorker.Id
			);
			if (dischargeSection.dischargeSectionObj.Status__c == "Completed") {
				component.set("v.isResponsibleWorkerChangeable", false);
				// Only Responsible Social Worker can re-open
				if (currentUser.Id == responsibleSocialWorker.Id) {
					component.set("v.isEditable", false);
					component.set("v.isReopenable", true);
				} else {
					component.set("v.isEditable", false);
					component.set("v.isReopenable", false);
				}
			} else {
				component.set("v.isReopenable", false);
				if (
					currentUser.Id == dischargeSection.dischargeSectionObj.OwnerId ||
					(dischargeSection.dischargeSectionObj.Role__c ==
						"Medical Care Instructions" &&
						dischargeDisposition.isMedOfficeUser == true)
				) {
					component.set("v.isEditable", true);
				} else {
					component.set("v.isEditable", false);
				}
				if (
					currentUser.Id == dischargeSection.dischargeSectionObj.OwnerId ||
					currentUser.Id == responsibleSocialWorker.Id
				) {
					component.set("v.isResponsibleWorkerChangeable", true);
				} else {
					component.set("v.isResponsibleWorkerChangeable", false);
				}
			}
		}
		//if current user has Medical Records custom permission, make DDR editable
		if(dischargeDisposition.isMedRecords){
			component.set("v.isEditable", true);
			component.set("v.isReopenable", true);
			component.set("v.isResponsibleWorkerChangeable", true);
		}
		//removed 220908 JN
		// component.set("v.loading", false);
	},
	/**
	 * Validate referrals.  There are multiple scenarios:
	 *
	 * #1. When No separate referral required is CHECKED, comments are required.
	 * #2. When No separate referral required is UNCHECKED, there MUST have referrals
	 */
	validateReferral: function (component, event, helper) {
		var numErrors = 0;
		var retval = true;
		var referralList;
		var dischargeSection = component.get("v.dischargeSection");
		var referralListMap = component.get("v.referralListMap");
		// No separate referral required but still adding referrals
		var sectionMap = {
			Psychotherapy: true,
			Psychopharmacology: true,
			"Medical Care Instructions": true,
			"Substance Use Services": true
		};

		if (sectionMap[dischargeSection.dischargeSectionObj.Role__c] == true) {
			if (
				dischargeSection.dischargeSectionObj.No_Separate_Referral_Required__c
			) {
				if (
					$A.util.isEmpty(
						dischargeSection.dischargeSectionObj
							.No_Separate_Referral_Required_Comments__c
					)
				) {
					numErrors++;
				}
			} else {
				var numReferrals = 0;
				Object.keys(referralListMap).forEach(function (key) {
					console.log(
						"key:" + key + ", referralListMap[key]:" + referralListMap[key]
					);
					referralList = referralListMap[key];
					if (!$A.util.isEmpty(referralList)) {
						for (var referral in referralList) {
							if (
								referralList[referral].dischargeReferralObj.Clinician__c !=
									null ||
								referralList[referral].dischargeReferralObj.Institution__c !=
									null
							) {
								numReferrals++;
							}
						}
					}
				});
				if (numReferrals == 0) {
					numErrors++;
				}
				console.log(
					"numReferrals:" + numReferrals + ", numErrors:" + numErrors
				);
			}
		}
		if (numErrors > 0) {
			retval = false;
			helper.showToast({
				title: "No Referral Entered",
				message:
					"Please either enter a Referral or provide comments on why there is no separate referral required.",
				type: "error"
			});
		}
		return retval;
	},
	reload: function (component, dischargeDispositionId) {
		var dischargeRedirect = $A.get("e.force:navigateToURL");
		dischargeRedirect.setParams({
			url: "/" + dischargeDispositionId,
			isredirect: true
		});
		dischargeRedirect.fire();
	},
	splitList: function (component, event, helper) {
		var isEditable = component.get("v.isEditable");
		var referralListMap = component.get("v.referralListMap");
		var dischargeSection = component.get("v.dischargeSection");
		var dischargeDisposition = component.get("v.dischargeDisposition");
		console.log("before referralListMap:" + JSON.stringify(referralListMap));
		console.log(
			"dischargeSection.referralList:" +
				JSON.stringify(dischargeSection.referralList)
		);
		Object.keys(referralListMap).forEach(function (key) {
			console.log(
				"referralListMap[" + key + "]:" + JSON.stringify(referralListMap[key])
			);
			if (!$A.util.isEmpty(referralListMap[key])) {
				//referralListMap[key] = [];
				referralListMap[key].length = 0;
			}
		});
		if (!$A.util.isEmpty(dischargeSection.referralList)) {
			for (var referral in dischargeSection.referralList) 
			{
				if ($A.util.isEmpty(dischargeSection.referralList[referral].dischargeReferralObj.Grouping__c)) 
				{
					referralListMap[dischargeSection.referralList[referral].dischargeReferralObj.Grouping__c] = [];
				}
				console.log( "dischargeSection.referralList[" + referral + "]:" + JSON.stringify(dischargeSection.referralList[referral]) );

				referralListMap[dischargeSection.referralList[referral].dischargeReferralObj.Grouping__c].push(dischargeSection.referralList[referral]);
			}
		}
		console.log("after referralListMap:" + JSON.stringify(referralListMap));
		component.set("v.referralListMap", referralListMap);
		console.log( "discharge status:" + dischargeDisposition.dischargeDispositionObj.Status__c + ", section status:" + dischargeSection.dischargeSectionObj.Status__c );
		if (dischargeDisposition.dischargeDispositionObj.Status__c == "Draft" 
				&& dischargeSection.dischargeSectionObj.Status__c == "Draft" 
				&& isEditable == true) 
		{
			Object.keys(referralListMap).forEach(function (listName) 
			{
				console.log("listName:" + listName + " add new referral");
				var referralListComponent = component.find(listName);
				if (referralListComponent) {
					console.log("adding:" + listName + " add new referral");
					referralListComponent.addNewReferral();
				}
			});
		}
	},
	combineList: function (component, event, helper) {
		var referralListMap = component.get("v.referralListMap");
		var dischargeSection = component.get("v.dischargeSection");
		var referralList = [];
		if (!$A.util.isEmpty(referralListMap)) {
			Object.keys(referralListMap).forEach(function (grouping) {
				var referralSubList = referralListMap[grouping];
				for (var referral in referralSubList) {
					if (
						!$A.util.isEmpty(
							referralSubList[referral].dischargeReferralObj.Clinician__c
						) ||
						!$A.util.isEmpty(
							referralSubList[referral].dischargeReferralObj.Institution__c
						)
					) {
						referralList.push(referralSubList[referral]);
					}
				}
			});
		}
		dischargeSection.referralList = referralList;
		component.set("v.dischargeSection", dischargeSection);
	},
	saveDischargeSection: function (component, event, helper, dischargeSection) {
		helper.combineList(component, event, helper);
		// dischargeSection.dischargeSectionObj = {'Id': dischargeSection.dischargeSectionObj.Id};
		dischargeSection.dischargeSectionObj["sobjectType"]="Discharge_Section__c";

		var selectedResponsiblePerson = component.get(
			"v.selectedResponsiblePerson"
		);
		if (!$A.util.isEmpty(selectedResponsiblePerson)) {
			dischargeSection.dischargeSectionObj.OwnerId =
				selectedResponsiblePerson.value;
		}
		if (dischargeSection.dischargeSectionObj.OwnerId == null)
		{
			delete dischargeSection.dischargeSectionObj.OwnerId;
		}
		delete dischargeSection.dischargeSectionObj.Owner;

		if (!$A.util.isEmpty(dischargeSection.referralList)) {
			var newReferralList = [];
			for (var i = 0; i < dischargeSection.referralList.length; i++) {
				if (
					!$A.util.isEmpty(
						dischargeSection.referralList[i].dischargeReferralObj.Clinician__c
					) ||
					!$A.util.isEmpty(
						dischargeSection.referralList[i].dischargeReferralObj.Institution__c
					)
				) {
					dischargeSection.referralList[i].dischargeReferralObj["sobjectType"] =
						"Discharge_Referral__c";
					newReferralList.push(dischargeSection.referralList[i]);
				}
			}
			dischargeSection.referralList = newReferralList;
		}
		console.log(
			"Ready to save section:" + dischargeSection.dischargeSectionObj.Role__c
		);
		var dischargeSectionString = JSON.stringify(dischargeSection);
		helper.callApexMethod(
			component,
			"saveDischargeSection",
			{ dischargeSectionString: dischargeSectionString },
			function (result) {
				var savedResult = JSON.parse(result);
				console.log("savedResult:" + result);
				console.log("is object:" + $A.util.isObject(savedResult));
				if ($A.util.isObject(savedResult)) 
				{
					if (!$A.util.isEmpty(savedResult.dischargeSectionObj)) 
					{
						component.set("v.dischargeSection", savedResult);
						helper.calculatePermission(component, event, helper);

						helper.splitList(component, event, helper);
						component.set("v.removeReferralList", []);
						component.set("v.isResponsiblePersonChanged", false);
						component.set("v.isResponsiblePersonChangeClicked", false);
						helper.showToast({
							title: "Save Discharge Section",
							message:
								"Successfully Saved " +
								savedResult.dischargeSectionObj.Role__c +
								" Discharge Section",
							type: "success"
						});
						helper.refreshDischargeDisposition(component, event, helper);
						// component.get('v.hideReferrals', false);
					} else {
						Object.keys(savedResult).forEach(function (error) {
							console.log("Error:" + error + ",stack:" + savedResult[error]);
							helper.showToast({
								title: "Unable to Save Discharge Section",
								message: error,
								type: "error"
							});
						});
					}
					// component.set("v.loading", false);
				} else {
					var errorMap = JSON.parse(result);
					Object.keys(errorMap).forEach(function (error) {
						console.log("Error:" + error + ",stack:" + errorMap[error]);
						helper.showToast({
							title: "Unable to Save Discharge Section",
							message: error,
							type: "error"
						});
					});
				}
				component.set("v.loading", false);
				component.set("v.isLoading", false);
			},
			null,
			false
		);
	},
	reopenDischargeSection: function (component,event,helper,dischargeSection) 
	{
		//JN have to remove this to avoid JSON deserialization problems in apex
		delete dischargeSection.dischargeSectionObj.Owner;

		var dischargeSectionString = JSON.stringify(dischargeSection);
		helper.callApexMethod(
			component,
			"reopenDischargeSection",
			{ dischargeSectionString: dischargeSectionString },
			function (result) {
				var savedResult = JSON.parse(result);
				console.log("savedResult:" + result);
				console.log("is object:" + $A.util.isObject(savedResult));
				if ($A.util.isObject(savedResult)) {
					if (!$A.util.isEmpty(savedResult.dischargeSectionObj)) {
						var dischargeSectionReopenedEvent = component.getEvent(
							"dischargeSectionReopenedEvent"
						);
						var instanceName = component.get("v.instanceName");
						dischargeSectionReopenedEvent.setParams({
							dischargeSection: savedResult,
							instanceName: instanceName
						});
						dischargeSectionReopenedEvent.fire();
						component.set("v.dischargeSection", savedResult);
						helper.splitList(component, event, helper);
						component.set("v.removeReferralList", []);
						helper.calculatePermission(component, event, helper);
						helper.showToast({
							title: "Reopen Discharge Section",
							message:
								"Successfully Reopened " +
								dischargeSection.dischargeSectionObj.Role__c +
								" Discharge Section",
							type: "success"
						});
					} else {
						Object.keys(savedResult).forEach(function (error) {
							console.log("Error:" + error + ",stack:" + savedResult[error]);
							helper.showToast({
								title: "Unable to Re-open Discharge Section",
								message: error,
								type: "error"
							});
						});
					}
					component.set("v.loading", false);
				} else {
					var errorMap = JSON.parse(result);
					Object.keys(errorMap).forEach(function (error) {
						console.log("Error:" + error);
					});
				}
				component.set("v.loading", false);
				component.set("v.isLoading", false);
			},
			null,
			false
		);
	},
	setFilters: function (component, event, helper) {
		var psetAssignmentFilters = [
			{
				fieldName: "Assignee.IsActive",
				condition: "=",
				value: true
			}
		];

		var userTypes = "'Standard'";
		if (userTypes && userTypes.length > 0) {
			//userTypes should be a single-quoted, comma-separated String
			var userTypeString = "(";
			userTypeString += userTypes;
			userTypeString += ")";

			psetAssignmentFilters.push({
				fieldName: "Assignee.UserType",
				condition: "IN",
				value: userTypeString
			});
		}

		//currently no profiles filtered 210519 JN
		var profileNames = "";
		if (profileNames && profileNames.length > 0) {
			//profileNames should be a single-quoted, comma-separated String
			var profileNameString = "(";
			profileNameString += profileNames;
			profileNameString += ")";

			psetAssignmentFilters.push({
				fieldName: "Assignee.Profile.Name",
				condition: "IN",
				value: profileNameString
			});
		}

		var permissionSetNames = component.get("v.permissionSetNames");
		if (permissionSetNames && permissionSetNames.length > 0) {
			//permissionSetNames should be a single-quoted, comma-separated String
			var permSetNameString = "(";
			permSetNameString += permissionSetNames;
			permSetNameString += ")";

			psetAssignmentFilters.push({
				fieldName: "PermissionSet.Name",
				condition: "IN",
				value: permSetNameString
			});
		}
		console.log(
			"psetAssignmentFilters " +
				JSON.parse(JSON.stringify(psetAssignmentFilters))
		);

		component.set("v.psetAssignmentFilters", psetAssignmentFilters);
	},
	refreshDischargeDisposition: function(component, event, helper) 
	{
        var compEvent = component.getEvent("DischargeDispositionActionEvent");
        compEvent.setParams({
            actionType: "Refresh"
        });
        compEvent.fire();
    },
});
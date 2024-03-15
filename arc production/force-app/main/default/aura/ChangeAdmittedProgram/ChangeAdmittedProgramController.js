({
	doInit: function (component, event, helper) {
		helper.clean(component);
		helper.loadData(component, event, helper);

		let changeProgramLookupFilter = [{ fieldName: "Active__c", condition: "=", value: true }];
		component.set("v.changeProgramLookupFilter", changeProgramLookupFilter);
	},
	doneScriptsLoading: function (component, event, helper) {
		component.set("v.loading", false);
	},

	handleLocationChange: function (component, event, helper) {
		console.log("ChangeAdmittedProgram handleLocationChange ");
	},
	handleChangeFunction: function (component, event, helper) {
		console.log("ChangeAdmittedProgram handleChangeFunction ");
		var chosenFunction = component.get("v.chosenFunction");
		console.log("ChangeAdmittedProgram handleChangeFunction chosenFunction: " + chosenFunction);
		if (chosenFunction == "Change Program") {
			var nowDate = moment().tz("UTC").format("YYYY-MM-DD");
			// console.log("ChangeAdmittedProgram handleChangeFunction nowDate: " + nowDate);
			// component.set('v.programStartDate', nowDate);
			component.find("programStartDate").set("v.value", nowDate);
			var newAdmittedProgram = {
				Program__c: null,
				Program_Manager__c: null,
				Start_Date__c: nowDate,
			};
			console.log("ChangeAdmittedProgram handleChangeFunction newAdmittedProgram: " + JSON.stringify(newAdmittedProgram));
			component.set("v.newAdmittedProgram", newAdmittedProgram);
			// component.find('changeProgramLookup').focus();
		} else if (chosenFunction == "New Status") {
			var nowDateTime = moment();

			var admittedProgramStatusRecord = {
				Admitted_Program__c: component.get("v.currentAdmittedProgram.Id"),
				Status__c: "",
				Start_Date_Time__c: nowDateTime.tz("UTC").format(),
			};
			component.set("v.admittedProgramStatusRecord", admittedProgramStatusRecord);

			// component.find('newStatusSelectStatus').focus();
		} else if (chosenFunction == "Update Status") {
			// component.find('updateStatusSelectStatusId').focus();
		}

		console.log("choosing function " + chosenFunction);
	},
	onSelectedStatusIdChanged: function (component, e, h) {
		h.showSpinner(component);

		let selectedStatusId = component.get("v.selectedStatusId");
		if (!selectedStatusId) {
			component.set("v.admittedProgramStatusRecord", {});
			// component.find('newStatusEndDate').set('v.value');
			// component.set('v.statusStartDateTime');
			h.hideSpinner(component);
			return;
		}

		let me = this;
		component
			.find("statusLoader")
			.getRecord(true)
			.then(
				$A.getCallback(function (record) {
					component.set("v.admittedProgramStatusRecord", record);

					// let endDateCmp = component.find('updateStatusEndDate');
					// if(record && endDateCmp){
					//     endDateCmp.set('v.value', record.End_Date_Time__c );
					// }
					// let startDateCmp = component.find('updateStatusStartDate');
					// if (record && startDateCmp){
					//     startDateCmp.set('v.value', record.Start_Date_Time__c);
					// }
					console.log("status record " + JSON.stringify(record));
					h.hideSpinner(component);
				})
			);
	},
	onSelectedProgramChanged: function (component, e, helper) {
		let programId2ProgramManagerMap = component.get("v.programId2ProgramManagerMap");
		let selectedProgram = component.get("v.selectedProgram");
		let program = helper.clone(programId2ProgramManagerMap)[selectedProgram.value];
		if (selectedProgram && selectedProgram.value && programId2ProgramManagerMap && program) {
			let selectedProgramManager = {
				value: helper.clone(program.Id),
				label: helper.clone(program.Professional_Name__c),
				isRecord: true,
			};
			component.set("v.selectedProgramManager", selectedProgramManager);
		} else {
			component.set("v.selectedProgramManager");
			let managerLookup = component.find("managerLookup");
			if (managerLookup) managerLookup.closePill();
		}
	},
	onRender: function (component, event, helper) {
		console.log("ChangeAdmittedProgram onRender: " + event.getParam("value").getName());
	},
	closeModal: function (component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
	submitDetails: function (component, event, helper) {
		helper.saveRecord(component).then(
			$A.getCallback(function () {
				$A.get("e.force:refreshView").fire();
			})
		);
	},
});
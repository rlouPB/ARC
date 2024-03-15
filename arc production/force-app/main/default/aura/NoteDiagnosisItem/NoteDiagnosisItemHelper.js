({
	apex: function (cmp, methodName, params) {
		let self = this;
		return new Promise(
			$A.getCallback(function (resolve, reject) {
				console.log(cmp, methodName, params);
				let action = cmp.get("c." + methodName);
				if (params) {
					action.setParams(params);
				}
				action.setCallback(self, (resp) => {
					if (resp.getState() == "SUCCESS") {
						resolve(resp.getReturnValue());
					} else if (resp.getState() == "ERROR") {
						reject(resp.getError());
					}
				});
				$A.enqueueAction(action);
			})
		);
	},

	setFilters: function (cmp) {
		console.log("NoteDiagnosisItemHelper setFilters...");

		let dsmCodeLookupFilter = [
			{
				fieldName: "Code_Set__c",
				condition: "=",
				value: cmp.get("v.codeSet"),
			},
			{
				fieldName: "Is_Current__c",
				condition: "=",
				value: true,
			},
		];
		cmp.set("v.dsmCodeLookupFilter", dsmCodeLookupFilter);
		console.log("NoteDiagnosisItemHelper setFilters dsmCodeLookupFilter: " + JSON.stringify(cmp.get("v.dsmCodeLookupFilter")));
	},

	loadRecord: function (cmp) {
		let me = this;
		return new Promise(
			$A.getCallback(function (resolve) {
				cmp.set("v.loading", true);
				me.callApexMethod(
					cmp,
					"getRecordInfo",
					{
						recordId: cmp.get("v.recordId"),
						sobjectType: "Diagnosis__c",
						fields: "Id,Clinical_Code__c,Additional_Specifiers__c,Source__c,Type__c,Admission__c,Patient_Note__c,Marked_for_Delete__c",
						whereClause:
							"AND Clinical_Code__r.Start_Date__c < = TODAY AND (Clinical_Code__r.End_Date__c >= TODAY OR Clinical_Code__r.End_Date__c = null)",
					},
					function (result) {
						cmp.set("v.diagnosis", result);
						resolve(result);
						cmp.set("v.loading", false);
					}
				);
			})
		);
	},
	updateMarkForDelete: function (cmp, diagnosisId, value) {
		let me = this;
		return new Promise(
			$A.getCallback(function (resolve, reject) {
				cmp.set("v.loading", true);
				me.apex(cmp, "MarkForDelete", { diagnosisId, value })
					.then(
						$A.getCallback((result) => {
							if (result && !result.errorMessage) {
								resolve(result);
							} else if (result && result.errorMessage) {
								reject(result.errorMessage);
							} else if (!result) {
								reject("Unknown error ocurrec");
							}
						})
					)
					.then($A.getCallback(() => cmp.set("v.loading", false)));
			})
		);
	},
	saveDiagnosis: function (cmp) {
		let me = this;
		return new Promise(
			$A.getCallback(function (resolve) {
				cmp.set("v.loading", true);
				let diagnosis = cmp.get("v.diagnosis");
				console.info(
					":::::::::::::::::::::::::::::::::::: saveDiagnosis ::::::::::::::::::::::::::::::::::::",
					JSON.parse(JSON.stringify(diagnosis))
				);
				me.callApexMethod(
					cmp,
					"saveDiagnosis",
					{
						diagnosisJson: JSON.stringify(diagnosis),
					},
					function (result) {
						resolve(result);
						cmp.set("v.loading", false);
					}
				);
			})
		);
	},
	refreshCode: function (cmp, clinicalCodeId) {
		let me = this;
		return new Promise(
			$A.getCallback(function (resolve) {
				if (me.isId(clinicalCodeId)) {
					//alert('checking ==> ' + (me && me.callApexMethod )?'true':'false');
					cmp.set("v.loading", true);
					me.callApexMethod(
						cmp,
						"getRecordInfo",
						{
							recordId: clinicalCodeId,
							sobjectType: "Clinical_Code__c",
							fields: "Id,Name,Description__c",
							whereClause: "AND Start_Date__c < = TODAY AND (End_Date__c >= TODAY OR End_Date__c = null)",
						},
						function (result) {
							cmp.set("v.code", result ? result.Name : null);
							cmp.set("v.codeDescription", result ? result.Description__c : null);
							resolve(result.Name);
							cmp.set("v.loading", false);
						}
					);
				} else {
					cmp.set("v.code", null);
				}
			})
		);
	},

	reset: function (cmp) {
		cmp.set("v.diagnosis", {
			Type__c: cmp.get("v.type"),
			Admission__c: cmp.get("v.admissionId"),
			Source__c: cmp.get("v.source"),
			Patient_Note__c: cmp.get("v.patientNoteId"),
		});
		// if(cmp.get('v.type')=='Principal'){
		//     cmp.set('v.diagnosis.Clinical_Code__c', null);
		//     cmp.set('v.diagnosis.Additional_Specifiers__c', null);
		// }else{
		//     cmp.set('v.diagnosis',{
		//         Type__c: cmp.get('v.type'),
		//         Admission__c: cmp.get('v.admissionId'),
		//         Source__c: cmp.get('v.source'),
		//         Patient_Note__c:cmp.get('v.patientNoteId'),
		//     });
		// }
		cmp.set("v.hideLookup", false);
		cmp.find("diagnosisLookup").closePill();
	},

	isId: function (value) {
		let regex = RegExp("^[a-zA-Z0-9]{15,18}$");
		return value && typeof value == "string" && regex.test(value);
	},
});
({
	doInit: function (cmp, e, h) {
		console.log("NoteDiagnosisItemController doInit...");
		let recordId = cmp.get("v.recordId");
		console.log("NoteDiagnosisItemController doInit isActive: " + cmp.get("v.isActive"));

		if (!recordId) {
			cmp.set("v.diagnosis", {
				Type__c: cmp.get("v.type"),
				Admission__c: cmp.get("v.admissionId"),
				Source__c: cmp.get("v.source"),
				Patient_Note__c: cmp.get("v.patientNoteId"),
			});
			console.info("doInit v.diagnosis ==> " + JSON.stringify(cmp.get("v.diagnosis")));
		} else {
			h.loadRecord(cmp).then(
				$A.getCallback(function (record) {
					h.refreshCode(cmp, "" + record.Clinical_Code__c).then(
						$A.getCallback(function (r) {
							console.info("doInit Result ==> " + JSON.stringify(r));
						})
					);
				})
			);
		}

		h.setFilters(cmp);
	},
	onClinicalCodeChanged: function (cmp, e, h) {
		let params = e.getParams();
		let clincalCodeId = cmp.get("v.diagnosis.Clinical_Code__c");
		let type = cmp.get("v.type");
		h.refreshCode(cmp, clincalCodeId);
	},
	onCodeChanged: function (cmp, e, h) {
		let old = e.getParam("oldValue");
		let value = e.getParam("value");
		if (value && value != old) {
			cmp.set("v.hideLookup", true);
		}
	},
	onSaveClickHandler: function (cmp, e, h) {
		h.saveDiagnosis(cmp)
			.then(
				$A.getCallback(function (result) {
					if (cmp.get("v.resetAfterSave")) {
						h.reset(cmp);
					} else {
						cmp.set("v.recordId", result);
						h.loadRecord(cmp);
					}
					return 1;
				})
			)
			.then(
				$A.getCallback(function () {
					$A.get("e.c:NoteDiagnosisEvent")
						.setParams({ type: "saved", data: { source: cmp.get("v.source"), type: cmp.get("v.type") } })
						.fire();
				})
			);
	},
	onRemoveHandler: function (cmp, e, h) {
		h.reset(cmp);
	},
	onMarkForRemoval: function (cmp, e, h) {
		let diagnosisId = cmp.get("v.diagnosis.Id");
		h.updateMarkForDelete(cmp, diagnosisId, true).then(
			$A.getCallback((result) => {
				if (!result.errorMessage) {
					h.reset(cmp);
					$A.get("e.c:NoteDiagnosisEvent")
						.setParams({ type: "saved", data: { source: cmp.get("v.source"), type: cmp.get("v.type") } })
						.fire();
				}
			})
		);
	},
	// onCancelRemoval: function(cmp,e,h){
	//     let diagnosisId = cmp.get('v.diagnosis.Id');
	//     h.updateMarkForDelete(cmp,diagnosisId,false);
	// },
});
({
	confirmCreate: function(cmp, event, helper, params, modal)
	{
		modal
			.confirm(
				"Are you sure you want to create a new <strong>" +
				params.docType.Name__c +
				"</strong> for <strong>" +
				params.recordName +
				"</strong>?"
			)
			.then(
				$A.getCallback(function(confirmed) {
					if (confirmed) 
					{
						cmp.set("v.showmodal", true);
						let flow = cmp.find("flow");
						let flowName = params.docType.Flow_Name__c;
						if (flowName) 
						{
							let inputParams = [{
									name: "accountId",
									type: "String",
									value: cmp.get("v.recordId")
								},
								{
									name: "docTypeName",
									type: "String",
									value: params.docType.DeveloperName
								},
								{
									name: "docTypeId",
									type: "String",
									value: params.docType.Id
								}
								// {
								// 	name: "contactDate",
								// 	type: "Date",
								// 	value: cmp.get("v.contactDate"),
								// },
							];

							if (flowName == "Build_Patient_Note_With_Params") 
							{
								// set default date

								inputParams = [{
										name: "accountId",
										type: "String",
										value: cmp.get("v.recordId")
									},
									{
										name: "docTypeName",
										type: "String",
										value: params.docType.DeveloperName
									},
									{
										name: "docTypeId",
										type: "String",
										value: params.docType.Id
									},
									{
										name: "contactDate",
										type: "Date",
										value: cmp.get("v.contactDate")
									}
								];
							}
							flow.startFlow(flowName, inputParams);
						} else {
							cmp.set("v.showmodal", false);
							modal.alert("No FLow Name Found");
						}
					}
				})
			);
	}
})
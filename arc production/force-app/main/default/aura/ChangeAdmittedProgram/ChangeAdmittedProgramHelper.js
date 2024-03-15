({
	loadData : function(component, event, helper)
	{
		let me = this;
		return new Promise($A.getCallback((resolve,reject)=>{
			me.callApexMethod(
				component,
				"getAccountInfo",
				{ accountId: component.get("v.recordId") },
				function (result) 
				{
					console.log("ChangeAdmittedProgramHelper loadData getAccountInfo result: ", me.clone(result));
					component.set('v.programId2ProgramManagerMap', result.programId2ProgramManagerMap);

					component.set("v.patient", result);

					component.set('v.admittedPrograms', result.admittedPrograms );
					component.set("v.currentAdmittedProgram", result.currentAdmittedProgram);
					
					var currentAdmittedProgramStatuses = result.currentAdmittedProgramStatuses;
					component.set("v.currentAdmittedProgramStatuses", currentAdmittedProgramStatuses);
					component.set("v.hasAdmittedProgramPermission", result.hasAdmittedProgramPermission);
					component.set("v.newAdmittedProgram", {});
					component.set("v.admittedProgramStatusRecord", {});

					var allStatusOptions = me.clone(result.statusOptions);
					component.set('v.statusOptions', allStatusOptions );
					
					var filteredStatusOptions = [];

					allStatusOptions.forEach( (option) =>
					{
						//currentAdmittedProgramStatuses.forEach( (status) =>
						//var existingStatusRecord = false;
						var existingStatusRecord = currentAdmittedProgramStatuses.some( (status) =>
						{
							//if this option value is in a current status, don't show it in the picklist
							return (option.value == status.Status__c)
							// {
							// 	existingStatusRecord = true;
							// }
						});
						if (!existingStatusRecord)
						{
							filteredStatusOptions.push(option);
						}
					});
					component.set('v.filteredStatusOptions', filteredStatusOptions);
					
					component.set('v.chosenFunction','');
					
					resolve( result );
				},
				function (error) {
					me.showToast({
						type:"error",
						message:error,
						duration: 10000
					});
				},
				true
			);			
		}));
	},
	saveRecord: function(component){
		let me = this;
		return new Promise($A.getCallback(function(resolve,reject){
			let accountId = component.get('v.recordId');
			let chosenFunction = component.get('v.chosenFunction');
			
			// let statusStartDate = component.get('v.updateStatusStartDate');
			// let statusEndDate = component.get('v.updateStatusEndDate');
			// let selectedStatusId = component.get('v.selectedStatusId');
			var newAdmittedProgram =  me.clone(component.get('v.newAdmittedProgram'));
			if (chosenFunction == 'Change Program')
			{
				newAdmittedProgram.Start_Date__c = moment(component.get('v.newAdmittedProgram.Start_Date__c')).tz('UTC').format('YYYY-MM-DD');
				newAdmittedProgram.Program_Manager__c = component.get('v.selectedProgramManager.value');
			}

			var admittedProgramStatusRecord =  me.clone(component.get('v.admittedProgramStatusRecord'));
			let paramsMap = {
				accountId,
				chosenFunction,
				'newAdmittedProgram': newAdmittedProgram,
				'admittedProgramStatusRecord': admittedProgramStatusRecord

				// 'programId': me.clone(component.get('v.selectedProgram.value')),
				// 'programStartDate': newAdmittedProgram.Start_Date__c,
				// 'programManagerId': me.clone(component.get('v.selectedProgramManager.value')),
				// 'status': me.clone(component.get('v.newAdmittedProgramStatus')),
				// 'statusStartDateTime': updateStatusStartDate,
				// 'statusEndDateTime': updateStatusEndDate,
				// 'statusId': selectedStatusId,
			};

			// let params = { 
			// 	accountId,  
			// 	chosenFunction, 
			// 	paramsMap,
			// };
			
			console.info('-------------------------------------------');
			console.info('---------saveRecords paramsMap--------', paramsMap);
			console.info('-------------------------------------------');

			me.callApexMethod(
				component,
				"saveRecord",
				{
					'paramsJson': JSON.stringify(paramsMap)
				},
				function (result) {						
					try{				
						console.info('-------------------------------------------');
						console.info('---------saveRecords RESULT--------', result);
						console.info('-------------------------------------------');
						if( result.errorMessage ){
							me.showError(result.errorMessage);						
						}else{
							me.showToast({
								type:"success",
								message:'Saved Successfuly',
								duration: 10000
							});
							resolve( result );
						}
						console.info('ERRORS', me.clone(result));
					}catch(e){
						me.showError(e);
					}
				},
				function (error) {
					me.showError(error);
				},
				true
			);			
		}));
	},
	showError: function(message){
		let me = this;
		me.showToast({
			type:"error",
			message:message,
			duration: 10000
		});
	},
	clean:function(component){
		// component.set('v.updateStatusEndDate');
		component.set('v.chosenFunction');
		component.set('v.selectedProgramManager');
		component.set('v.selectedStatusId');
		component.set('v.selectedStatusRecord');
		// component.set('v.statusStartDateTime');
	},
	clone: function(o){
		return o? JSON.parse(JSON.stringify(o)):o;
	},
})
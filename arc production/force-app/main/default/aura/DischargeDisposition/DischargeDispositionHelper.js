({
    getDischargeDisposition:function(component, event, helper,recordId)
    {
        var startTime=Date.now();
        console.log('Runnig getDischargeDisposition');
        helper.callApexMethod(
            component,
            "getDischargeDisposition",
            { "dischargeDispositionId":recordId},
            function (dischargeDisposition)
            {
                if(dischargeDisposition)
                {
                    // console.log('getDischargeDisposition time:'+((Date.now()-startTime)/1000)+'s');
                    startTime=Date.now();
                    dischargeDisposition.dischargeDispositionObj["sobjectType"]="Discharge_Disposition__c";
                    component.set("v.dischargeDisposition",dischargeDisposition);
                    component.set('v.patient', dischargeDisposition.patient);
                    
                    component.set("v.parentRecordId",dischargeDisposition.dischargeDispositionObj.Patient_Account__c);
                    component.set("v.selectedResponsibleSocialWorker",{
                        "isRecord":true,
                        "label":dischargeDisposition.responsibleSocialWorker.Name,
                        "value":dischargeDisposition.responsibleSocialWorker.Id
                    });
                    component.set("v.responsibleSocialWorkerName",dischargeDisposition.responsibleSocialWorker.Name);
                    if (dischargeDisposition.dischargeDispositionObj.Post_Discharge_Address__c)
                    {
                        component.set("v.selectedPostDischargeAddress",{
                            "isRecord":true,
                            "label":dischargeDisposition.dischargeDispositionObj.Post_Discharge_Address__r.Summary__c,
                            "value":dischargeDisposition.dischargeDispositionObj.Post_Discharge_Address__c
                        });
                    }
                    if (dischargeDisposition.dischargeDispositionObj.Snapshot__c != null) 
                    {
                        var snapshotHtml = dischargeDisposition.dischargeDispositionObj.Snapshot__r.Html__c;
                        component.set("v.snapshotHtml", snapshotHtml);
                    }
                    helper.setFilters(component,event,helper);
                    helper.calculateEditable(component,dischargeDisposition);
                    // console.log("settting loading to false");
                    component.set("v.loading",false);
                    component.set("v.isLoading",false);
                    // console.log("afte loading");
                    // console.log('Setting the data time:'+((Date.now()-startTime)/1000)+'s');
                }
                else
                {
                    helper.showToast({
                        "title":"Unknown Error",
                        "message":"Unable to load Discharge Disposition",
                        "type":"error"
                    });
                    component.set("v.loading",false);
                    component.set("v.isLoading",false);
                }
            },
            null,
            false
        );
    },
    getParameterByName:function(component, event, name)
    {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    // createDischargeDisposition:function(component,event,helper)
    // {
    //     var patientId=component.get("v.parentRecordId");
    //     var dischargeTypeSelected=component.get("v.dischargeTypeSelected");
    //     var isEmergencyTransfer=(dischargeTypeSelected=='Discharge Plan'?false:true);
    //     helper.callApexMethod(
    //         component,
    //         "createDischargeDisposition",
    //         { "patientId":patientId,"isEmergencyTransfer":isEmergencyTransfer},
    //         function (dischargeDisposition)
    //         {
    //             if(dischargeDisposition)
    //             {
    //                 /*
    //                 console.log('disposition result:'+JSON.stringify(dischargeDisposition));
    //                 dischargeDisposition.dischargeDispositionObj["sobjectType"]="Discharge_Disposition__c";
    //                 component.set("v.dischargeDisposition",dischargeDisposition);
    //                 component.set("v.selectedResponsibleSocialWorker",{
    //                     "isRecord":true,
    //                     "label":dischargeDisposition.responsibleSocialWorker.Name,
    //                     "value":dischargeDisposition.responsibleSocialWorker.Id
    //                 });
    //                 component.set("v.responsibleSocialWorkerName",dischargeDisposition.responsibleSocialWorker.Name);
    //                 helper.calculateEditable(component,dischargeDisposition);
    //                 */
    //                 window.open("/"+dischargeDisposition.dischargeDispositionObj.Id,'_top');
    //             }
    //             else
    //             {
    //                 helper.showToast({
    //                     "title":"Unknown Error",
    //                     "message":"Unable to create Discharge Dispositionr",
    //                     "type":"error"
    //                 });
    //                 component.set("v.loading",false);
    //             }
    //         },
    //         null,
    //         false
    //     );
    // },
    getPatient:function(component,event,helper)
    {
        var patientId=component.get("v.parentRecordId");
        if(!$A.util.isEmpty(patientId))
        {
            console.log("before calling getPatientById");
            helper.callApexMethod(
                component,
                "getPatientById",
                { "patientId":patientId},
                function (result)
                {
                    if(result)
                    {
                        component.set("v.patient",result);

                        helper.setFilters(component,event,helper);
                    }
                    else
                    {
                        helper.showToast({
                            "title":"Unknown Error",
                            "message":"Get Patient Info Error",
                            "type":"error"
                        });
                    }
                    component.set("v.loading",false);
                    component.set("v.isLoading",false);
                },
                null,
                false
            );
        }
        else
        {
            component.set("v.loading",false);
        }
    },
    cancelDischargeDisposition:function(component,event,helper)
    {
        var dischargeDisposition=component.get("v.dischargeDisposition");
        if(!$A.util.isEmpty(dischargeDisposition))
        {
            helper.callApexMethod(
                component,
                "cancelDischargeDisposition",
                { "dischargeDispositionId":dischargeDisposition.dischargeDispositionObj.Id},
                function (result)
                {
                    if(result == 'SUCCESS')
                    {
                        /*
                        var redirectEvent=$A.get("e.force:navigateToURL");
                        redirectEvent.setParams({
                            "url":"/"+dischargeDisposition.dischargeDispositionObj.Patient_Account__c,
                            "isredirect":true
                        });
                        redirectEvent.fire();
                        */
                        window.open("/"+dischargeDisposition.dischargeDispositionObj.Patient_Account__c,'_top');
                    }
                    else
                    {
                        helper.showToast({
                            "title":"Cancel Discharge Disposition Error",
                            "message": result,
                            "type":"error"
                        });
                        component.set("v.loading",false);
                    }
                },
                null,
                false
            );
        }
    },
    saveDischargeDisposition:function(component,event,helper)
    {
        var dischargeDisposition=component.get("v.dischargeDisposition");
        if(!$A.util.isEmpty(dischargeDisposition))
        {
            var selectedResponsibleSocialWorker=component.get("v.selectedResponsibleSocialWorker");
            dischargeDisposition.dischargeDispositionObj.Responsible_Social_Worker__c=selectedResponsibleSocialWorker.value;
            dischargeDisposition.dischargeDispositionObj["sobjectType"]="Discharge_Disposition__c";
            helper.callApexMethod(
                component,
                "saveDischargeDisposition",
                {"dischargeDispositionObj":dischargeDisposition.dischargeDispositionObj},
                function (result)
                {
                    if(result)
                    {
                        var redirectEvent=$A.get("e.force:navigateToURL");
                        redirectEvent.setParams({
                            "url":"/"+dischargeDisposition.dischargeDispositionObj.Id,
                            "isredirect":true
                        });
                        redirectEvent.fire();
                    }
                    else
                    {
                        helper.showToast({
                            "title":"Unknown Error",
                            "message":"Save Discharge Disposition Error",
                            "type":"error"
                        });
                        component.set("v.loading",false);
                    }
                },
                null,
                false
            );
        }
    },
    refreshDischargeDisposition: function(component, event, helper)
    {
        var redirectEvent=$A.get("e.force:navigateToURL");
        redirectEvent.setParams({
            "url":"/" + component.get('v.dischargeDisposition.dischargeDispositionObj.Id'),
            "isredirect":true
        });
        redirectEvent.fire();
    },
    finalizeDischargeDisposition:function(component,event,helper)
    {
        var dischargeDisposition=component.get("v.dischargeDisposition");
        if(!$A.util.isEmpty(dischargeDisposition))
        {
            var selectedResponsibleSocialWorker=component.get("v.selectedResponsibleSocialWorker");
            dischargeDisposition.dischargeDispositionObj.Status__c='Finalized';
            dischargeDisposition.dischargeDispositionObj["sobjectType"]="Discharge_Disposition__c";
            helper.callApexMethod(
                component,
                "saveDischargeDisposition",
                {"dischargeDispositionObj":dischargeDisposition.dischargeDispositionObj},
                function (result)
                {
                    if(result == 'SUCCESS')
                    {
                        var redirectEvent=$A.get("e.force:navigateToURL");
                        redirectEvent.setParams({
                            "url":"/"+dischargeDisposition.dischargeDispositionObj.Id,
                            "isredirect":true
                        });
                        redirectEvent.fire();
                    }
                    else
                    {
                        helper.showToast({
                            "title":"Error Saving",
                            "message": result,
                            "type":"error"
                        });
                        component.set("v.loading",false);
                    }
                },
                null,
                false
            );
        }
    },
    calculateEditable:function(component,dischargeDisposition)
    {
        var retval=false;
        if(dischargeDisposition.dischargeDispositionObj.Status__c!='Finalized' &&
           dischargeDisposition.dischargeDispositionObj.Status__c!='Cancel')
        {
            /**
             * TODO - Make sure to add System Administrator check back by replace the logic with the commented
             * logic below:
             * 
             * dischargeDisposition.currentUser.Profile.Name=='System Administrator' ||
            dischargeDisposition.dischargeDispositionObj.Responsible_Social_Worker__c==dischargeDisposition.currentUser.Id
                * 
                */
            if(dischargeDisposition.dischargeDispositionObj.Responsible_Social_Worker__c==dischargeDisposition.currentUser.Id || dischargeDisposition.isMedRecords)
            {
                component.set("v.isEditable",true);
                var sidebar = component.find("DischargeDispositionSidebar");
                sidebar.set("v.isEditable",true);
                retval=true;
            }
        }
        return retval;
    },
    setFixedHeader:function(component,helper)
    {
        /*
        window.onscroll = function() {myFunction()};
        
        // Get the header
        var header=document.getElementById("DischargeDispositionHeader"); //component.find("DischargeDispositionStickyHeader").getElement();//document.getElementById("DischargeDispositionHeader");
        if(header==undefined)
        {
            return;
        }
        // Get the offset position of the navbar
        var sticky = header.offsetTop;
        component.set("v.offsetTop",sticky);
        // Add the sticky class to the header when you reach its scroll position. Remove "sticky" when you leave the scroll position
        function myFunction() {
            var sticky=component.get("v.offsetTop");
            console.log('window.pageYOffset:'+window.pageYOffset+',Header OffsetTop:'+sticky);
            var headerBanner=component.find("DischargeDispositionStickyHeader")
            if (window.pageYOffset > sticky) {
                $A.util.addClass(headerBanner,"sticky");
            } else {
                $A.util.removeClass(headerBanner,"sticky");
            }
        }*/
    },
    setFilters: function(component, event, helper)
	{
        
		var psetAssignmentFilters = 
		[
			{
				'fieldName': 'Assignee.IsActive',
				'condition': '=',
				'value': true
			}
		];
		
		var userTypes = "'Standard'";
		if (userTypes && userTypes.length > 0)
		{
			//userTypes should be a single-quoted, comma-separated String
			var userTypeString = '(';
			userTypeString += userTypes;
			userTypeString += ')';
		
			psetAssignmentFilters.push(
			{
				'fieldName': 'Assignee.UserType',
				'condition': 'IN',
				'value': userTypeString
			});
		}

		//currently no profiles filtered 210519 JN
		var profileNames = '';
		if (profileNames && profileNames.length > 0)
		{
			//profileNames should be a single-quoted, comma-separated String
			var profileNameString = '(';
			profileNameString += profileNames;
			profileNameString += ')';

			psetAssignmentFilters.push(
			{
				'fieldName': 'Assignee.Profile.Name',
				'condition': 'IN',
				'value': profileNameString
			});
		}
		
		var permissionSetNames = component.get('v.permissionSetNames');
		if (permissionSetNames && permissionSetNames.length > 0)
        {
            //permissionSetNames should be a single-quoted, comma-separated String
            var permSetNameString = '(';
            permSetNameString += permissionSetNames;
            permSetNameString += ')';

            psetAssignmentFilters.push(
            {
                'fieldName': 'PermissionSet.Name',
                'condition': 'IN',
                'value': permSetNameString
            });
        }
		console.log('psetAssignmentFilters ' + JSON.parse(JSON.stringify(psetAssignmentFilters)));
		
		component.set('v.psetAssignmentFilters', psetAssignmentFilters);

        if (component.get('v.patient'))
        {
            var patientContactId = component.get('v.patient').Patient_Contact__c;
            var postDischargeAddressFilters = [
                {
                    'fieldName': 'Post_Discharge_Address__c',
                    'condition': '=',
                    'value': true
                },
                {
                    'fieldName': 'Contact__c',
                    'condition': '=',
                    'value': patientContactId
                }
            ];
            component.set('v.postDischargeAddressFilters', postDischargeAddressFilters);
        }
        var responsibleSocialWorkerFilter=[
            {
                'fieldName': 'Role__c',
                'condition': '=',
                'value': 'Clinical Social Worker'
            }];
        component.set("v.responsibleSocialWorkerFilter", responsibleSocialWorkerFilter);
        
	},
    handleFinalizeDischarge:function(component,event,helper){
        component.set("v.loading",true);
        var dischargeDisposition=component.get("v.dischargeDisposition");
        var hasIncompletedSection=false;
        if(!$A.util.isEmpty(dischargeDisposition.dischargeSectionList))
        {
            for(var dischargeSection in dischargeDisposition.dischargeSectionList)
            {
                // console.log(dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Role__c+' status:'+dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Status__c);
                if(dischargeDisposition.dischargeSectionList[dischargeSection].dischargeSectionObj.Status__c!='Completed')
                {
                    hasIncompletedSection=true;
                    break;
                }
            }
        }

        if(hasIncompletedSection)
        {
            helper.showToast({
                "title":"Incomplete Sections",
                "message":"Discharge Disposition cannot be finalized until all sections are completed.",
                "type":"warning"
            });
            component.set("v.loading",false);
        }
        else
        {
            component.set("v.showFinalizeModal", true);
            component.set("v.loading",false);
        }
    
    },
    handlePrintDischarge:function(component,event,helper){
        let dischargeDisposition = component.get("v.dischargeDisposition");
		let urlval = dischargeDisposition.dischargeDispositionObj.Print_Link__c.split('"')[1].replaceAll("&amp;", "&");
		window.open(urlval, "_blank");
    },
    handlePrintDraftDischarge:function(component,event,helper){
        component.set("v.showPrintDraftModal", true);
    },
    handleReOpenDischargeDisposition:function(component,event,helper){
        component.set("v.loading",true);
        component.set("v.showReOpenModal", true);
        component.set("v.loading",false);
    },
    reopenDischargeDisposition:function(component,event,helper)
    {
        var dischargeDisposition=component.get("v.dischargeDisposition");
        if(!$A.util.isEmpty(dischargeDisposition))
        {
            var selectedResponsibleSocialWorker=component.get("v.selectedResponsibleSocialWorker");
            dischargeDisposition.dischargeDispositionObj.Status__c='Draft';
            dischargeDisposition.dischargeDispositionObj["sobjectType"]="Discharge_Disposition__c";
            helper.callApexMethod(
                component,
                "saveDischargeDisposition",
                {"dischargeDispositionObj":dischargeDisposition.dischargeDispositionObj},
                function (result)
                {
                    if(result == 'SUCCESS')
                    {
                        var redirectEvent=$A.get("e.force:navigateToURL");
                        redirectEvent.setParams({
                            "url":"/"+dischargeDisposition.dischargeDispositionObj.Id,
                            "isredirect":true
                        });
                        redirectEvent.fire();
                    }
                    else
                    {
                        helper.showToast({
                            "title":"Error Saving",
                            "message": result,
                            "type":"error"
                        });
                        component.set("v.loading",false);
                    }
                },
                null,
                false
            );
        }
    },
})
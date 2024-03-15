({
    saveEGO : function(component, event, helper){
        console.log("TreatmentPlan_EGO_HeaderController.js saveEgo");
        let saveEGOEvent=$A.get("e.c:SaveEGOEvent");
        saveEGOEvent.fire();
    },
    finalizeEGO : function(component, event, helper){
        component.set("v.showFinalizeModal", true);
    },
    handleBackToDraftTreatmentPlan : function(component, event, helper){
        component.set("v.showFinalizeModal", false);
    },
    handleConfirmFinalizeEGO:function(component, event, helper)
    {
        console.log('in handleConfirmFinalizeEGO');
        component.set("v.loading", true);
        let EGOActionEvent = $A.get("e.c:EGOActionEvent");
        EGOActionEvent.setParam("action", "Validate");
        EGOActionEvent.fire();
        let treatmentPlan=component.get('v.treatmentPlan');
        var isAllValid=true;
        domainLoop:
        for(var domain in treatmentPlan.domains)
        {
            var goals=treatmentPlan.domains[domain].goals;
            console.log('Goals');
            if(!$A.util.isEmpty(goals))
            {
                for(var goal in goals)
                {
                    if(treatmentPlan.isEGOR && !$A.util.isEmpty(goals[goal].goalObj.Continued_From_Goal__c) &&
                       $A.util.isEmpty(goals[goal].rating))
                    {
                        isAllValid=false;
                        break domainLoop;
                    }
                    if($A.util.isEmpty(goals[goal].goalObj.Label__c))
                    {
                        isAllValid=false;
                        break domainLoop;
                    }
                    var objectives=goals[goal].objectives;
                    if(!$A.util.isEmpty(objectives))
                    {
                        for(var objective in objectives)
                        {
                            if(treatmentPlan.isEGOR && !$A.util.isEmpty(objectives[objective].objectiveObj.Continued_From_Objective__c) &&
                              $A.util.isEmpty(objectives[objective].rating))
                            {
                                isAllValid=false;
                                break domainLoop;
                            }
                            if($A.util.isEmpty(objectives[objective].objectiveObj.Label__c))
                            {
                                isAllValid=false;
                                break domainLoop;
                            }
                        }
                    }
                }
            }
        }
        if(isAllValid)
        {
            let EGOActionEvent = $A.get("e.c:EGOActionEvent");
            EGOActionEvent.setParam("action", "Finalize");
            EGOActionEvent.fire();
            console.log("Fired Finalize event");
        }
        else
        {
            helper.showToast({
                'title':'Incomplete Input Error',
                'message':'There seems to be something incompete.  Please check for messages in red.',
                'type':'error'
            });
            component.set("v.loading", false);
        }
    },
    // cancel : function(component, event, helper)
	// {
    //     // helper.showSpinner(component);
    //     var isDirty = component.get("v.isDirty");
    // 	if(isDirty) {
    // 		component.set("v.showCancelModal", true);
    //     } else {
    //     let closeEvent = component.getEvent('closeModalEvent');
    //     let data = {
    //         'instanceName': 'ConductEGOModal', 
    //         'isDirty': isDirty 
    //     };
    //     closeEvent.setParams({
    // 		'data': data
    // 	});
    //     closeEvent.fire();
    //     }
	// },
    cancelEdit:function(component, event, helper)
    {
        component.set('v.showCancelModal', true);
    },
    handleIsDirty:function(component, event, helper)
	{
    	component.set("v.isDirty", true);
	},
    handleDiscardChanges: function(component, event, helper) {
        // component.set("v.showCancelModal", false);
        $A.get('e.force:refreshView').fire();
        // let closeEvent = component.getEvent('closeModalEvent');
        // closeEvent.fire();
    },
    handleBackToEGO: function(component, event, helper) {
        component.set("v.showCancelModal", false);
    },

    printEgo : function (component, event, helper) {
        let treatmentPlan = JSON.parse(JSON.stringify(component.get("v.treatmentPlan")));
        //let treatmentPlan = component.get("v.treatmentPlan");
        console.log("#### treatmentPlan ----> ", treatmentPlan);

        if (treatmentPlan.ego.Status__c !== "Finalized") {
            let saveEGOEvent=$A.get("e.c:SaveEGOEvent");
            saveEGOEvent.fire();
        }

        // var urlEvent = $A.get("e.force:navigateToURL");
        // urlEvent.setParams({
        //   "url": "/apex/SDOC__SDCreate1?id="+ treatmentPlan.ego.Id +"&Object=EGO__c&doclist=EGO_PDF&autoopen=0"
        // });
        // urlEvent.fire();

        // let urlval = "/apex/SDOC__SDCreate1?id="+ treatmentPlan.ego.Id +"&Object=EGO__c&doclist=EGO_HTML&autoopen=0";
        
        // if('Draft' == treatmentPlan.ego.Status__c) {
        //     urlval = "/apex/SDOC__SDCreate1?id="+ treatmentPlan.ego.Id +"&Object=EGO__c&doclist=EGO_PDF&autoopen=0";
        // }

        let urlval = treatmentPlan.ego.Print_Link__c.split('"')[1].replaceAll(
            "&amp;",
            "&"
          );
        
        window.open(urlval, '_blank');
    }
})
({
    setDisplay : function(component, chosenTabIndex) 
    {
        var tabs = component.get('v.tabs');
        var selectedTabId;
        tabs.forEach(function(item, index) {
            if (index == chosenTabIndex)
            {
                item.isSelected = true;
                selectedTabId = item.id;
            } else {
                item.isSelected = false;
            }
        });
        this.sortTabs(tabs);
        component.set('v.tabs', tabs);
        component.set('v.selectedTabId', selectedTabId);
    },
    shouldShowNursingShiftItems : function(component){
        return new Promise($A.getCallback(function(resolve){
            var action = component.get("c.getViewConfiguration");
            action.setParams({
                "userId" : $A.get("$SObjectType.CurrentUser.Id")
            });
            action.setCallback(this, $A.getCallback(function(actionResult) {
                let appLabel = actionResult.getReturnValue().CurrentAppName;
                console.log('***appLabel : ' + appLabel);
                component.set('v.showNursingShiftItems', 'Nursing' == appLabel);
                //resolve('Nursing' == appLabel);
                resolve(actionResult.getReturnValue());
            }));
            $A.enqueueAction(action);
        }));
    },
    retrieveSimplifiedViewConfiguration : function(component){
        return new Promise($A.getCallback(function(resolve){
            var action = component.get("c.getViewConfiguration");
            action.setParams({
                "userId" : $A.get("$SObjectType.CurrentUser.Id")
            });
            action.setCallback(this, $A.getCallback(function(actionResult) {
                //let appLabel = actionResult.getReturnValue().CurrentAppName;
                //console.log('***appLabel : ' + appLabel);
                //component.set('v.showNursingShiftItems', 'Nursing' == appLabel);
                //resolve('Nursing' == appLabel);
                resolve(actionResult.getReturnValue());
            }));
            $A.enqueueAction(action);
        }));
    },
    callActionApi : function(component, args) {
        var actionAPI = component.find('quickActionAPI');
        actionAPI.setActionFieldValues(args).then(function(){
            actionAPI.invokeAction(args);
        }).catch(function(e){
            console.error(e.errors);
        });
    },
    getSummaryInfo : function(component) {
        component.set('v.loadingTabs', true);
        var action = component.get("c.getSummaryInfoByPatient");

        action.setParams({
            "patientId" 	: component.get("v.recordId")
        });
        
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if (component.isValid() && state === "SUCCESS") {
                let overdueTags = actionResult.getReturnValue().overdueTags;
                let dueNext7Days = actionResult.getReturnValue().dueNext7Days;
                let totalOpen = actionResult.getReturnValue().totalOpen;

                // let openItemTitle = '<table style="width:100%"><tr><td style="padding: 0px;">Overdue: ' + overdueTags 
                //     + '</td><td style="padding: 0px;">Due Next 7 Days: ' + dueNext7Days 
                //     + '</td><td style="padding: 0px;">Total Open: ' + totalOpen 
                //     + '</td></tr></table>';
                // let openItemTitle = 'Overdue: ' + overdueTags + ',\n Due Next 7 Days: ' + dueNext7Days + '\n Total Open: ' + totalOpen;
                
                let openItemTitle = '<div class="slds-grid slds-wrap" >'
                                        + '<div class="slds-col slds-size_12-of-12 slds-medium-size_6-of-12 slds-large-size_4-of-12">'
                                            + 'Overdue: ' + overdueTags
                                        + '</div>'
                                        + '<div class="slds-col slds-size_12-of-12 slds-medium-size_6-of-12 slds-large-size_4-of-12">'
                                            + 'Due Next 7 Days: ' + dueNext7Days
                                        + '</div>'
                                        + '<div class="slds-col slds-size_12-of-12 slds-large-size_4-of-12">'
                                            + 'Total Open: ' + totalOpen
                                        + '</div>'
                                    + '</div>';

                // let openItemTitle = '<lightning:layout multipleRows="true">'
                //                         + '<lightning:layoutItem size="6">col1</lightning:layoutItem>'
                //                         + '<lightning:layoutItem size="6">col2</lightning:layoutItem>'
                //                     + '</lightning:layout>';
                
                // let openItemTitle = '<table style="width:100%"><tr><td style="padding: 0px;">Overdue: ' + overdueTags 
                //     + '</td><td style="padding: 0px;">Due Next 7 Days: ' + dueNext7Days 
                //     + '</td><td style="padding: 0px;">Total Open: ' + totalOpen 
                //     + '</td></tr></table>';

                
                console.log('***** openItemTitle ---> ', openItemTitle);
                component.set("v.openItemTitle", openItemTitle);

                var tabs = component.get('v.tabs');
                var openItemTab = tabs.find(tab => tab.id == 'openItems');
                openItemTab.subTitle = openItemTitle;
                this.sortTabs(tabs);
                component.set('v.tabs', tabs);
                component.set('v.loadingTabs', false);
            }
        });
        $A.enqueueAction(action);
	},
    sortTabs : function(tabs) {
        tabs.sort((elem1, elem2) => elem1.sequence-elem2.sequence);
    },
    // checkForChartClosed : function(component){
    //     return new Promise($A.getCallback(function(resolve){
    //         var action = component.get("c.getAccountById");
    //         action.setParams({
    //             "accountId" : component.get("v.recordId")
    //         });
    //         action.setCallback(this, $A.getCallback(function(account) {
    //             const statusesToHideTabs = ["Open Inquiry", "Active Inquiry", "Waitlist", "Declined", "Withdrawn", "Inactive"];
    //             if(null != account && (account.getReturnValue().Current_Admission__r.Chart_Closed__c || statusesToHideTabs.includes(account.getReturnValue().Current_Admission__r.Stage__c))) {
    //                 var tabs = component.get('v.tabs');
    //                 var createNewTab = tabs.find(tab => tab.id == 'createnew');
    //                 createNewTab.show = false;
    //                 var treatmentPlanTab = tabs.find(tab => tab.id == 'treatmentPlan');
    //                 treatmentPlanTab.show = false;
    //                 var draftsTab = tabs.find(tab => tab.id == 'drafts');
    //                 draftsTab.show = false;
    //                 var openItemsTab = tabs.find(tab => tab.id == 'openItems');
    //                 openItemsTab.show = false;
    //                 var shiftItemsTab = tabs.find(tab => tab.id == 'shiftItems');
    //                 shiftItemsTab.show = false;
    //                 tabs = tabs.filter((value) => value.show == true);
    //                 component.set('v.tabs', tabs);
    //             }
    //         }));
    //         $A.enqueueAction(action);
    //     }));
    // },
    // shouldShowClinicalPatientFile : function(component){
    //     return new Promise($A.getCallback(function(resolve){
    //         var action = component.get("c.shouldShowClinicalPatientFile");
    //         action.setParams({
    //             "accountId" : component.get("v.recordId")
    //         });
    //         action.setCallback(this, $A.getCallback(function(result) {
    //             if(null != result && result.getReturnValue()){
    //                 console.log('in shouldShowClinicalPatientFile - result.getReturnValue() : ', result.getReturnValue());
    //                 component.set('v.showClinicalPatientFile', true);
    //             }
    //         }));
    //         $A.enqueueAction(action);
    //     }));
    // },
    getPostRenderConfig : function(component){
        return new Promise($A.getCallback(function(resolve){
            var action = component.get("c.getPostRenderConfig");
            action.setParams({
                "accountId" : component.get("v.recordId")
            });
            action.setCallback(this, $A.getCallback(function(result) {
                console.log('getPostRenderConfig - result.getReturnValue() : ', result.getReturnValue());
                if(null != result && 'true' == result.getReturnValue().shouldShowClinicalPatientFile){
                    console.log('in shouldShowClinicalPatientFile - result.getReturnValue().shouldShowClinicalPatientFile : ', result.getReturnValue().shouldShowClinicalPatientFile);
                    component.set('v.showClinicalPatientFile', true);
                
                    const statusesToHideTabs = ["Open Inquiry", "Active Inquiry", "Waitlist", "Declined", "Withdrawn", "Inactive"];
                    if(null != result && ('true' == result.getReturnValue().admissionChartClosed || statusesToHideTabs.includes(result.getReturnValue().admissionStage))) {
                        var tabs = component.get('v.tabs');

                        if('false' == result.getReturnValue().userIsMedRecords) {
                            var createNewTab = tabs.find(tab => tab.id == 'createnew');
                            console.log('createNewTab : ', createNewTab)
                            createNewTab.show = false;
                        }

                        var treatmentPlanTab = tabs.find(tab => tab.id == 'treatmentPlan');
                        console.log('treatmentPlanTab : ', treatmentPlanTab)
                        treatmentPlanTab.show = false;
                        var draftsTab = tabs.find(tab => tab.id == 'drafts');
                        console.log('draftsTab : ', draftsTab)
                        draftsTab.show = false;
                        var openItemsTab = tabs.find(tab => tab.id == 'openItems');
                        console.log('openItemsTab : ', openItemsTab)
                        openItemsTab.show = false;
                        var shiftItemsTab = tabs.find(tab => tab.id == 'shiftItems');
                        if(shiftItemsTab) {
                            console.log('shiftItemsTab : ', shiftItemsTab)
                            shiftItemsTab.show = false;
                        }
                        tabs = tabs.filter((value) => value.show == true);
                        component.set('v.tabs', tabs);
                    }
                }
            }));
            $A.enqueueAction(action);
        }));
    },
})
({
    getTreatmentHistory : function(component, event, helper, moveMonths) {
        let context = component.get('v.context');
        let patientId = component.get("v.recordId");
        let currentViewOptionSet = component.get("v.currentViewOptionSet");
        let selectedDateRange = component.get("v.selectedDateRange");
        let lastWeeks = -1;
        // Only when move buttons are not clicked, which means on initial load
        if($A.util.isEmpty(moveMonths) || moveMonths == 0){
            if(!$A.util.isEmpty(selectedDateRange)){
                if(selectedDateRange != 'Custom'){
                    lastWeeks = parseInt(selectedDateRange);
                }else{
                    lastWeeks = null;
                }
            }
        }else{
            lastWeeks = null;
        }
        let optionItems = [];
        if(!$A.util.isEmpty(currentViewOptionSet)){
            if(!$A.util.isEmpty(currentViewOptionSet.checkboxItems)){
                currentViewOptionSet.checkboxItems.forEach(function(checkboxItem){
                    if(checkboxItem.checkboxValue==true){
                        optionItems.push(checkboxItem.optionItemObj.MasterLabel);
                    }
                });
            }
            let treatmentHistory = component.get("v.treatmentHistory");
            if($A.util.isEmpty(treatmentHistory)){
                treatmentHistory = {};
            }
            if($A.util.isEmpty(treatmentHistory.startDate)){
                // console.log('startDate is empty');
                treatmentHistory.startDate=null;
            }else{
                // console.log('startDate is:'+component.get("v.customStartDate"));
                treatmentHistory.startDate = component.get("v.customStartDate");
            }
            if($A.util.isEmpty(treatmentHistory.endDate)){
                // console.log('endDate is empty');
                treatmentHistory.endDate=null;
            }else{
                treatmentHistory.endDate = component.get("v.customEndDate");
            }
            var changeValue = event.getParam("value");
           
            if(selectedDateRange === "9999") {
                treatmentHistory.selectAll = true;
            } else {
                treatmentHistory.selectAll = false;
            }
            
            treatmentHistory.context = context;
            treatmentHistory.patientId = patientId;
            treatmentHistory.viewOptionItemLabelList = optionItems;
            treatmentHistory.moveMonths = moveMonths;
            treatmentHistory.lastWeeks = lastWeeks;
            let treatmentHistoryRequestString = JSON.stringify(treatmentHistory);
            // console.log("Treatment History String:"+treatmentHistoryRequestString);
            helper.callApexMethod(
                component,
                "getTreatmentHistory",
                { "treatmentHistoryString" : treatmentHistoryRequestString},
                function (treatmentHistoryString) {
                    // console.log("treatmentHistoryString:"+treatmentHistoryString);
                    if(treatmentHistoryString) {
                        var treatmentHistory = JSON.parse(treatmentHistoryString);
                        var data = [];
                        var historyItemIdMap = {};
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        // console.log('userId : ' + userId);
                        if(!$A.util.isEmpty(treatmentHistory.itemList)){
                            debugger;
                            treatmentHistory.itemList.forEach(function(historyItem)
                            {
                                let details = '';
                                historyItemIdMap[historyItem.record["Id"]] = historyItem;

                                // console.log('historyItem.ownerId : ' + historyItem.ownerId);
                                // console.log('historyItem.URL : ' + historyItem.URL);
                                data.push({
                                    "Id" : historyItem.record["Id"],
                                    "item" : historyItem.record["Name"],
                                    "details" : historyItem.details,
                                    "itemDate" : historyItem.itemDate,
                                    "recorded" : historyItem.record.CreatedBy.Name,
                                    "type" : historyItem.definition.Label__c,
                                    "URL" : historyItem.URL,
                                    'urlLabel' : historyItem.urlLabel,
                                    "key" : historyItem.record["Id"]+historyItem.definition.Label__c,
                                    "finalizedDateTime" : historyItem.record["Finalized_Date_Time__c"]
                                });
                            });
                        }
                        //console.log("history item id map:"+JSON.stringify(historyItemIdMap));
            			component.set("v.treatmentHistory", treatmentHistory);
                        component.set("v.customStartDate", $A.localizationService.formatDateUTC(treatmentHistory.startDate, "YYYY-MM-DD"));
                        component.set("v.customEndDate", $A.localizationService.formatDateUTC(treatmentHistory.endDate, "YYYY-MM-DD"));
                        component.set("v.data",data);
                        component.set("v.historyItemIdMap",historyItemIdMap);
                        helper.hideSpinner(component);
                    }else{
                        helper.showToast({
                            "title":"Error",
                            "type":"error",
                            "message":"Unknown system error."
                        });
                    }
                },
                null,
                true
            );
        }
    },
    showSpinner: function(component)
    {
        // console.log("show :"+component.get("v.loading"));
        component.set('v.loading', true);
    },
    hideSpinner: function(component)
    {
        component.set('v.loading', false);
    },
    clearSelection : function(component, event, helper){
        component.set("v.selectedRecordId",null);
        let treatmentHistorySelectedEvent = $A.get("e.c:TreatmentHistorySelectedEvent");
        treatmentHistorySelectedEvent.setParams({
            "selectedRecordId" : null
        });
        // console.log("Firing treatmentHistorySelectedEvent:"+treatmentHistorySelectedEvent);
        treatmentHistorySelectedEvent.fire();
    },


    sortBy: function(field, reverse, primer) {
        var key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

    handleSort: function(cmp, event) {
        let sortedBy = event.getParam('fieldName');
        let sortDirection = event.getParam('sortDirection');

        let cloneData = cmp.get('v.data').slice(0);
        cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
        
        cmp.set('v.data', cloneData);
        cmp.set('v.sortDirection', sortDirection);
        cmp.set('v.sortedBy', sortedBy);
    }
})
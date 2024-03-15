({
	doInit: function(component, event, helper) {
        // if (!component.get("v.recordId")) {
            // component.find("recordEditor").getNewRecord(
            //     "Recurrence__c", // sObject type (objectApiName)
            //     null, // recordTypeId
            //     true, // skip cache?
            //     $A.getCallback(function() {
            //         var rec = component.get("v.recurrenceRecord");
            //         var error = component.get("v.recordError");
            //         if (error || (rec === null)) {
            //             console.log("Error initializing record template: " + error);
            //             return;
            //         }
            //         console.log("Record template initialized: " + JSON.stringify(rec));
            //     })
            // );
            
        // };

        helper.loadRecurrencePatternList(component);
        helper.loadDailyOptionList(component);
        helper.loadEndTypeList(component);
        helper.loadMonths(component);
        helper.loadWeekdays(component);
        
        var recurrenceRecord = component.get('v.recurrenceRecord');
        var recurrenceId = recurrenceRecord.Id;
        
        var recurrencePattern = component.get("v.recurrenceRecord.Recurrence_Pattern__c");
        if(!recurrencePattern) {
            component.set("v.recurrenceRecord.Recurrence_Pattern__c", "Weekly");
        }
        var endType = recurrenceRecord.End_Type__c;
        if(!endType) {
            component.set("v.recurrenceRecord.End_Type__c", "End By Date");
        }
        var startDate = recurrenceRecord.Start_Date__c;
        if(!startDate) {
            var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
            component.set("v.recurrenceRecord.Start_Date__c", today);
        }
        component.set("v.oldRecurrenceRecord", component.get("v.recurrenceRecord"));

        // var savedRecurrence = component.get("v.recurrence");
        // var isSaved = component.get("v.isSaved");
        
        // if(savedRecurrence && savedRecurrence.startDate && !recurrenceId) {
        //     component.set("v.recurrenceRecord.Start_Date__c", savedRecurrence.startDate);
        // }
        
        // if(savedRecurrence && isSaved) {
        //     component.set("v.recurrenceRecord.Recurrence_Pattern__c", savedRecurrence.recurrencePattern);
        //     component.set("v.recurrenceRecord.Recur_every__c", savedRecurrence.recurEvery);
        //     component.set("v.recurrenceRecord.Weekdays__c", savedRecurrence.weekdays);
        //     component.set("v.recurrenceRecord.Start_Date__c", savedRecurrence.startDate);
        //     component.set("v.recurrenceRecord.End_By__c", savedRecurrence.endDate);
        //     component.set("v.recurrenceRecord.End_Type__c", savedRecurrence.endType);
        //     component.set("v.recurrenceRecord.Number_of_Occurrences__c", savedRecurrence.numberOfOccurrences);
        //     component.set("v.recurrenceRecord.Daily_Option__c", savedRecurrence.dailyOption);
        //     component.set("v.recurrenceRecord.Monthly_Day_Number__c", savedRecurrence.monthlyDayNumber);
        //     component.set("v.recurrenceRecord.Yearly_Month__c", savedRecurrence.yearlyMonth);
        //     component.set("v.recurrenceRecord.Yearly_Day_Number__c", savedRecurrence.yearlyDayNumber);
        // };

        var weekdays = recurrenceRecord.Weekdays__c;
        if(weekdays) {
            component.set("v.weekdays", weekdays.split(';'));
        };

        var recurEvery = recurrenceRecord.Recur_every__c;
        if(!recurEvery) {
            component.set("v.recurrenceRecord.Recur_every__c", 1);
        }
        
        var dailyOption = recurrenceRecord.Daily_Option__c;
        console.log('dailyOption loaded ' + JSON.stringify(dailyOption));
        if(!dailyOption) {
            component.set("v.recurrenceRecord.Daily_Option__c", "Every Day");
        }
        
        var monthlyDayNumber = recurrenceRecord.Monthly_Day_Number__c;
        if(!monthlyDayNumber) {
            component.set("v.recurrenceRecord.Monthly_Day_Number__c", 1);
        }
        
        var yearlyMonth = recurrenceRecord.Yearly_Month__c;
        if(!yearlyMonth) {
            component.set("v.recurrenceRecord.Yearly_Month__c", "January");
        }
        
        var yearlyDayNumber = recurrenceRecord.Yearly_Day_Number__c;
        if(!yearlyDayNumber) {
            component.set("v.recurrenceRecord.Yearly_Day_Number__c", 1);
        }
        helper.loadDailyOptionList(component);
    },
	handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === "CHANGED") {
            // get the fields that are changed for this record
            var changedFields = eventParams.changedFields;
            console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            // record is changed so refresh the component (or other component logic)
        } else if (eventParams.changeType === "LOADED") {
            var recurrencePattern = component.get("v.recurrenceRecord.Recurrence_Pattern__c");
            if(!recurrencePattern) {
                component.set("v.recurrenceRecord.Recurrence_Pattern__c", "Weekly");
            }
        	var endType = component.get("v.recurrenceRecord.End_Type__c");
        	if(!endType) {
        		component.set("v.recurrenceRecord.End_Type__c", "End By Date");
        	}
        	var startDate = component.get("v.recurrenceRecord.Start_Date__c");
        	if(!startDate) {
        		var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        		component.set("v.recurrenceRecord.Start_Date__c", today);
        	}
        	component.set("v.oldRecurrenceRecord", component.get("v.recurrenceRecord"));

        	var savedRecurrence = component.get("v.recurrence");
        	var isSaved = component.get("v.isSaved");
            
            var recurrenceId = component.get("v.recurrenceRecord.Id");
            if(savedRecurrence && savedRecurrence.startDate && !recurrenceId) {
                component.set("v.recurrenceRecord.Start_Date__c", savedRecurrence.startDate);
            }
            
        	if(savedRecurrence && isSaved) {
	    		component.set("v.recurrenceRecord.Recurrence_Pattern__c", savedRecurrence.recurrencePattern);
	    		component.set("v.recurrenceRecord.Recur_every__c", savedRecurrence.recurEvery);
	    		component.set("v.recurrenceRecord.Weekdays__c", savedRecurrence.weekdays);
	    		component.set("v.recurrenceRecord.Start_Date__c", savedRecurrence.startDate);
	    		component.set("v.recurrenceRecord.End_By__c", savedRecurrence.endDate);
	    		component.set("v.recurrenceRecord.End_Type__c", savedRecurrence.endType);
	    		component.set("v.recurrenceRecord.Number_of_Occurrences__c", savedRecurrence.numberOfOccurrences);
                component.set("v.recurrenceRecord.Daily_Option__c", savedRecurrence.dailyOption);
                component.set("v.recurrenceRecord.Monthly_Day_Number__c", savedRecurrence.monthlyDayNumber);
                component.set("v.recurrenceRecord.Yearly_Month__c", savedRecurrence.yearlyMonth);
                component.set("v.recurrenceRecord.Yearly_Day_Number__c", savedRecurrence.yearlyDayNumber);
        	};

        	var weekdays = component.get("v.recurrenceRecord.Weekdays__c");
        	if(weekdays) {
        		component.set("v.weekdays", weekdays.split(';'));
        	};

            var recurEvery = component.get("v.recurrenceRecord.Recur_every__c");
            if(!recurEvery) {
                component.set("v.recurrenceRecord.Recur_every__c", 1);
            }
            
            var dailyOption = component.get("v.recurrenceRecord.Daily_Option__c");
            console.log('dailyOption loaded ' + JSON.stringify(dailyOption));
            if(!dailyOption) {
                component.set("v.recurrenceRecord.Daily_Option__c", "Every Day");
            }
            
            var monthlyDayNumber = component.get("v.recurrenceRecord.Monthly_Day_Number__c");
            if(!monthlyDayNumber) {
                component.set("v.recurrenceRecord.Monthly_Day_Number__c", 1);
            }
            
            var yearlyMonth = component.get("v.recurrenceRecord.Yearly_Month__c");
            if(!yearlyMonth) {
                component.set("v.recurrenceRecord.Yearly_Month__c", "January");
            }
            
            var yearlyDayNumber = component.get("v.recurrenceRecord.Yearly_Day_Number__c");
            if(!yearlyDayNumber) {
                component.set("v.recurrenceRecord.Yearly_Day_Number__c", 1);
            }
            helper.loadDailyOptionList(component);

        } else if (eventParams.changeType === "REMOVED") {
            // record is deleted and removed from the cache
        } else if (eventParams.changeType === "ERROR") {
            console.log('Error: ' + component.get("v.error"));
        }
    },
    handleRecurrencePatternChange: function(component, event, helper) {
    	var recurrencePattern = component.get("v.recurrenceRecord.Recurrence_Pattern__c");
    	switch (recurrencePattern) {
			case 'Daily':
				component.set("v.recurrenceText", " day(s)");
                helper.loadDailyOptionList(component);
				break;
			case 'Weekly':
				component.set("v.recurrenceText", " week(s)");
				break;
			case 'Monthly':
				component.set("v.recurrenceText", " month(s)");
				break;
			case 'Yearly':
				component.set("v.recurrenceText", " year(s)");
				break;
		}
    },
    handleWeekdaysChange: function(component, event, helper) {
    	var weekdaysList = component.get("v.weekdays");
    	var weekdays = weekdaysList.join(';');
    	component.set("v.recurrenceRecord.Weekdays__c", weekdays);
    },
    handleDailyOptionsChange: function(component, event, helper) {
        var dailyOption = event.getSource().get("v.value");
        console.log('dailyOption ' + JSON.stringify(dailyOption));
        component.set("v.recurrenceRecord.Daily_Option__c", dailyOption);
    },
    handleEndDateChange: function(component, event, helper) {
        var recurrenceRecord = component.get('v.recurrenceRecord');
        var startDate = moment(recurrenceRecord.Start_Date__c);
        var endDate = moment(recurrenceRecord.End_By__c);
        if (!(endDate.isSameOrAfter(startDate))) {
            component.set('v.recurrenceRecord.End_By__c', recurrenceRecord.Start_Date__c);
        }
    },
    handleIsDirty: function(component, event, helper) {
    	component.set("v.isDirty", true);
    },
    handleSave: function(component, event, helper) {
    	var isSaved = false;
        var pattern = component.get('v.recurrenceRecord.Recurrence_Pattern__c');
        var weekdays = component.get('v.weekdays');
        if (pattern == 'Weekly' && weekdays.length == 0) {
            // if 'Weekly' is selected but no weekdays are checked, show error
            component.find('notifLib').showToast({
                "variant": "Please choose at least one weekday.",
                "title"  : "No weekdays chosen.",
                "message": "Please choose at least one weekday."
            });
        }
    	if (helper.validateForm(component)) {
            helper.saveRecord(component);
            isSaved = true;
        }
        return isSaved;
    },
    handleCancel: function(component, event, helper) {
    	component.set("v.recurrenceRecord", component.get("v.oldRecurrenceRecord"));

    	var meetingRecurrence = {
    		recurrenceId: component.get("v.recurrenceRecord.Id"),
    		recurrencePattern: component.get("v.recurrenceRecord.Recurrence_Pattern__c"),
    		recurEvery: component.get("v.recurrenceRecord.Recur_every__c"),
    		weekdays: component.get("v.recurrenceRecord.Weekdays__c"),
    		startDate: component.get("v.recurrenceRecord.Start_Date__c"),
    		endDate: component.get("v.recurrenceRecord.End_By__c"),
    		endType: component.get("v.recurrenceRecord.End_Type__c"),
    		numberOfOccurrences: component.get("v.recurrenceRecord.Number_of_Occurrences__c"),
    	};
    	component.set("v.recurrence", meetingRecurrence);
    }
})
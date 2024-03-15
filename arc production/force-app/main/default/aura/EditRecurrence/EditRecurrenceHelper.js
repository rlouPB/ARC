({
	loadRecurrencePatternList: function(component) {
		var recurrencePatternList = [
			{'label': 'Daily', 'value': 'Daily'},
			{'label': 'Weekly', 'value': 'Weekly'},
			{'label': 'Monthly', 'value': 'Monthly'},
			{'label': 'Yearly', 'value': 'Yearly'}
		];
		component.set("v.recurrencePatternList", recurrencePatternList);
	},
    loadDailyOptionList: function(component) {
        var dailyOption = component.get("v.recurrenceRecord.Daily_Option__c");
        var dailyOptionList = [
            {'label': 'Every day', 'value': 'Every Day', 'checked': dailyOption == 'Every Day'? true : false}, 
            {'label': 'Every weekday', 'value': 'Weekdays Only', 'checked': dailyOption == 'Weekdays Only'? true : false}
        ];
        component.set("v.dailyOptionList", dailyOptionList);
    },
	loadEndTypeList: function(component) {
		var endTypeList = [
			{'label': 'End by date:', 'value': 'End By Date'},
			{'label': 'End after #:', 'value': 'End After Occurrences'},
			{'label': 'No end date', 'value': 'No End Date'}
		];
		component.set("v.endTypeList", endTypeList);
	},
    loadMonths: function(component) {
        var months = [
            {label: 'January', id: 'January', selected: true},
            {label: 'February', id: 'February'},
            {label: 'March', id: 'March'},
            {label: 'April', id: 'April'},
            {label: 'May', id: 'May'},
            {label: 'June', id: 'June'},
            {label: 'July', id: 'July'},
            {label: 'August', id: 'August'},
            {label: 'September', id: 'September'},
            {label: 'October', id: 'October'},
            {label: 'November', id: 'November'},
            {label: 'December', id: 'December'}
        ];
        component.set("v.months", months);
    },
    loadWeekdays: function(component) {
        var weekdays = [
            {label: 'Monday', id: 'Monday', selected: true},
            {label: 'Tuesday', id: 'Tuesday'},
            {label: 'Wednesday', id: 'Wednesday'},
            {label: 'Thursday', id: 'Thursday'},
            {label: 'Friday', id: 'Friday'},
            {label: 'Saturday', id: 'Saturday'},
            {label: 'Sunday', id: 'Sunday'}
        ];
        component.set("v.weekdayList", weekdays);
    },
    isValidDayInMonth: function(month, dayInMonth) {
        var isValid = false;
        if(dayInMonth < 1) {
            return false;
        }
    	switch(month) {
            case "January":
                if (dayInMonth <= 31) {
                    isValid = true;
                }
                break;
            case "February":
                if (dayInMonth <= 29) {
                    isValid = true;
                }
                break;
        	case "March":
                if (dayInMonth <= 31) {
                    isValid = true;
                }
                break;
            case "April":
                if (dayInMonth <= 30) {
                    isValid = true;
                }
                break;
            case "May":
                if (dayInMonth <= 31) {
                    isValid = true;
                }
                break;
            case "June":
                if (dayInMonth <= 30) {
                    isValid = true;
                }
                break;
            case "July":
                if (dayInMonth <= 31) {
                    isValid = true;
                }
                break;
            case "August":
                if (dayInMonth <= 31) {
                    isValid = true;
                }
                break;
            case "September":
                if (dayInMonth <= 30) {
                    isValid = true;
                }
                break;
            case "October":
                if (dayInMonth <= 31) {
                    isValid = true;
                }
                break;
            case "November":
                if (dayInMonth <= 30) {
                    isValid = true;
                }
                break;
            case "December":
                if (dayInMonth <= 31) {
                    isValid = true;
                }
                break;
            default:
                break;
        }
        return isValid;
    },
	validateForm: function(component) {
		var validForm = true;

        // Show error messages if required fields are blank
        var allValid = component.find('recurrenceField').reduce(function(validFields, inputComponent) {
            inputComponent.showHelpMessageIfInvalid();
            return validFields && inputComponent.get('v.validity').valid;
        }, true);
        var errorsList = [];
        if (allValid) {
        	var weekdays = component.get("v.recurrenceRecord.Weekdays__c");
            var recurrencePattern = component.get("v.recurrenceRecord.Recurrence_Pattern__c");
            if(!weekdays && recurrencePattern == 'Weekly') {
                errorsList.push('Please select a Weekday.');
                console.log('errorsList in weekdays ' + errorsList);
                validForm = false;
            }
            var recurrencePattern = component.get("v.recurrenceRecord.Recurrence_Pattern__c");
            var monthlyDayNumber = component.get("v.recurrenceRecord.Monthly_Day_Number__c");
            var yearlyMonth = component.get("v.recurrenceRecord.Yearly_Month__c");
            var yearlyDayNumber = component.get("v.recurrenceRecord.Yearly_Day_Number__c");
            if(recurrencePattern == 'Monthly' || recurrencePattern == 'Yearly') {
                if(recurrencePattern == 'Monthly' && (monthlyDayNumber < 1 || monthlyDayNumber > 31)) {
                    errorsList.push('Please enter a valid number between 1 and 31.');
                    console.log('errorsList in Monthly ' + errorsList);
                    validForm = false;
                };
                
                if(recurrencePattern == 'Yearly' && !this.isValidDayInMonth(yearlyMonth, yearlyDayNumber)) {
                    errorsList.push('Please enter a valid number for the month of ' + yearlyMonth);
                    console.log('errorsList in Monthly ' + errorsList);
                    validForm = false;
                }
            }
            if(errorsList && errorsList.constructor === Array && errorsList.length === 0) {
                console.log('setting errors list ' + JSON.stringify(errorsList));
                component.set("v.recordError", errorsList.join("<br />"));
            };
        }
        else {
        	validForm = false;
        }
        if(validForm) {
            component.set("v.recordError", null);
        }

        return (validForm);
	},
	saveRecord: function(component) {
		component.set("v.isSaved", true);
    	var recurrenceRecord = component.get('v.recurrenceRecord');
    	var meetingRecurrence = {
    		recurrenceId: recurrenceRecord.Id,
    		recurrencePattern: recurrenceRecord.Recurrence_Pattern__c,
    		recurEvery: recurrenceRecord.Recur_every__c,
    		weekdays: recurrenceRecord.Weekdays__c,
    		startDate: recurrenceRecord.Start_Date__c,
    		endDate: recurrenceRecord.End_By__c,
            endType: recurrenceRecord.End_Type__c,
            allDayMeeting: true,
    		numberOfOccurrences: recurrenceRecord.Number_of_Occurrences__c,
            dailyOption: recurrenceRecord.Daily_Option__c,
            monthlyDayNumber: recurrenceRecord.Monthly_Day_Number__c,
            yearlyMonth: recurrenceRecord.Yearly_Month__c,
            yearlyDayNumber: recurrenceRecord.Yearly_Day_Number__c,
            isDirty: component.get("V.isDirty")
    	};
    	component.set("v.recurrence", meetingRecurrence);
	}
})
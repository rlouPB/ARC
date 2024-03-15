/* eslint-disable vars-on-top */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-expressions */
({
    getAccount: function(component) {
        var action = component.get("c.getAccount");
        action.setParams({
            accountId: component.get("v.recordId")
        });
        // Add callback behavior for when response is received
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set(
                    "v.currentAdmissionStage",
                    response.getReturnValue().Current_Admission_Stage__c
                );
                component.set("v.account", response.getReturnValue());
            } else {
                console.log("Failed with state: " + state);
            }
        });
        // Send action off to be executed
        $A.enqueueAction(action);
    },
    toggleSpinner: function(component, duration) {
        component.set("v.enableButtons", !component.get("v.enableButtons"));
        window.setTimeout(
            $A.getCallback(function() {
                if (component.find("spinner")) {
                    var spinnerCls = component.find("spinner").get("v.class");
                    if (spinnerCls) {
                        if (spinnerCls === "slds-show") {
                            component.find("spinner").set("v.class", "slds-hide");
                        } else {
                            component.find("spinner").set("v.class", "slds-show");
                        }
                    } else {
                        component.find("spinner").set("v.class", "slds-hide");
                    }
                    //console.log('toggle spinner to ' + component.find("spinner").get("v.class"));
                }
            }),
            duration
        );
    },
    setContactOptions: function(component, recordId) {
        //let newActivity = component.get("v.newActivity");

        //newActivity.Patient_Name__c = recordId;
        //component.set("v.newActivity", newActivity);

        var personalContactAdditionalOptions = [
            // {
            //     'label': 'Advanced Search',
            //     'value': 'advanceSearch',
            //     'isRecord': false,
            //     'componentName': 'c:AdvancedSearchView',
            //     'attr':{'recordId': recordId, 'context':'contact'}
            // },
            {
                label: "Create New Contact",
                value: "newContact",
                isRecord: false,
                componentName: "c:NewBasicContact",
                attr: { recordId: recordId, contactRecordTypeName: "Personal" }
            }
        ];
        var professionalContactAdditionalOptions = [
            // {
            //     'label': 'Advanced Search',
            //     'value': 'advanceSearch',
            //     'isRecord': false,
            //     'componentName': 'c:AdvancedSearchView',
            //     'attr':{'recordId': recordId, 'context':'contact'}
            // },
            {
                label: "Create New Contact",
                value: "newContact",
                isRecord: false,
                componentName: "c:NewBasicContact",
                attr: { recordId: recordId, contactRecordTypeName: "Professional" }
            }
        ];
        /*
                                                                                    {
                                                                                        'label': 'Advanced Search', 'value': 'advanceSearch', 'isRecord': false, 'componentName': 'c:AdvancedSearchView', 'attr':{'recordId': recordId, 'context':'contact'}
                                                                                    },
                                                                                    {
                                                                                        'label': 'Create New Contact', 'value': 'newContact', 'isRecord': false, 'componentName': 'c:NewContactView','attr':{'recordId': recordId}
                                                                                    }
                                                                                */
        component.set(
            "v.personalContactAdditionalOptions",
            personalContactAdditionalOptions
        );
        component.set(
            "v.professionalContactAdditionalOptions",
            professionalContactAdditionalOptions
        );

        //console.log('set options ' + contactAdditionalOptions);
        var personalContactFilter = [{
            fieldName: "RecordType.Name",
            condition: "=",
            value: "Personal"
        }];
        component.set("v.personalContactFilter", personalContactFilter);
        var professionalContactFilter = [{
            fieldName: "RecordType.Name",
            condition: "=",
            value: "Professional"
        }];
        component.set("v.professionalContactFilter", professionalContactFilter);
    },

    getRelatedContact: function(component) {
        var relatedContactRecordId = component.get("v.relatedContactRecordId");

        if (relatedContactRecordId) {
            console.log("called getRelatedContact");
            var action = component.get("c.getRelatedContact");
            action.setParams({
                relatedContactRecordId: relatedContactRecordId
            });
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log("response " + JSON.stringify(response.getReturnValue()));
                    component.set("v.relatedContact", response.getReturnValue());

                    var relatedContact = component.get("v.relatedContact");

                    var selectedRecordType = component.get("v.selectedRecordType");
                    selectedRecordType.label = relatedContact.RecordType.Name;
                    selectedRecordType.value = relatedContact.RecordType.Id;
                    selectedRecordType.relatedValue = relatedContact.RecordType.Id;

                    console.log(
                        "selectedRecordType " + JSON.stringify(selectedRecordType)
                    );

                    component.set("v.selectedRecordType", selectedRecordType);
                } else {
                    console.log("Failed with state: " + state);
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }
    },

    validateIsRequired: function(component, fields, obj) {
        let self = this;
        let errorMessages = component.get("v.errorMessages");
        // debugger;
        let isContactLookupValid = true;
        var relatedContactRecordId = component.get("v.relatedContactRecordId");

        if (!component.get("v.selectedCallerRecord").isRecord &&
            !relatedContactRecordId
        ) {
            let errorMap = component.get("v.lookupError");
            errorMap.message =
                "Either choose an existing contact or create a new one.";
            errorMap.show = true;
            component.set("v.lookupError", errorMap);
            isContactLookupValid = false;
            //errorMap.set('message', 'Either choose an existing contact or create a new one.');
            // return false;
        }

        console.log("isContactLookupValid " + isContactLookupValid);
        let isValidDates = true;

        if (obj.Start_Date__c || obj.End_Date__c) {
            isValidDates =
                self.isValidDate(component, "Start Date", obj.Start_Date__c) &&
                isValidDates;
            isValidDates =
                self.isValidDate(component, "End Date", obj.End_Date__c) &&
                isValidDates;
        }

        console.log("isValidDates " + isValidDates);

        let errorMessage = "";
        let isRequiredFieldsValid = Object.keys(fields).reduce(function(
                validSoFar,
                field
            ) {
                console.log("object " + JSON.stringify(obj));
                console.log("field is: " + field);
                if (fields[field].required) {
                    if (!obj[field]) {
                        console.log("field missing value");
                        if (errorMessage === "") {
                            errorMessage = fields[field].label;
                        } else {
                            errorMessage = errorMessage + ", " + fields[field].label;
                        }
                        //component.set('v.errorMessage',errorMessage)
                    }
                    return validSoFar && obj[field];
                } else {
                    return validSoFar;
                }
            },
            true);

        console.log("isRequiredFieldsValid " + isRequiredFieldsValid);

        if (errorMessage != "") {
            errorMessages.push({
                type: "error",
                title: "Required fields missing: " + errorMessage
            });
        }
        return isRequiredFieldsValid && isContactLookupValid && isValidDates;
    },
    addRequiredField: function(component, fieldName, fieldLabel) {
        let reqFieldsObject = component.get("v.requiredFields");
        reqFieldsObject[fieldName] = { label: fieldLabel, required: true };
        component.set("v.requiredFields", reqFieldsObject);
    },
    removeRequiredField: function(component, fieldName, fieldLabel) {
        let reqFieldsObject = component.get("v.requiredFields");
        reqFieldsObject[fieldName] = { label: fieldLabel, required: false };
        component.set("v.requiredFields", reqFieldsObject);
    },
    showErrorMessage: function(component) {
        let messageText = "";
        let errorMessages = component.get("v.errorMessages");
        errorMessages.forEach(function(message) {
            messageText += "\n" + message.title;
        });
        // if (messageText != '')
        // {
        //     messageText = 'Required fields missing: ' + messageText;
        // }
        this.showCustomToast(component, {
            type: "error",
            title: "Please review the errors in the page.",
            message: messageText
        });
    },
    setValueBasedOnFieldType: function(obj, apiName, event) {
        if (
            apiName === "Contact" &&
            event.getSource().get("v.fieldName") === "Name"
        ) {
            obj["FirstName"] = event.getParams().firstName;
            obj["LastName"] = event.getParams().lastName;
            obj["salutation"] = event.getParams().salutation;
        }

        if (event.getParams().hasOwnProperty("checked")) {
            obj[event.getSource().get("v.fieldName")] = event.getParam("checked");
        } else {
            obj[event.getSource().get("v.fieldName")] = event.getParam("value");
        }

        return obj;
    },
    saveContactform: function(component, contact, relatedContact, helper) {
        var self = this;
        relatedContact.Account__c = component.get("v.recordId");

        helper.callApexMethod(
            component,
            "saveRelatedContact", { relatedContact: relatedContact },
            function(result) {
                self.handleSaveSuccess(component, result);
            },
            function(error) {
                self.toggleSpinner(component, 0);
                helper.showCustomToast(component, {
                    type: "error",
                    title: "Error while saving a record",
                    message: error
                });
            }
        );
    },
    // Validates that the input string is a valid date formatted as "mm/dd/yyyy"
    isValidDate: function(component, fieldLabel, dateString) {
        if (!dateString || dateString == "") return true;
        // First check for the pattern
        //check that date was properly interpreted by ui:inputDate (should show as yyyy-mm-dd if ui:inputdate knew what you were entering)
        if (!/^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$/.test(dateString)) {
            let errorMsgs = component.get("v.errorMessages");
            let errorStr = fieldLabel + " not in proper format (MM/DD/YYYY). ";
            errorMsgs.push({ type: "error", title: errorStr });
            component.set("v.errorMessages", errorMsgs);
            return false;
        }

        // Parse the date parts to integers
        var parts = dateString.split("-");
        var day = parseInt(parts[2], 10);
        var month = parseInt(parts[1], 10);
        var year = parseInt(parts[0], 10);

        var monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

        // Adjust for leap years
        if (year % 400 == 0 || (year % 100 != 0 && year % 4 == 0))
            monthLength[1] = 29;

        // Check the range
        let inRange =
            year > 1000 &&
            year < 3000 &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= monthLength[month - 1];
        if (!inRange) {
            let errorStr = fieldLabel + " out of range. ";
            component.get("v.errorMessages").push({ type: "error", title: errorStr });
        }
        return inRange;
    },
    handleSaveSuccess: function(component, result) {
        //$A.get('e.force:refreshView').fire();
        component.set("v.showModal", false);

        // Added by DES 2022-06-15, ARC-2067
        // Before creating data object, convert result back into JSON
        var parsedResult = JSON.parse(result);

        this.toggleSpinner(component, 0);

        var data = {
            label: parsedResult.Name,
            value: parsedResult.Id
        };

        let evt = component.getEvent("closeModalView");
        evt.setParams({
            data: data
        });
        evt.fire();

        var refreshEvent = $A.get("e.c:refreshRelatedList");
        //refreshEvent.data = 'Related_Contacts__r';
        refreshEvent.setParams({
            data: "Related_Contacts__r"
        });
        refreshEvent.fire();
    },
    handleOnLoad: function(component, event, helper) {
        //$A.get('e.force:refreshView').fire();

        var relatedContact = component.get("v.relatedContact");
        console.log("relatedContact " + JSON.stringify(relatedContact));
        var relatedContactFields = component.find("relatedContactField");
        if (!relatedContactFields) return;

        if ($A.util.isArray(relatedContactFields)) {
            var relatedContact = component.get("v.relatedContact");
            relatedContactFields.forEach((relatedContactField) => {
                var fieldName = relatedContactField.get("v.fieldName");
                relatedContact[fieldName] = relatedContactField.get("v.value");
            });
        }

        var contactLookup = component.find("contactLookup");
        if (contactLookup) {
            contactLookup.runSearch();
        }
    }
});
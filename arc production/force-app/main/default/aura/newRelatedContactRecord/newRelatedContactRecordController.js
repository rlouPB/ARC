/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
    doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log("doInit recordId " + recordId);
        helper.getAccount(component);
        helper.setContactOptions(component);
        var requiredFieldObject = {
            Role__c: { label: "Role", required: true },
            Contact__c: { label: "Contact Name", required: true }
        };
        component.set("v.requiredFields", requiredFieldObject);

        helper.callApexMethod(
            component,
            "getContactRecordTypeDetails",
            null,
            function(result) {
                let contactRecordTypes = (collection) => {
                    return collection
                        .filter((record) => record.Name != "Patient")
                        .map((record) => {
                            let recordMap = { label: record.Name, value: record.Id };
                            console.log("recordMap ist: " + recordMap);
                            return recordMap;
                        });
                };

                const contactRecordTypeList = contactRecordTypes(
                    result.contactRecordTypes
                );
                const relatedContactRecordTypeList = contactRecordTypes(
                    result.relatedContactRecordTypes
                );

                component.set("v.contactRecordTypeList", contactRecordTypeList);
                component.set(
                    "v.relatedContactRecordTypeList",
                    relatedContactRecordTypeList
                );
                helper.handleOnLoad(component, event, helper);
                helper.toggleSpinner(component, 0);
            },
            function(error) {
                helper.showCustomToast({ type: "error", title: error });
                helper.toggleSpinner(component, 0);
            }
        );
        helper.getRelatedContact(component);
    },
    cancel: function(component, event, helper) {
        var evt = component.getEvent("closeModalView");
        evt.fire();
    },
    closeModal: function(component, event, helper) {
        component.set("v.showModal", false);

        var evt = component.getEvent("closeModalView");
        evt.fire();
    },
    //closeModal event handler for close the modal.
    handleCloseModal: function(component, event, helper) {
        var data = event.getParam("data");
        //component.find();
        //component.find("optionComponent").set("v.body", []);

        // if(data) {
        //component.set("v.selectedRecord" , data);
        // component.set("v.lookupFieldName", data.value);
        // console.log('lookupFieldName###', data.value);
        // var forclose = component.find("lookup-pill");
        // $A.util.addClass(forclose, 'slds-show');
        // $A.util.removeClass(forclose, 'slds-hide');

        // var forclose = component.find("searchRes");
        // $A.util.addClass(forclose, 'slds-is-close');
        // $A.util.removeClass(forclose, 'slds-is-open');

        // var lookUpTarget = component.find("lookupField");
        // $A.util.addClass(lookUpTarget, 'slds-hide');
        // $A.util.removeClass(lookUpTarget, 'slds-show');

        // var searchIcon = component.find("searchIcon");
        // $A.util.addClass(searchIcon, 'slds-hide');
        // $A.util.removeClass(searchIcon, 'slds-show');
        // }
        //event.stopPropagation();
    },
    handleError: function(component, event, helper) {
        var params = event.getParams();
        helper.toggleSpinner(component, 0);
    },
    handleOnError: function(component, event, helper) {
        //RecordEditform error
        var params = event.getParams();
        helper.toggleSpinner(component, 0);
        console.log(params);
    },
    handleOnLoad: function(component, event, helper) {
        helper.handleOnLoad(component, event, helper);
    },
    handleShowModalChanged: function(component, event, helper) {
        var oldValue = event.getParam("oldValue");
        var value = event.getParam("value");

        if (!oldValue && value == true) {
            var relatedContact = component.get("v.relatedContact");
            var relatedContactFields = component.find("relatedContactField");

            if (!relatedContactFields) return;

            if ($A.util.isArray(relatedContactFields)) {
                var relatedContact = component.get("v.relatedContact");
                relatedContactFields.forEach((relatedContactField) => {
                    var fieldName = relatedContactField.get("v.fieldName");
                    relatedContact[fieldName] = relatedContactField.get("v.value");
                });
            }
        }
    },
    handleSuccess: function(component, event, helper) {
        var evt = component.getEvent("closeModalView");
        evt.fire();
        var refreshEvent = $A.get("e.c:refreshRelatedList");

        //refreshEvent.data = 'Related_Contacts__r';
        refreshEvent.setParams({
            data: "Related_Contacts__r"
        });
        refreshEvent.fire();
    },
    load: function(component, event, helper) {
        helper.toggleSpinner(component, 0);
    },
    onFieldChange: function(component, event, helper) {
        let contact = component.get("v.contact"),
            selectedRecordType = component.get("v.selectedRecordType"),
            objectApiName = "";

        if (selectedRecordType.label === "Professional") {
            objectApiName = component
                .find("newProfessionalContactForm")
                .get("v.objectApiName");
        } else {
            objectApiName = component.find("newContactForm").get("v.objectApiName");
        }

        if (objectApiName === "Contact") {
            component.set(
                "v.contact",
                helper.setValueBasedOnFieldType(contact, objectApiName, event)
            );
        }
    },
    onFieldChangeRelated: function(component, event, helper) {
        var relatedContactRecordId = component.get("v.relatedContactRecordId");

        if (!relatedContactRecordId) {
            console.log("relatedContactRecordId is null");
            let relatedContact = component.get("v.relatedContact"),
                selectedRecordType = component.get("v.selectedRecordType"),
                relatedObjectApiName = "";

            if (selectedRecordType.label === "Professional") {
                relatedObjectApiName = component
                    .find("relatedContactFormProfessional")
                    .get("v.objectApiName");
            } else {
                relatedObjectApiName = component
                    .find("relatedContactFormPersonal")
                    .get("v.objectApiName");
            }

            if (relatedObjectApiName === "Related_Contact__c") {
                component.set(
                    "v.relatedContact",
                    helper.setValueBasedOnFieldType(
                        relatedContact,
                        relatedObjectApiName,
                        event
                    )
                );
            }
        } else {
            var relatedContact = component.get("v.relatedContact");
            var relatedObjectApiName = "Related_Contact__c";
            if (relatedObjectApiName === "Related_Contact__c") {
                component.set(
                    "v.relatedContact",
                    helper.setValueBasedOnFieldType(
                        relatedContact,
                        relatedObjectApiName,
                        event
                    )
                );
            }
        }
    },
    onrecordTypeChange: function(component, event, helper) {
        helper.toggleSpinner(component, 0);
        //reInitialize when Recordtype change
        component.set("v.contact", { sobjectType: "Contact" });
        component.set("v.relatedContact", { sobjectType: "Related_Contact__c" });

        const contactRecordTypeList = component.get("v.contactRecordTypeList"),
            relatedContactRecordTypeList = component.get(
                "v.relatedContactRecordTypeList"
            );

        const contactRecordTypeRecord = contactRecordTypeList.find(
            (record) => record.value === event.getParam("value")
        );
        const relatedContactRecordTypeRecord = relatedContactRecordTypeList.find(
            (record) => record.label === contactRecordTypeRecord.label
        );

        let selectedRecordType = component.get("v.selectedRecordType");
        selectedRecordType.label = contactRecordTypeRecord.label;
        selectedRecordType.value = contactRecordTypeRecord.value;
        selectedRecordType.relatedValue = relatedContactRecordTypeRecord.value;

        component.set("v.selectedRecordType", selectedRecordType);
        helper.toggleSpinner(component, 0);
    },
    save: function(component, event, helper) {
        helper.toggleSpinner(component, 0);

        let selectedRecordType = component.get("v.selectedRecordType"),
            contact = component.get("v.contact"),
            relatedContact = component.get("v.relatedContact"),
            accountId = component.get("v.recordId");

        //empty error message every time save clicked
        component.set("v.errorMessages", []);
        var relatedContactRecordId = component.get("v.relatedContactRecordId");

        if (!relatedContactRecordId) {
            contact.RecordTypeId = selectedRecordType.value;
            relatedContact.RecordTypeId = selectedRecordType.relatedValue;
        } else {
            relatedContact.Id = relatedContactRecordId;
            console.log("has relatedContact.Id");
            var relatedContactForm;
            if (selectedRecordType.label == "Personal") {
                relatedContactForm = component.find("relatedContactFormPersonal");
            }
            if (selectedRecordType.label == "Professional") {
                relatedContactForm = component.find("relatedContactFormProfessional");
            }
            if (selectedRecordType.label == "Patient") {
                relatedContactForm = component.find("relatedContactFormPatient");
            }

            if (relatedContactForm) {
                console.log("relatedContactForm");
                relatedContactForm.submit();
                helper.saveContactform(component, contact, relatedContact, helper);
                // component.set('v.showModal',false);
            }
            helper.toggleSpinner(component, 0);
            return;
        }

        relatedContact.Account__c = accountId;
        console.log(JSON.stringify(contact));
        if (selectedRecordType.label === "Professional") {
            //both fields error message show
            const isRelatedContactFieldsValid = helper.validateIsRequired(
                component,
                component.get("v.requiredFields"),
                relatedContact
            );

            if (isRelatedContactFieldsValid) {
                helper.hideCustomToast(component);
                helper.saveContactform(component, contact, relatedContact, helper);
                //component.find('newProfessionalContactForm').submit(contact)
            } else {
                helper.toggleSpinner(component, 0);
                helper.showErrorMessage(component);
            }
        } else {
            //both fields error message show
            const isContactFieldsValid = true; //helper.validateIsRequired(component,{'LastName':'Last Name'},contact),
            const isRelatedContactFieldsValid = helper.validateIsRequired(
                component,
                component.get("v.requiredFields"),
                relatedContact
            );

            if (isContactFieldsValid && isRelatedContactFieldsValid) {
                // helper.toggleSpinner(component, 0);
                helper.saveContactform(component, contact, relatedContact, helper);
                //component.find("newContactForm").submit(contact);
            } else {
                helper.toggleSpinner(component, 0);
                helper.showErrorMessage(component);
            }
        }
    }
});
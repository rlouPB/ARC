({
  validateForm: function (component) {
    var validForm = true;

    // Show error messages if required fields are blank
    var allValid = component.find("meetingField").reduce(function (validFields, inputComponent) {
      inputComponent.showHelpMessageIfInvalid();
      return validFields && inputComponent.get("v.validity").valid;
    }, true);
    if (allValid) {
    } else {
      validForm = false;
    }

    return validForm;
  },
  saveRecord: function (component) {
    var isDirty = component.get("v.isDirty");
    // console.log('isDirty on save ' + isDirty);
    if (isDirty) {
      var participantsList = [];

      var selectedRecordList = component.get("v.selectedRecordList");
      // console.log('saveRecord selectedRecordList ' + JSON.stringify(selectedRecordList));
      if (Array.isArray(selectedRecordList) && selectedRecordList.length) {
        var userList = [];
        var contactList = [];
        var groupList = [];
        selectedRecordList.forEach((element) => {
          if (element.type == "User" && element.value != null) {
            userList.push(element.value);
          } else if (element.type == "Contact" && element.value != null) {
            contactList.push(element.value);
          } else if (element.type == "Group" && element.value != null) {
            groupList.push(element.value);
          }
        });

        if (userList.length) {
          participantsList.push({
            objectType: "User",
            idSet: userList
          });
        }

        if (contactList.length) {
          participantsList.push({
            objectType: "Contact",
            idSet: contactList
          });
        }

        if (groupList.length) {
          participantsList.push({
            objectType: "Group__c",
            idSet: groupList
          });
        }

        // console.log('participantsList in selectedRecordList ' + JSON.stringify(participantsList));
      }

      var isRecurrenceSaved = component.get("v.isRecurrenceSaved");
      var isRecurrenceDirty = component.get("v.isRecurrenceDirty");
      var recurrence = component.get("v.recurrence");
      var meetingRecurrence = null;
      if (isRecurrenceSaved && isRecurrenceDirty) {
        component.set("v.isMeetingUpdateOnly", false);
        component.set("v.recurrenceSelected", "series");
        var newMeetingRecurrence = {
          recurrenceId: component.get("v.recurrence.recurrenceId"),
          ownerId: component.get("v.meetingRecord.Owner.Id"),
          recurrencePattern: component.get("v.recurrence.recurrencePattern"),
          recurEvery: component.get("v.recurrence.recurEvery"),
          weekdays: component.get("v.recurrence.weekdays"),
          startDate: component.get("v.recurrence.startDate"),
          endDate: component.get("v.recurrence.endDate"),
          endType: component.get("v.recurrence.endType"),
          numberOfOccurrences: component.get("v.recurrence.numberOfOccurrences"),
          dailyOption: component.get("v.recurrence.dailyOption"),
          monthlyDayNumber: component.get("v.recurrence.monthlyDayNumber"),
          yearlyMonth: component.get("v.recurrence.yearlyMonth"),
          yearlyDayNumber: component.get("v.recurrence.yearlyDayNumber")
        };
        meetingRecurrence = newMeetingRecurrence;
      }

      // console.log('meetingRecord ' + JSON.stringify(component.get("v.meetingRecord")));
      var mtg = component.get("v.meetingRecord");
      delete mtg.Owner; //avoid issues in apex
      delete mtg.Participants__r;
      var recurrenceRecord = component.get("v.recurrenceRecord");
      //var attendance = component.get('v.meetingRecord.Patient_Attendance__c');

      if (mtg.Meeting_Focus__c == "Patient") {
        mtg.Patient_Group_Meeting_Type__c = null;
        mtg.Staff_Group_Meeting_Type__c = null;
        mtg.Other_Meeting_Type__c = null;
      } else if (mtg.Meeting_Focus__c == "Patient Group") {
        mtg.Patient_Meeting_Type__c = null;
        mtg.Staff_Group_Meeting_Type__c = null;
        mtg.Other_Meeting_Type__c = null;
      } else if (mtg.Meeting_Focus__c == "Staff Group") {
        mtg.Patient_Meeting_Type__c = null;
        mtg.Patient_Group_Meeting_Type__c = null;
        mtg.Other_Meeting_Type__c = null;
      } else if (mtg.Meeting_Focus__c == "Other") {
        mtg.Patient_Meeting_Type__c = null;
        mtg.Patient_Group_Meeting_Type__c = null;
        mtg.Staff_Group_Meeting_Type__c = null;
      }

      var meeting = {
        meetingId: component.get("v.recordId"),
        mtg: mtg,
        recurrenceRecord: recurrenceRecord,
        // startDateTime: component.get("v.meetingRecord.Start_Date_Time__c"),
        // endDateTime: component.get("v.meetingRecord.End_Date_Time__c"),
        // subject: component.get("v.meetingRecord.Subject__c"),
        staffOwnerId: mtg.OwnerId,
        schedulingResourceId: mtg.Room_Resource__c,
        // description: component.get("v.meetingRecord.Description__c"),
        participantsList: participantsList,
        recurrence: meetingRecurrence,
        recurrenceSelected: component.get("v.recurrenceSelected"),
        isMeetingUpdateOnly: component.get("v.isMeetingUpdateOnly"),
        recurrenceId: mtg.Recurrence__c,
        roomResource: component.get("v.selectedResource.value")
      };
      console.log("Meeting room resource: ", meeting.roomResource);

      // console.log('meetingRequest ' + JSON.stringify(meeting));
      var action = component.get("c.saveMeeting");
      action.setParams({
        meeting: JSON.stringify(meeting)
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var responseValue = response.getReturnValue();
          var resultToast = $A.get("e.force:showToast");

          resultToast.setParams({
            type: responseValue.responseType,
            title: responseValue.title,
            message: responseValue.message
          });
          resultToast.fire();

          if (meeting.recurrenceSelected) {
            console.log("meetingS saved");
          }

          if (responseValue.responseType == "success") {
            this.closeModal(component, "save");
          }
        } else if (state === "INCOMPLETE") {
          // do something
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              console.log("Error message: " + errors[0].message);
            }
          } else {
            console.log("Unknown error");
          }
        }
      });
      $A.enqueueAction(action);
    } else {
      this.closeModal(component, "save");
    }
  },
  deleteMeeting: function (component) {
    var action = component.get("c.deleteMeeting");
    var meetingId = component.get("v.recordId");
    var recurrenceType = component.get("v.recurrenceSelected");
    var myParams = {
      meetingId: meetingId,
      recurrenceType: recurrenceType
    };
    action.setParams(myParams);
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var responseValue = response.getReturnValue();
        var resultToast = $A.get("e.force:showToast");
        var toastParams = {
          type: responseValue.responseType,
          title: responseValue.title,
          message: responseValue.message
        };
        resultToast.setParams(toastParams);
        resultToast.fire();
        console.log(JSON.stringify(toastParams));
        if (responseValue.responseType == "success") {
          this.closeModal(component, "delete");
        }
        component.set("v.showDeleteModal", false);
      } else if (state === "INCOMPLETE") {
        // do something
      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("Error message: " + errors[0].message);
          }
        } else {
          console.log("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  },
  loadMeeting: function (component, event, helper) {
    //component.find("recordEditor").reloadRecord(true);

    var action = component.get("c.loadMeeting_Ctl");
    action.setParams({
      recordId: component.get("v.recordId"),
      patientId: component.get("v.patientId")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var responseValue = response.getReturnValue();
        var selectedRecordList = [];

        console.log("responseValue: ", responseValue);

        var meetingRecord = responseValue.mtg;
        console.log("meetingRecord: ", meetingRecord);
        component.set("v.durationInMinutes", helper.calculateDuration(meetingRecord));
        component.set("v.canEditMeeting", responseValue.canEdit);

        var meetingLoadedEvent = component.getEvent("calendarMeetingLoadedEvent");

        meetingLoadedEvent.setParams({
          canEditMeeting: responseValue.canEdit
        });
        meetingLoadedEvent.fire();

        component.set("v.meetingRecord", meetingRecord);
        component.set("v.meetingTypeMap", responseValue.meetingTypeMap);
        console.log("MNF: ", meetingRecord.Monthly_Note_Finalized__c, " | ", meetingRecord.Monthly_Note_Finalized__c == true);
        if (meetingRecord.Monthly_Note_Finalized__c == true) {
          component.set("v.readOnly", true);
        }
        var selectedResource = {};
        if (meetingRecord.Room_Resource__c) {
          selectedResource = {
            label: meetingRecord.Room_Resource__r.Name,
            value: meetingRecord.Room_Resource__c,
            isRecord: true
          };
        }
        component.set("v.selectedResource", selectedResource);

        console.log("EditMeetingHelper meetingRecord.All_Day_Meeting__c: ", meetingRecord.All_Day_Meeting__c);
        if (meetingRecord.All_Day_Meeting__c == true) {
          console.log("inside");
          component.set("v.showAllDay", true);
        }

        responseValue.participantGroupList.forEach((element) => {
          if (element.groupType == "User") {
            element.participants.forEach((participant) => {
              selectedRecordList.push({
                type: "User",
                label: participant.label,
                value: participant.name,
                isRecord: true
              });
            });
          }

          if (element.groupType == "Contact") {
            element.participants.forEach((participant) => {
              selectedRecordList.push({
                type: "Contact",
                label: participant.label,
                value: participant.name,
                isRecord: true
              });
            });
          }

          if (element.groupType == "Group") {
            element.participants.forEach((participant) => {
              selectedRecordList.push({
                type: "Group",
                label: participant.label,
                value: participant.name,
                isRecord: true
              });
            });
          }
        });
        // selectedRecordList.push({
        //     type: 'User'
        // });
        var selectedOwner = responseValue.selectedOwner;
        selectedOwner.isRecord = true;
        component.set("v.selectedOwner", selectedOwner);

        var selectedPatient = responseValue.selectedPatient;
        if (selectedPatient.value) {
          selectedPatient.isRecord = true;
          component.set("v.selectedPatient", selectedPatient);
        }

        component.set("v.selectedRecordList", selectedRecordList);

        helper.populateSelectedRecordList(component, meetingRecord.Id != null);

        var recurrenceRecord = responseValue.recurrenceRecord;

        if (!recurrenceRecord) {
          recurrenceRecord = {};
        }
        if (!recurrenceRecord.Monthly_Day_Type__c) {
          recurrenceRecord.Monthly_Day_Type__c = "Day Number";
          recurrenceRecord.Month_Number__c = 1;
          recurrenceRecord.Number_of_Occurrences__c = 10;
        }
        component.set("v.recurrenceRecord", recurrenceRecord);
        helper.updateRecurrenceStartdate(component);
        //move cursor focus to Subject once Meeting is loaded
        var meetingFields = component.find("meetingField");
        if (meetingFields) {
          meetingFields[0].focus();
        }
        component.set("v.isLoaded", true);
      } else if (state === "INCOMPLETE") {
        // do something
      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("Error message: " + errors[0].message);
          }
        } else {
          console.log("Unknown error");
        }
      }
      helper.hideSpinner(component);
    });
    $A.enqueueAction(action);
  },
  calculateDuration: function (meeting) {
    var startDT = moment(meeting.Start_Date_Time__c);
    var endDT = moment(meeting.End_Date_Time__c);
    return endDT.diff(startDT, "minutes");
  },
  updateRecurrenceStartdate: function (component, event, helper) {
    var recurrenceRecord = component.get("v.recurrenceRecord");
    var meetingRecord = component.get("v.meetingRecord");
    var showAllDay = component.get("v.showAllDay");
    if (showAllDay == false) {
      if (meetingRecord && meetingRecord.Start_Date_Time__c && recurrenceRecord && !recurrenceRecord.Id) {
        recurrenceRecord.Start_Date__c = moment(meetingRecord.Start_Date_Time__c).format("YYYY-MM-DD");
      }
    } else {
      if (meetingRecord && meetingRecord.All_Day_Date__c && recurrenceRecord && !recurrenceRecord.Id) {
        recurrenceRecord.Start_Date__c = moment(meetingRecord.All_Day_Date__c).format("YYYY-MM-DD");
      }
    }
    var startDate = moment(recurrenceRecord.Start_Date__c);
    var endDate = moment(recurrenceRecord.End_By__c);
    if (!endDate.isSameOrAfter(startDate)) {
      component.set("v.recurrenceRecord.End_By__c", recurrenceRecord.Start_Date__c);
    }
  },
  updateShowRecurrenceButton: function (component, event, helper) {
    var startDateTime = component.get("v.meetingRecord.Start_Date_Time__c");
    var allDayDate = component.get("v.meetingRecord.All_Day_Date__c");
    var isAllDay = component.get("v.showAllDay");
    var enableRecurrenceButton = isAllDay ? allDayDate != null : startDateTime != null;
    component.set("v.enableRecurrenceButton", enableRecurrenceButton);
    //debugger;
  },
  populateSelectedRecordList: function (component, isExistingMeeting) {
    var selectedRecordList = component.get("v.selectedRecordList");
    console.log("EditMeetingController handleRecordUpdated " + JSON.stringify(selectedRecordList));
    if (Array.isArray(selectedRecordList)) {
      console.log("in selectedRecordList");
      if (!isExistingMeeting) {
        var patientContact = component.get("v.patientContact");
        if (patientContact && patientContact.Id && patientContact.Name) {
          var patientContactFound = selectedRecordList.some((element) => element.value === patientContact.Id);
          if (!patientContactFound) {
            selectedRecordList.push({
              type: "Contact",
              label: patientContact.Name,
              value: patientContact.Id,
              isRecord: true
            });
          }
        }

        var ownerFound = selectedRecordList.some((element) => element.value === component.get("v.meetingRecord.Owner.Id"));
        if (!ownerFound) {
          selectedRecordList.push({
            type: "User",
            label: component.get("v.selectedOwner.label"),
            value: component.get("v.selectedOwner.value"),
            isRecord: true
          });
        }
      }
      var hasEmptyLookup = selectedRecordList.some((element) => element.value === undefined || element.value === null);
      if (!hasEmptyLookup) {
        selectedRecordList.push({
          type: "User"
        });
      }
      component.set("v.selectedRecordList", selectedRecordList);
    }
  },
  closeModal: function (component, type) {
    var closeEvent = component.getEvent("closeModalEvent");

    var data = {
      instanceName: component.get("v.instanceName"),
      type: type
    };
    closeEvent.setParams({
      data: data
    });
    closeEvent.fire();
  },
  setFilters: function (component) {
    var staffLookupFilter = [
      {
        fieldName: "IsActive",
        condition: "=",
        value: true
      }
    ];
    component.set("v.staffLookupFilter", staffLookupFilter);

    var contactLookupFilter = [
      {
        fieldName: "Available_For_Schedule__c",
        condition: "=",
        value: true
      }
    ];
    component.set("v.contactLookupFilter", contactLookupFilter);

    var staffGroupLookupFilter = [
      {
        fieldName: "Active__c",
        condition: "=",
        value: true
      },
      {
        fieldName: "Primary_Function__c",
        condition: "=",
        value: "staff"
      }
    ];
    component.set("v.staffGroupLookupFilter", staffGroupLookupFilter);
    var patientGroupLookupFilter = [
      {
        fieldName: "Active__c",
        condition: "=",
        value: true
      },
      {
        fieldName: "Primary_Function__c",
        condition: "=",
        value: "patient"
      }
    ];
    component.set("v.patientGroupLookupFilter", patientGroupLookupFilter);

    var resourceLookupFilter = [
      {
        fieldName: "Active__c",
        condition: "=",
        value: true
      }
    ];
    component.set("v.resourceLookupFilter", resourceLookupFilter);

    var patientLookupFilter = [
      {
        fieldName: "RecordType.Name",
        condition: "=",
        value: "Patient"
      },
      {
        fieldName: "Current_Lookup_Admission_Stage__c",
        condition: "IN",
        value: "('Admitted','Chart Not Closed')"
      }
    ];

    console.log("patientLookupFilter: " + JSON.stringify(patientLookupFilter));
    component.set("v.patientLookupFilter", patientLookupFilter);
  },
  getAvailableResources: function (component) {
    var action = component.get("c.getAvailableSchedulingResourcesForMeetingTimes");
    var newMeetingStartDateTime = component.get("v.meetingRecord.Start_Date_Time__c");
    var newMeetingEndDateTime = component.get("v.meetingRecord.End_Date_Time__c");
    var currentResourceId = component.get("v.originalResourceId");
    if (newMeetingStartDateTime && newMeetingEndDateTime) {
      var utcStart = moment(newMeetingStartDateTime).utc().format();
      var utcEnd = moment(newMeetingEndDateTime).utc().format();
      action.setParams({
        currentResourceId,
        newMeetingStartDateTime: utcStart,
        newMeetingEndDateTime: utcEnd
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var responseValue = response.getReturnValue();
          // console.log('getAvailableResources ' + JSON.stringify(responseValue));
          component.set("v.availableResources", responseValue);
        } else if (state === "INCOMPLETE") {
          // do something
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              console.log("Error message: " + errors[0].message);
            }
          } else {
            console.log("Unknown error");
          }
        }
      });
      $A.enqueueAction(action);
    }
  },
  showSpinner: function (component, event, helper) {
    component.set("v.showSpinner", true);
  },
  hideSpinner: function (component, event, helper) {
    component.set("v.showSpinner", false);
  }
});
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  doInit: function (component, event, helper) {
    var recordId = component.get("v.recordId");
    console.log("DoInit");
    var hasAccessToEditAction = component.get("c.checkUserAccessToEdit");
    hasAccessToEditAction.setParams({
      groupId: component.get("v.recordId")
    });
    hasAccessToEditAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.hasAccessToEdit", response.getReturnValue());
        var action = component.get("c.getGroupMembers");
        action.setParams({
          groupId: recordId
        });
        var actions = [
          { label: "Edit Dates", name: "EditDates" },
          { label: "Change Role", name: "ChangeRole" }
        ];
        var coulmnsPatient = [
          {
            label: "Name",
            fieldName: "linkName",
            type: "url",
            typeAttributes: { label: { fieldName: "Name" }, target: "_blank" },
            sortable: true
          },
          {
            label: "Joined Date",
            fieldName: "Joined_Date__c",
            type: "date-local",
            sortable: true,
            initialWidth: 100,
            typeAttributes: { month: "2-digit", day: "2-digit" }
          },
          {
            label: "Role",
            fieldName: "Role__c",
            type: "text",
            sortable: true,
            initialWidth: 150,
            cellAttributes: { class: "onClickRole" }
          },
          {
            label: "Start Date",
            fieldName: "Start_Date__c",
            type: "date-local",
            sortable: true,
            initialWidth: 90,
            typeAttributes: { month: "2-digit", day: "2-digit" }
          },
          {
            label: "End Date",
            fieldName: "Planned_End_Date__c",
            type: "date-local",
            sortable: true,
            initialWidth: 90,
            typeAttributes: { month: "2-digit", day: "2-digit" }
          }
        ];
        if (component.get("v.hasAccessToEdit")) {
          // coulmnsPatient.push({type: "button", typeAttributes: {
          //         label: 'Edit Dates',
          //         name: 'EditDates',
          //         title: 'View',
          //         disabled: { fieldName: 'isButtonDisabled'},
          //         value: 'view',
          //         iconPosition: 'left',
          //         class: { fieldName: 'testHideClass'}
          //     }});
          // coulmnsPatient.push( {type: "button",typeAttributes: {
          //         label: 'Change Role',
          //         name: 'ChangeRole',
          //         title: 'Edit',
          //         disabled: { fieldName: 'isButtonDisabled'},
          //         value: 'edit',
          //         iconPosition: 'left',
          //         class: { fieldName: 'testHideClass'}
          // } });
          coulmnsPatient.push({
            type: "customLinkButton",
            label: "Actions",
            fieldName: "Id",
            typeAttributes: {
              buttonLabelA: "Edit Dates",
              buttonLabelB: "Change Role",
              disabled: { fieldName: "isButtonDisabled" }
            }
          });
        } else {
          component.set("v.ButtonDisabled", true);
        }
        component.set("v.columns", coulmnsPatient);
        var columnsStaff = [
          {
            label: "Name",
            fieldName: "linkName",
            type: "url",
            typeAttributes: { label: { fieldName: "Name" }, target: "_blank" },
            sortable: true
          },
          {
            label: "Joined Date",
            fieldName: "Joined_Date__c",
            type: "date-local",
            sortable: true,
            initialWidth: 100,
            typeAttributes: {
              month: "2-digit",
              day: "2-digit"
            }
          },
          {
            label: "Role",
            fieldName: "Role__c",
            type: "text",
            sortable: true,
            initialWidth: 150
          },
          {
            label: "Start Date",
            fieldName: "Start_Date__c",
            type: "date-local",
            sortable: true,
            initialWidth: 90,
            typeAttributes: {
              month: "2-digit",
              day: "2-digit"
            }
          },
          {
            label: "End Date",
            fieldName: "Planned_End_Date__c",
            type: "date-local",
            sortable: true,
            initialWidth: 90,
            typeAttributes: {
              month: "2-digit",
              day: "2-digit"
            }
          }
        ];
        // if(component.get("v.hasAccessToEdit")){
        //     columnsStaff.push({type: "button", typeAttributes: {
        //             label: 'Edit Dates',
        //             name: 'EditDates',
        //             title: 'View',
        //             disabled: { fieldName: 'isButtonDisabled'},
        //             value: 'Dates',
        //             iconPosition: 'left',
        //             class: { fieldName: 'testHideClass'}
        //     }});
        //     columnsStaff.push(  {type: "button",typeAttributes: {
        //             label: 'Change Role',
        //             name: 'ChangeRole',
        //             title: 'Role',
        //             disabled: { fieldName: 'isButtonDisabled'},
        //             value: 'edit',
        //             iconPosition: 'left',
        //             class: { fieldName: 'testHideClass'}
        //         } });
        // }
        if (component.get("v.hasAccessToEdit")) {
          columnsStaff.push({
            type: "customLinkButton",
            label: "Actions",
            fieldName: "Id",
            initialWidth: 90,
            typeAttributes: {
              buttonLabelA: "Edit Dates",
              buttonLabelB: "Change Role",
              disabled: { fieldName: "isButtonDisabled" }
            }
          });
        }
        component.set("v.columnsStaff", columnsStaff);
        action.setCallback(this, function (response) {
          console.log(response.getReturnValue());
          component.set("v.group", response.getReturnValue());
          //Add Authorized Signer column to the Stagff table if Group type = Team
          if (response.getReturnValue().Type__c == "Team" || response.getReturnValue().Authorized_Signers__c) {
            let columnsToModify = component.get("v.columnsStaff");
            columnsToModify.splice(5, 0, {
              label: "Auth Signer",
              fieldName: "Authorized_Signer__c",
              type: "boolean",
              sortable: true,
              fixedWidth: 100
            });
            columnsToModify.join();
            component.set("v.columnsStaff", columnsToModify);
          }
          component.set(
            "v.staffGroupMembers",
            response.getReturnValue().Staff_Group_Members__r
          );
          component.set(
            "v.patientGroupMembers",
            response.getReturnValue().Patient_Group_Members__r
          );
          var rowspatient = response.getReturnValue().Patient_Group_Members__r;
          if (rowspatient) {
            for (var i = 0; i < rowspatient.length; i++) {
              var row = rowspatient[i];
              if (row.Patient__r.Name) {
                console.log(row.Start_Date__c);
                row.Name = row.Patient__r.Name;
                row.linkName = "/" + row.Patient__c;
                row.ChangeRole = "Change Role";
              }
              if (row.Planned_End_Date__c) {
                row.isButtonDisabled = true;
                row.testHideClass = "testClassDisabled";
              } else {
                row.isButtonDisabled = false;
              }
              if (!component.get("v.hasAccessToEdit")) {
                row.testHideClass = "testClass";
              }
            }
          }
          component.set("v.dataPatient", rowspatient);
          var rowsStaff = response.getReturnValue().Staff_Group_Members__r;
          if (rowsStaff) {
            for (var i = 0; i < rowsStaff.length; i++) {
              var row = rowsStaff[i];
              if (row.Staff_Member__r.Name) {
                row.Name = row.Staff_Member__r.Name;
                row.linkName = "/" + row.Staff_Member__c;
              }
              if (row.Planned_End_Date__c) {
                row.isButtonDisabled = true;
                row.testHideClass = "testClassDisabled";
              } else {
                row.isButtonDisabled = false;
              }
              if (!component.get("v.hasAccessToEdit")) {
                row.testHideClass = "testClass";
              }
            }
          }
          component.set("v.dataStaff", rowsStaff);
        });
        $A.enqueueAction(action);
      }
    });
    $A.enqueueAction(hasAccessToEditAction);
  },
  add: function (component, event, helper) {
    var appEvent = $A.get("e.c:AddNewGroupButtonEvent");
    let group = component.get("v.group");
    appEvent.setParams({
      buttonClicked: "add",
      group: group
    });
    appEvent.fire();
  },
  callFunction: function (cmp, event, helper) {
    alert("hi");
  },
  Close: function (component, event, helper) {
    var appEvent = $A.get("e.c:AddNewGroupButtonEvent");
    appEvent.setParams({
      buttonClicked: "Close"
    });
    appEvent.fire();
  },
  handleRowAction: function (cmp, event, helper) {
    var hasAccess = cmp.get("v.hasAccessToEdit");
    if (hasAccess) {
      let data = cmp.get("v.dataPatient");
      let recordId = event.getParam("recordId");
      var row = data.find((item) => item.Id == recordId);
      var label = event.getParam("label");
      switch (label) {
        case "Edit Dates":
          console.log("Showing Details: " + JSON.stringify(row));
          //this.EditDatesPatient(cmp, event, helper, row.Id);
          //$A.enqueueAction(cmp.get('c.EditDatesPatient'));
          helper.EditDatesPatient(cmp, recordId, helper);
          break;
        case "Change Role":
          helper.changeRolePatient(cmp, recordId, helper);
          break;
      }
    } else {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        title: "Error!",
        type: "error",
        message: "You do not have permission to perform this action."
      });
      toastEvent.fire();
    }
  },
  handleRowActionStaff: function (cmp, event, helper) {
    let label = event.getParam("label");
    let recordId = event.getParam("recordId");
    let data = cmp.get("v.dataStaff");
    let row = data.find((item) => item.Id == recordId);
    switch (label) {
      // case 'EditDates':
      case "Edit Dates":
        console.log("Showing Details: " + JSON.stringify(row));
        //this.EditDatesPatient(cmp, event, helper, row.Id);
        //$A.enqueueAction(cmp.get('c.EditDatesPatient'));
        // helper.EditDatesStaff(cmp,event,helper);
        helper.EditDatesStaff(cmp, recordId, helper);
        break;
      // case 'ChangeRole':
      case "Change Role":
        // helper.changeRoleStaff(cmp,event,helper);
        helper.changeRoleStaff(cmp, recordId, helper);
        break;
    }
  },
  //Method gets called by onsort action,
  handleSort: function (component, event, helper) {
    //Returns the field which has to be sorted
    var fieldName = event.getParam("fieldName");
    //returns the direction of sorting like asc or desc
    var sortDirection = event.getParam("sortDirection");
    //Set the sortBy and SortDirection attributes
    component.set("v.sortBy", fieldName);
    component.set("v.sortDirection", sortDirection);
    // call sortData helper function
    //helper.sortData(component,sortBy,sortDirection);
    var data = component.get("v.dataPatient");
    //function to return the value stored in the field
    var key = function (a) {
      return a[fieldName];
    };
    var reverse = sortDirection == "asc" ? 1 : -1;
    // to handel number/currency type fields
    if (fieldName == "NumberOfEmployees") {
      data.sort(function (a, b) {
        var a = key(a) ? key(a) : "";
        var b = key(b) ? key(b) : "";
        return reverse * ((a > b) - (b > a));
      });
    } else {
      data.sort(function (a, b) {
        var a = key(a) ? key(a).toLowerCase() : ""; //To handle null values , uppercase records during sorting
        var b = key(b) ? key(b).toLowerCase() : "";
        return reverse * ((a > b) - (b > a));
      });
    }
    //set sorted data to accountData attribute
    component.set("v.dataPatient", data);
  },
  handleSortStaff: function (component, event, helper) {
    var sortingOption = {
      asc: "desc",
      desc: "asc"
    };
    //Returns the field which has to be sorted
    var fieldName = event.getParam("fieldName");
    //returns the direction of sorting like asc or desc
    var sortDirection = component.get("v.sortDirectionStaff");
    if (!sortDirection) {
      sortDirection = event.getParam("sortDirection");
    } else {
      sortDirection = sortingOption[sortDirection];
    }
    //Set the sortBy and SortDirection attributes
    component.set("v.sortByStaff", fieldName);
    component.set("v.sortDirectionStaff", sortDirection);
    // call sortData helper function
    //helper.sortData(component,sortBy,sortDirection);
    var data = component.get("v.dataStaff");
    //function to return the value stored in the field
    var key = function (a) {
      if (fieldName == "linkName") {
        return a["Name"];
      }
      return a[fieldName];
    };
    var reverse = sortDirection == "asc" ? 1 : -1;
    // to handel number/currency type fields
    if (fieldName == "NumberOfEmployees") {
      data.sort(function (a, b) {
        var a = key(a) ? key(a) : "";
        var b = key(b) ? key(b) : "";
        return reverse * ((a > b) - (b > a));
      });
    } else {
      data.sort(function (a, b) {
        if (typeof key(a) != "boolean") {
        var a = key(a) ? key(a).toLowerCase() : ""; //To handle null values , uppercase records during sorting
        var b = key(b) ? key(b).toLowerCase() : "";
        } else {
          var a = key(a) ? key(a) : ""; //To handle null values , uppercase records during sorting
          var b = key(b) ? key(b) : "";
        }
        return reverse * ((a > b) - (b > a));
      });
    }
    //set sorted data to accountData attribute
    component.set("v.dataStaff", data);
  },
  onRender: function (component, event, helper) {},
  patientRadioChanged: function (component, event, helper) {
    var recordId = component.get("v.recordId");
    var allOrActive = component.get("v.patientCheckBox");
    var action = component.get("c.getPatientGroupMembers");
    action.setParams({
      groupId: recordId,
      allOrActive: allOrActive
    });
    action.setCallback(this, function (response) {
      var rowspatient = response.getReturnValue();
      for (var i = 0; i < rowspatient.length; i++) {
        var row = rowspatient[i];
        if (row.Patient__r.Name) {
          row.Name = row.Patient__r.Name;
          row.linkName = "/" + row.Patient__c;
          row.ChangeRole = "Change Role";
        }
        if (row.Planned_End_Date__c) {
          row.isButtonDisabled = true;
          row.testHideClass = "testClassDisabled";
        } else {
          row.isButtonDisabled = false;
        }
        if (!component.get("v.hasAccessToEdit")) {
          row.testHideClass = "testClass";
        }
      }
      component.set("v.dataPatient", rowspatient);
    });
    $A.enqueueAction(action);
  },
  staffRadioChanged: function (component, event, helper) {
    var recordId = component.get("v.recordId");
    var allOrActive = component.get("v.staffCheckBox");
    var action = component.get("c.getStaffGroupMembers");
    action.setParams({
      groupId: recordId,
      allOrActive: allOrActive
    });
    action.setCallback(this, function (response) {
      var rowsStaff = response.getReturnValue();
      for (var i = 0; i < rowsStaff.length; i++) {
        var row = rowsStaff[i];
        if (row.Staff_Member__r.Name) {
          row.Name = row.Staff_Member__r.Name;
          row.linkName = "/" + row.Staff_Member__c;
        }
        if (row.Planned_End_Date__c) {
          row.isButtonDisabled = true;
          row.testHideClass = "testClassDisabled";
        } else {
          row.isButtonDisabled = false;
        }
        if (!component.get("v.hasAccessToEdit")) {
          row.testHideClass = "testClass";
        }
      }
      component.set("v.dataStaff", rowsStaff);
    });
    $A.enqueueAction(action);
  }
});
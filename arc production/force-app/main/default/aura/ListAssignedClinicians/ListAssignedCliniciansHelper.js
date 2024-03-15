/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  loadData: function (component, event, helper) {
    //helper.showSpinner(component, 'Loading');
    component.set("v.loaded", false);

    var recordId = component.get("v.recordId");
    var showValue = component.get("v.radioValue");
    var action = component.get("c.getAssignedClinicians");
    var permissionAction = component.get("c.checkManagedCliniciansPermission");
    action.setParams({
      accountID: recordId,
      showValue: showValue
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.assignedClinicians", response.getReturnValue());

        // Begin section added by Sols ARC-2100
        component.get("v.assignedClinicians").forEach((element) => {
          console.log(JSON.stringify(element));
          //   if (element.Role__c === "Substance Use Counselor") {
          //     component.set("v.hasSUS", true);
          //     component.set("v.SUSId", element.User__c);
          //     component.set("v.admissionId", element.Admission__c);
          //     console.log(element.Admission__r.Substance_Use_Counselor_Active__c);
          //     if (element.Admission__r.Substance_Use_Counselor_Active__c) {
          //       component.set("v.SUSActive", true);
          //     } else {
          //       component.set("v.SUSActive", false);
          //     }
          //   }
          //   if (element.Role__c === "Registered Dietitian Nutritionist") {
          //     component.set("v.hasDietician", true);
          //     component.set("v.dieticianId", element.User__c);
          //     component.set("v.admissionId", element.Admission__c);
          //     if (element.Admission__r.Registered_Dietician_Nutritionist_Active__c) {
          //       component.set("v.dieticianActive", true);
          //     } else {
          //       component.set("v.dieticianActive", false);
          //     }
          //   }
        });
        // End section added by Sols ARC-2100
      } else {
        component.set("v.assignedClinicians", []);
        component.find("notifLib").showToast({
          title: "Error",
          variant: "error",
          message: JSON.stringify(response.getError())
        });
      }
      this.sortBy(component, component.get("v.sortField"), "DESC");
      // helper.hideSpinner(component);
      component.set("v.loaded", true);
    });
    $A.enqueueAction(action);

    permissionAction.setCallback(this, function (response) {
      if (response.getState() == "SUCCESS") {
        component.set("v.hasClinicianPermission", response.getReturnValue());
      }
    });
    $A.enqueueAction(permissionAction);
  },

  sortBy: function (component, field, sortDirection) {
    var sortAsc = component.get("v.sortAsc"),
      sortField = component.get("v.sortField"),
      records = component.get("v.assignedClinicians");
    if (sortDirection) {
      //explicitly set direction
      sortAsc = sortDirection == "ASC" ? true : false;
    } else {
      //sortAsc true if changing columns or if current sortAsc is false, otherwise true
      sortAsc = sortField != field || sortAsc == false;
    }
    records.sort(function (a, b) {
      var t1 = a[field] == b[field],
        t2 = (a[field] && !b[field]) || a[field] < b[field];
      return t1 == true ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
    });
    component.set("v.sortAsc", sortAsc);
    component.set("v.sortField", field);
    component.set("v.assignedClinicians", records);
  },

  updateDietician: function (component, checked) {
    var action = component.get("c.updateActiveAssignedClinician");
    action.setParams({
      admissionID: component.get("v.admissionId"),
      activeType: "Dietician",
      checked: checked
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.loading", false);
      }
    });
    // enqueue the Action
    $A.enqueueAction(action);
  },

  updateSUS: function (component, checked) {
    component.set("v.loading", true);
    var action = component.get("c.updateActiveAssignedClinician");
    action.setParams({
      admissionID: component.get("v.admissionId"),
      activeType: "SUS",
      checked: checked
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.loading", false);
      }
    });
    // enqueue the Action
    $A.enqueueAction(action);
  }
});
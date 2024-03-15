/* eslint-disable no-unused-expressions */
({
  doInit: function (component, event, helper) {
    helper.callApexMethod(
      component,
      "getDependentOptionsImpl",

      {
        objectName: component.get("v.objectApiName"),
        field: component.get("v.fieldName"),
        cntrlField: component.get("v.controllingField")
      },
      function (result) {
        component.set("v.dependentOptionsMap", result);
      },
      null
    );
  },

  onControllingFieldChange: function (component, event, helper) {
    let controllingFieldValue = component.get("v.controllingFieldValue"),
      dependentOptionsMap = component.get("v.dependentOptionsMap");

    if (!dependentOptionsMap) return;

    if (controllingFieldValue && controllingFieldValue != "") {
      let dependentOptions = (collection) => {
        return collection.map((option) => {
          let recordMap = { label: option, value: option };
          return recordMap;
        });
      };

      let options = dependentOptions(
        dependentOptionsMap[controllingFieldValue]
      );
      if (options.length == 0) {
        component.set("v.fieldValue", "");
      }
      options.splice(0, 0, { label: "--None--", value: "" });
      component.set("v.options", options);
    } else {
      component.set("v.fieldValue", "");
      component.set("v.options", [{ label: "--None--", value: "" }]);
    }
  }
});
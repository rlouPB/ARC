({
  selectobj: function (component, event, helper) {
    var instanceName = component.get("v.instanceName");
    var getSelectObj = component.get("v.obj");
    var compEvent = component.getEvent("selectedItemEvent");
    compEvent.setParams({
      sourceInstanceName: instanceName,
      selectedObj: getSelectObj
    });
    compEvent.fire();
  }
});
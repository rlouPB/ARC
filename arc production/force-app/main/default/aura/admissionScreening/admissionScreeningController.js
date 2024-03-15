({
  doInit: function (component, event, helper) {
    let accountId = component.get("v.recordId");

    helper.callApexMethod(
      component,
      "getQuestionsForAccount",
      { parentId: accountId },
      function (result) {
        console.log("result", JSON.stringify(result));
        component.set("v.selectedQuestions", result.selectedQuestions);
        component.set("v.relatedContacts", result.relatedContacts);
        component.set("v.allQuestions", result.allQuestions);
        console.log(component.get("v.selectedQuestions"));
        console.log(component.get("v.relatedContacts"));
        console.log(component.get("v.allQuestions"));
        helper.toggleSpinner(component, 0);
      },
      function (errorcallback) {
        helper.toggleSpinner(component, 0);
      }
    );
  },
  onViewChange: function (component, event, helper) {
    const viewState = event.getSource().get("v.title");

    if (viewState === "selectedQuestion") {
      component.set("v.isSelectedQuestion", true);
    } else {
      component.set("v.isSelectedQuestion", false);
    }
  }
});
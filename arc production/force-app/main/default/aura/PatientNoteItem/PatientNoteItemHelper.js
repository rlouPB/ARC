/* eslint-disable vars-on-top */
/* eslint-disable no-unused-expressions */
({
  instantiateEmbeddedComponent: function (component, event, helper) {
    var noteItem = component.get("v.noteItem");
    var patientNote = component.get("v.patientNote");
    var instanceName = component.get("v.instanceName");
    var componentName = noteItem.noteItem.Embedded_Component_Name__c;
    var parameters = {};
    // console.log("creating component:"+componentName);
    if (noteItem.noteItem.Embedded_Component_Parameters__c) {
      //console.log("patientNote:"+JSON.stringify(patientNote));
      parameters = JSON.parse(
        noteItem.noteItem.Embedded_Component_Parameters__c
      );

      //commenting out this section 210422 JN. Not sure what it's supposed to do, but it has the bad effect of deleting parameter keys

      // Object.keys(parameters).forEach(function(key){
      //         console.log("key:"+key+", parameters[key]:"+parameters[key]);
      //     if(!$A.util.isUndefined(patientNote.patientNote[parameters[key]])){
      //         parameters[key] = patientNote.patientNote[parameters[key]];
      //         console.log("key:"+key+", parameters[key]:"+parameters[key]+", patientNote:"+patientNote.patientNote[parameters[key]]);
      //     }else{
      //         delete parameters[key];
      //     }
      // });
      /*
            if(!$A.util.isEmpty(parameters.selectedOption)){
                parameters.selectedOption = patientNote[parameters.selectedOption];
            }
            if(!$A.util.isEmpty(parameters.selectedRecord)){
                parameters.selectedRecord.value = patientNote[""];
            }*/
    }
    parameters.theNote = patientNote;
    parameters.noteItem = noteItem;
    parameters.instanceName = "embedded_" + instanceName;
    // console.log('component parameters ' + JSON.stringify(parameters));
    // console.log('================== component parameters ----> ', JSON.parse(JSON.stringify(parameters)));
    $A.createComponent(
      componentName,
      parameters,
      function (embeddedComponent, status, errorMessage) {
        if (status === "SUCCESS") {
          // console.log("successfully created component " + componentName);

          var embeddedContainer = component.find("embeddedContainer");
          if(embeddedContainer){
            var body = embeddedContainer.get("v.body");
            // console.log(JSON.stringify(body));
            body.push(embeddedComponent);
            embeddedContainer.set("v.body", body);
          }
        } else if (status === "INCOMPLETE") {
          // console.log("No response from server or client is offline.");
          // Show offline error
        } else if (status === "ERROR") {
          // console.log("Error: " + errorMessage);
          // Show error message
        }
      }
    );
  },

  checkHideNoteItem: function (component, event, helper, changedFields) {
    // Initial value
    var initialHideNoteItem = component.get("v.hideNoteItem");

    var noteItem = component.get("v.noteItem");
    var patientNote = component.get("v.patientNote");

    var newHideNoteItem = false;
    if (noteItem.noteItem.Hide_Conditions__c) {
      var conditions = JSON.parse(noteItem.noteItem.Hide_Conditions__c);
      // console.log('conditions ' + JSON.stringify(conditions));

      //assume this note item hide status needs to be calculated
      var isThisNoteItemAffected = true;

      //changedFields passed from Note Changed Event
      if (changedFields) {
        isThisNoteItemAffected = changedFields.some(function (changedField) {
          return changedField == conditions.fieldName;
        });
      }

      if (!isThisNoteItemAffected) return;

      //check for controlling display field value
      var noteFieldValue = patientNote.patientNote[conditions.fieldName];
      if (conditions.operator == "==") {
        newHideNoteItem = noteFieldValue == conditions.fieldValue;
      } else if (conditions.operator == "!=") {
        newHideNoteItem = noteFieldValue != conditions.fieldValue;
      }
    }

    if (newHideNoteItem != initialHideNoteItem) {
      // console.log(
      //   "instanceName " +
      //     component.get("v.instanceName") +
      //     " changing to HIDE = " +
      //     newHideNoteItem
      // );
      component.set("v.hideNoteItem", newHideNoteItem);
    }
  }
});
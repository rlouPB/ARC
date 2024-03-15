({
    myAction : function(component, event, helper) {

    },
    doInit: function (component, event, helper) {
        console.log(
            "PrescriptionNoteItem ---- " +
              component.get("v.patientRecord")
          );
        console.log(
            "v.theNote.patientNote.Account__c---- " 
          );
        var a =JSON.parse(JSON.stringify( component.get("v.theNote")))
        console.log(a)        
    },
    handleSaveAwayOrderInfo: function (component, event, helper) {
      // debugger;
      console.log('In handleSaveAwayOrderInfo handling - event.getParam(firDay) : ', event.getParam('firstDayAwayStr'))
      var firstDayAwayStr = event.getParam('firstDayAwayStr');
      var lastDayAwayStr = event.getParam('lastDayAwayStr');
      var finalDischargeMedOrder = event.getParam('finalDischargeMedOrder');
      var daysToPackage = event.getParam('daysToPackage');
    
      var changedFields = component.set("v.changedFields") || [];

      if(firstDayAwayStr){
        changedFields.push({
          field: "Away_First_Date__c",
          value: firstDayAwayStr
        });
      }

      if(lastDayAwayStr) {
        changedFields.push({
          field: "Away_Last_Date__c",
          value: lastDayAwayStr
        });
      }

      // if(finalDischargeMedOrder) {
        changedFields.push({
          field: "Final_Discharge_Med_Order__c",
          value: finalDischargeMedOrder
        });
      // }

      if(daysToPackage) {
        changedFields.push({
          field: "Days_to_Package__c",
          value: daysToPackage
        });
      }
      
      component.set("v.changedFields", changedFields);
      helper.fireNoteChangedEvent(component, event, helper);
      console.log('Just updated changedFields in PrescriptionNoteItem - changedFields : ', changedFields);
    }
})
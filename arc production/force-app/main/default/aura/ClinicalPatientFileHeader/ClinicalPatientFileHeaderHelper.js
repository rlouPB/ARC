/* eslint-disable no-unused-expressions */
({
  populateDefaultAccountFields: function (component, event, helper) {
    var defaultAccountFields = [
      {
        apiName: "Name",
        label: "Patient"
      },
      {
        apiName: "Team__c",
        label: "Team"
      },
      {
        apiName: "Gender_Identifies_As__c",
        label: "Gender Identifies As"
      },
      {
        //apiName: "Current_Program__c",
        //Current_Admission__r.Current_Admitted_Program__r.Current_Status__c
        apiName: "Current_Admitted_Program_Name__c",
        addOn: "Current_Admission__r.Current_Admitted_Program__r.Current_Status__c",
        label: "Program"
      },
      // {
      //   apiName: "Current_Admission__r.In_Pass__c",
      //   label: "PAS"
      // },
      {
        apiName: "Preferred_Pronouns__c",
        label: "Preferred Pronouns"
      },
      {
        apiName: "Room__c",
        label: "Room"
      },
      {
        apiName: "Age__c",
        label: "Age"
      },
      {
        apiName: "Extension__c",
        label: "Extension"
      },
      {
        apiName: "Admit_Date__c",
        label: "Admit Date"
      },
      {
        apiName: "MobilePhone__c",
        label: "Mobile Phone"
      },
      
      {
        apiName: "Previous_Admissions_Numeric__c",
        label: "Previous Admissions"
      },
      {
        apiName: "Visitors_Clinical_Conferences__c",
        label: "Visitors at clinical conferences"
      }
      // {
      //   apiName: "Current_Admission_Stage__c",
      //   label: "Status"
      // },
      // {
      //     'apiName': 'Current_Program__c',
      //     'label': 'Program'
      // },
      //{
      //     'apiName': 'Riggs_Extension__c',
      //     'label': 'Extension'
      // },
      
      //{
      //     'apiName': 'Mobile__c',
      //     'label': 'Mobile'
      // },

    ];
    component.set("v.recordFields", defaultAccountFields);
  },
  retrievePatientFileHeaderSetting : function(component){
    return new Promise($A.getCallback(function(resolve){
        var action = component.get("c.getPatientFileHeaderSetting");
        action.setParams({
          "patientId"	: component.get("v.recordId")
      });
        action.setCallback(this, $A.getCallback(function(actionResult) {
            resolve(actionResult.getReturnValue());
        }));
        $A.enqueueAction(action);
    }));
  },
  populateFields: function (component, event, helper) {
    //possible get this list from the server, but if not use default
    helper.populateDefaultAccountFields(component, event, helper);
  },
  shouldShowClinicalPatientFile : function(component){
    return new Promise($A.getCallback(function(resolve){
        var action = component.get("c.shouldShowClinicalPatientFile");
        action.setParams({
            "accountId" : component.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function(result) {
            if(null != result && result.getReturnValue()){
              console.log('in shouldShowClinicalPatientFile - result.getReturnValue() : ', result.getReturnValue());
              component.set('v.showClinicalPatientFile', true);
            } else {
              component.set('v.cpMessage', 'To see more information, contact Medical Records for an Access Pass.')
            }
        }));
        $A.enqueueAction(action);
    }));
}
});
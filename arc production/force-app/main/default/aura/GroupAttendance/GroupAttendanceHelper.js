({
	
    clearPill : function(component, event, helper){
         var patientCmp = component.find("patientLookup");
         
       
         if(patientCmp)
        {
            if(patientCmp != 'undefined'){
                var retnMsg = patientCmp.closePill();
            }
        }
        
         
    },
    
    setFilters: function(component) {

        var patientLookupFilter = [
            {
                'fieldName': 'RecordType.Name',
                'condition': '=',
                'value': 'Patient'
            },
            {
                'fieldName': 'Account.Current_Admission_Stage__c',
                'condition': '=',
                'value': 'Admitted'
            } 
        ];
        component.set("v.patientLookupFilter", patientLookupFilter);
    },
    // 221021 JN replaced with v.noTracking from parent component
    // getAttendanceTracking : function(component, event, helper){
    //     var action = component.get("c.getAttendanceTracking");
    //     action.setParams({
    //         "groupMembershipId": component.get("v.objGroupNote.Meeting__r.Group_Membership__c")
    //     });
    //     action.setCallback(this, function(response){
    //         var state = response.getState();
    //         if(state === "SUCCESS"){
    //         	component.set("v.AttendanceTracking", response.getReturnValue());
    //     	}
    //     });
    //     $A.enqueueAction(action);
    // },
    countAttended : function(component, event, helper)
    {
        var counter = 0;
        var lstGroupAttendance = component.get('v.lstGroupAttendance');
        if(lstGroupAttendance)
        {
            for(var i = 0; i <lstGroupAttendance.length; i++ )
            {
                if(lstGroupAttendance[i].gatt.Attended__c)
                {
                    counter += 1;
                }
            }
        }
        component.set("v.noOfPatientsAttended",counter);
    },
    selectedPatient : function ( component, event, helper)
    {
        // var highlighted = document.getElementsByClassName('highlighted');
        // highlighted.forEach(function(elem) {
        //     elem.classList.remove('highlighted');
        // });

        // if (highlighted.length > 0)
        // {
        //     highlighted.classList.remove('highlighted');
        // }
        var selectedRecord = component.get('v.selectedRecord');
        var lstGroupAttendance = component.get("v.lstGroupAttendance");
        var recordExists = false;
        if(lstGroupAttendance)
        {
            for(var i = 0; i <lstGroupAttendance.length; i++ )
            {
                 console.log('new rec '+selectedRecord.value+'---newRC '+selectedRecord.value);
                if(lstGroupAttendance[i].gatt.Patient__c == selectedRecord.value)
                {
                    recordExists = true;
                }
                
            }
        }
        console.log('new rec exists'+recordExists);
        if(!recordExists)
        {
            var params = event.getParams();
            var sourceInstanceName = params.sourceInstanceName;
            var selectedObj = params.selectedObj;
            console.log('sourceInstanceName',sourceInstanceName);
            console.log('selectedObj',selectedObj);
            // console.log('serlectedrecord',component.get("v.selectedRecordPatient").value);
            //console.log('selectedObjasdasd',component.get("v.objGroupAttendance.Patient__c"));
            var newGroupAttendance = {
                gatt: {
                    Patient__c: selectedObj.value,
                    Attended__c: true
                },
                fullName: selectedObj.label,
                lastName: selectedObj.label
            };
            lstGroupAttendance =   component.get("v.lstGroupAttendance");
            lstGroupAttendance.push(newGroupAttendance);
            component.set("v.lstGroupAttendance",lstGroupAttendance);
           
            
            // var action = component.get("c.getGroupAttendanceInstance");
            // action.setParams({
            //     "accId": component.get("v.selectedRecordPatient").value,
            //     "groupNoteId": component.get("v.objGroupNote.Id")
            // });
            // action.setCallback(this,function(response){
            //     var state = response.getState();
            //     if(state === "SUCCESS"){
            //         var lstGA;
            //         console.log('lstgroupatt',component.get("v.lstGroupAttendance"));
            //         if( component.get("v.lstGroupAttendance") == undefined)
            //         lstGA = [];
            //         else
            //         lstGA =   component.get("v.lstGroupAttendance");
            //         lstGA.push(response.getReturnValue());
            //         component.set("v.lstGroupAttendance",lstGA);
            //         console.log('ret rec',component.get("v.lstGroupAttendance"));
            //     }
            // });
           
         
            //      $A.enqueueAction(action);
            
           
        }else{
            helper.duplicateRecord(component, event, helper, selectedRecord.value);
            // var childCmp = component.find("gaComponent")
            //  childCmp.duplicatePatient(newRecordId);
                       
        }
        helper.clearPill(component, event, helper);
        helper.countAttended(component, event, helper);
    },
    duplicateRecord : function(component, event, helper, dupRecId)
    {
        // var params = event.getParam('arguments');
        // if (params) {
        // var dupRecId = params.recordId;
        // alert('child component function'+dupRecId);
        // var dupRec = component.find(dupRecId);
        // $A.util.addClass(dupRec, 'highlighted');
        
        document.getElementById(dupRecId).classList.add('highlighted');
        // component.set("v.duplicateRecordId",dupRecId);
        // add your code here
        // }
        //component.set('v.selectedRecord',)
    },

    
})
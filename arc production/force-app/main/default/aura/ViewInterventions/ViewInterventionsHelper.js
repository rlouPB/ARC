({
    getColumnDefinitions: function () {
        var columns = [
            {label: 'Discipine', fieldName: 'discipline', type: 'text', sortable: false},
            {label: 'Intervention', fieldName: 'description', type: 'text', sortable: false},
            {label: 'Patient-specific Details', fieldName: 'patientSpecificDetail', type: 'text', sortable: false},
            {label: 'Start Date', fieldName: 'startDate', type: 'date', sortable: false},
            {label: 'End Date', fieldName: 'endDate', type: 'date', sortable: false}
        ];

        return columns;
    },

    getInterventions: function (component, event, helper, showAll) {
        component.set("v.data", []);
        let treatmentPlanId= component.get("v.treatmentPlanId");
        helper.callApexMethod(
            component,
            "getInterventions",
            { "treatmentPlanId" : treatmentPlanId,
            "showAll": showAll },
            function (result) {
                console.log("result:"+JSON.stringify(result));
                if(!$A.util.isEmpty(result)){
                    let data = [];
                    if(result.length > 0){
                        let currentDiscipline = '';
                        let showDiscipline = false;
                        result.forEach(intervention => {
                            if($A.util.isEmpty(currentDiscipline) || currentDiscipline != intervention.Discipline__c){
                                currentDiscipline = intervention.Discipline__c;
                                showDiscipline = true;
                            }else{
                                showDiscipline = false;
                            }
                            let row = {
                                "discipline" : (showDiscipline == true ? intervention.Discipline__c : ''),
                                "description" : intervention.Description__c,
                                "patientSpecificDetail" : intervention.Patient_specific_Details__c,
                                "startDate" : intervention.Start_Date__c,
                                "endDate" : intervention.End_Date__c,
                                'status' : intervention.Status__c,
                            }
                            data.push(row);
                        });
                    }
                    component.set("v.data", data);
                }else{
                    console.log('Create View Intervention Stack Trace...');
                    let messages = '';
                    Object.keys(result).forEach(function(errorMessage){
                        messages += errorMessage + '\n';
                        console.log(result[errorMessage]);
                    });
                }
                helper.hideSpinner(component);
            },
            null,
            false
        );
    }
})
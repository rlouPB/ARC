({
    getTreatmentPlan:function(component,event,helper){
        let recordId= component.get("v.recordId");
        helper.callApexMethod(
            component,
            "getTreatmentPlan",
            { "caseId" : recordId },
            function (result) {
                if(result) {
                    component.set("v.treatmentPlan",result);
                    component.set("v.loading",false);
                }
            },
            null,
            true
        );
    },
    update : function(cmp, event) {
        let action = cmp.get("c.save");

        let goalsJson = JSON.stringify(cmp.get("v.goals"));
        console.log('goalsJson : ' + goalsJson);
        let objectivesJson = JSON.stringify(cmp.get("v.objectives"));
        console.log('objectivesJson : ' + objectivesJson);

        action.setParams({
            recordId: cmp.get('v.recordId'),
            sTreatment: JSON.stringify(cmp.get("v.treatment")),
            sGoals: JSON.stringify(cmp.get("v.goals")),
            sObjectives: JSON.stringify(cmp.get("v.objectives"))
        })

		action.setCallback(this, function (response) {

			let state = response.getState();

			if (state === "SUCCESS") {

                cmp.set('v.edit', false); 
                this.setData(cmp, response.getReturnValue()); 

			} else if (state === "ERROR") {

				let errors = response.getError();

                cmp.find('notifLib').showToast({
                    "variant": "error",
                    "title"  : "Error!",
                    "message": errors
                });

            }
            
            cmp.set('v.loading', false);

        });
        
        $A.enqueueAction(action);

        cmp.set('v.loading', true);

    }, 
    updateTreatmentPlan: function(cmp, id, sObject, field, value) {
        
        switch (sObject) {
            case 'Case':
                this.updateObject(cmp, 'Case', 'treatment', id, field, value);
                break;
            case 'Goal__c':
                this.updateObject(cmp, 'Goal__c', 'goals', id, field, value);
                break;
            case 'Objective__c':
                this.updateObject(cmp, 'Objective__c', 'objectives', id, field, value);
                break;
            default:
                break;
        }

    }, 
    updateObject: function(cmp, sObject, vObjects, id, field, value) {

        let objects = cmp.get(`v.${vObjects}`); 

        let exists = objects.find(o => o.Id == id) ? true : false; 

        if(exists) {

            objects = objects.map(o => {

                if(o.Id == id) {
                    o[field] = value; 
                }

                return o; 

            });

        } else {

            let o = { Type__c: sObject, Id: id };
            
            o[field] = value; 

            objects = objects.concat([o]); 

        }

        cmp.set(`v.${vObjects}`, objects); 

    }, 
    setData: function(cmp, value) {

        var data = JSON.parse(value);
        cmp.set('v.plan', data.plan); 

        var domainGoals = Object.keys(data.domainGoals).map(domain => {

            return {
                domain: domain, 
                goals: data.domainGoals[domain]
            }; 

        }); 

        cmp.set('v.domains', domainGoals);

    }
})
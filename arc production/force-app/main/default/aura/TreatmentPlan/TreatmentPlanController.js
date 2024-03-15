({
    doInit : function(component, event, helper) {
        component.set('v.loading', true);
		//helper.getTreatmentPlan(component,event,helper);
    },
    finalize: function(cmp, event, helper) {

    }, 
    edit: function(cmp, event, helper) {
        cmp.set('v.edit', true); 
    },
    savePlan: function(cmp, event, helper) {
        //TODO - Update this to only save the record without changing status.
        helper.update(cmp, event); 
    },
    saveAsComplete:function(component,event,helper){
        //TODO - Save all and changing the status to complete
    },
    cancel: function(cmp, event, helper) {
        cmp.set('v.edit', false); 
    },
    addGoal: function(cmp, event, helper) {

        let id = event.getSource().get("v.value")

        let domains = cmp.get('v.domains');
        let domainGoals = domains.map(domain => {
            console.log(domain, id); 
            if(domain.domain == id) {
                domain.newGoal = true; 
            }

            return domain;

        }); 

        cmp.set('v.domains', domainGoals);

    },
    handleTreatmentPlanEdit: function(cmp, event, helper) {
        let id = event.getParam("id");
        let sObject = event.getParam("sObject");
        let field = event.getParam("field");
        let value = event.getParam("value");

        helper.updateTreatmentPlan(cmp, id, sObject, field, value);
    }
})
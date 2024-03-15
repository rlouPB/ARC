({
    doInit : function(cmp, event, helper) {

        if(!cmp.get('v.view_columns')){
            cmp.set('v.view_columns',[
                {initialWidth: 150, label: 'Discipline', fieldName: 'discipline', type: 'text', wrapText:true},
                {label: 'Intervention', fieldName: 'description', type: 'text', wrapText:true},
                {label: 'Patient-specific Details', fieldName: 'patientSpecificDetail', type: 'text', wrapText:true},
                {initialWidth: 150, label: 'Start Date', fieldName: 'startDate', type: 'date-local',wrapText:true,
                typeAttributes: {
                    day: '2-digit',
                    month: '2-digit',
                    year: '2-digit'}},
                {initialWidth: 150, label: 'End Date', fieldName: 'endDate', type: 'date-local',wrapText:true,
                typeAttributes: {
                    day: '2-digit',
                    month: '2-digit',
                    year: '2-digit'}},
            ]);
        }

        cmp.set('v.value','Current');
        cmp.set('v.loaded',false);

        let treatmentPlanId = cmp.get('v.treatmentPlanId');
        helper.hasPermissions(cmp, treatmentPlanId).then($A.getCallback(function(){
            helper.reload(cmp, cmp.get('v.Current'));
            cmp.set('v.newIntervention',{ 
                "treatmentPlanId" : cmp.get('v.treatmentPlanId') 
            });
            helper.getDiciplinesRecords(cmp).then($A.getCallback(function(){
                cmp.set('v.loaded',true);
            }));
        }));
       
    },
    handleAllAndCurrentButtons : function(cmp, event, helper) {
        if(cmp.get('v.loaded')){
            let value = event.getParam('value');
            cmp.set('v.Current', value);
            helper.reload(cmp, value);
        }
    },
    handleCloseViewInterventions : function(cmp, event, helper) {
		let closeEvent = cmp.getEvent('closeModalEvent');
		closeEvent.setParam('data', cmp.get('v.instanceName'));
		closeEvent.fire();
    },
    onCustomRefreshHandler: function(cmp, event, helper){
        let refreshData = event.getParam('data');
        if(refreshData=='reload'){
            helper.reload(cmp, cmp.get('v.value'));
        }
    },
    handlerManageInterventionClick: function(cmp,event,helper){
        //cmp.set('v.mode', (cmp.get('v.mode')=='edit')?'view':'edit');
        cmp.set('v.showManageInterventionsModal', true);
    },
    onDiscontinueClickHandler :  function(cmp, event, helper) {
        let interId = event.getSource().get('v.name');
        let modal = cmp.find('modal');
        if(modal){
            modal.confirm('Are you sure to discontinue this intervention?','WARNING','ERROR').then(function(result){
                if(result){
                    helper.showSpinner(cmp);
                    helper.discontinueIntervention(cmp,interId).then(function(msg){
                        helper.hideSpinner(cmp);
                        if (msg){
                            helper.showToast({
                                type:"error",
                                message:msg,
                                duration: 10000
                            });
                        }else{
                            cmp.getEvent("refresh").setParams({ data:"reload"}).fire();
                        }
                    });
                }
            });
        }
    },
    onSaveClickHandler : function(cmp, event, helper) {
        let newIntervention = cmp.get('v.newIntervention');
        if(helper.validateNewInter(cmp,newIntervention)){
            helper.saveNewIntervention(cmp, newIntervention).then($A.getCallback(function(result){
                if(!result){
                    cmp.getEvent("refresh").setParams({ data:"reload"}).fire();
                    helper.showToast({
                        type:"success",
                        message:"Record Saved",
                        duration: 10000
                    });
                }else{
                    helper.showToast({
                        type:"error",
                        message:result,
                        duration: 10000
                    });
                }
            }));
        }else{
            helper.showToast({
                type:"error",
                message:'One or more fields are required',
                duration: 10000
            });
        }
    },
    onCloseClickHandler: function(cmp,e,h){
        let closeEvent = cmp.getEvent('closeModalEvent');
		closeEvent.setParams('data', cmp.get('v.instanceName'));
		closeEvent.fire();
    },
    onCloseModalHandler: function(cmp,e,h){
        cmp.set('v.showManageInterventionsModal', false);
    },
    onDiciplineChangeHandler: function(cmp,e,h){
        let dicipline = e.getSource().get('v.value');

        let interventions = (dicipline && cmp.get('v.diciplineInterverntions')[dicipline])? cmp.get('v.diciplineInterverntions')[dicipline] : [];

        cmp.set('v.interventions', interventions);
        cmp.set('v.newIntervention.description', '' );
    },
    onInterventionChangeHandler : function(cmp,e,h){
        let inter = e.getSource().get('v.value');
        let map = cmp.get('v.requiredDetailsInterventions');
        let required = inter? map[inter]==true: false;
        cmp.set('v.specifyInputRequired', required);
    },
})
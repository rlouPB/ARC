({
    openCreateMonitorFlow : function(cmp, event, helper) {
        cmp.set('v.showFlowModal', true);
        var flow = cmp.find("createMonitor");

        let inputParams = [
            {
                name : 'AccountId',
                type : 'String',
                value : cmp.get('v.theNote.patientNote.Account__c')
            }
        ];
        flow.startFlow("Create_Physical_Monitor", inputParams);
    },
    onCloseModalHandler: function(cmp, event, helper) {
        cmp.set('v.showFlowModal', false);
    }
})
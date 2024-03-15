({
    initialize: function(cmp, currentTab){
        cmp.set('v.todaysDate', $A.localizationService.formatDate(new Date(), "EEEE, MM/DD/YYYY") )
        cmp.set('v.currentTab',currentTab?  currentTab : "Shift Items")
        this.refreshSignedInData(cmp)
    },
    refreshSignedInData : function(cmp) {
        let action = cmp.get('c.getMyNursingShiftAssigments')
        action.setCallback(this,function(result){
            if(result.getState()=='SUCCESS'){
                let returnValue = result.getReturnValue()
                cmp.set('v.myAssignments', returnValue)
                console.info('**************** myAssignments ****************',JSON.parse(JSON.stringify(returnValue)))
                if( !(returnValue.length > 0) ){
                    cmp.set('v.currentTab','Shift Sign In/Out')
                }
            }
        })
        $A.enqueueAction(action)
    }
})
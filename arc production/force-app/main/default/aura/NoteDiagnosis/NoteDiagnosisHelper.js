({
    callApexMethod : function(component, methodName, params, successCallback, errorCallback) {
        console.log(component, methodName, params);
        let self = this;
        let action = component.get('c.'+methodName);
               
        if (params) {
            action.setParams(params);
        }
        
        action.setCallback(this, response=>{
            if (response.getState() ==  "SUCCESS") {
            	successCallback(response.getReturnValue());
            } else if (response.getState() == "ERROR") {
            	if (errorCallback) {
                	errorCallback(this.getErrorMessage(response.getError()), component);
                } else {
                    self.handleError(response.getError(), self);        
                }
            	console.log('callApexMethod - error', JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);
    }, 
    loadData : function(cmp, source) {
        let me = this;        
        let noteId = cmp.get('v.theNote.patientNote.Id');
        let status = cmp.get("v.theNote.patientNote.Status__c");        
        let params = { 
            admissionId: cmp.get('v.theNote.patientNote.Admission__c'), 
            source:source,
            patientNoteId:noteId           
        };
        
        console.info('NOTE DIAGNOSIS HELPER LOAD DATA ====>',{noteId,status,params, TheNote: cmp.get('v.theNote')});
        cmp.set('v.loading',true);
        cmp.set('v.readonly',status=='Finalized');
        me.callApexMethod( cmp, "getDiagnoses",params,function(result){
            console.info('NoteDiagnosis - loadData - result: ' + JSON.stringify(result));
            if(result.errorMessage){
                me.showToast({
                    type:'error',
                    message:result.errorMessage
                });
            }else{
                let principalsToDelete = result.principalsToDelete.map(item=>{
                    item.className = `${item.Marked_for_Delete__c?'mark':''} line hover`
                    return item
                });
                let comorbidDiagnoses =  me.mapComorbids(result.comorbids);
                cmp.set('v.principalDiagnosis', result.principal? result.principal : {});
                cmp.set('v.comorbidDiagnoses', comorbidDiagnoses );
                cmp.set('v.principalsToDelete', principalsToDelete );
                cmp.set('v.loaded',true);
            }
            cmp.set('v.loading',false);
        });
    },
    showToast: function(params) {
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent){
            toastEvent.setParams(params);
            toastEvent.fire();
        }else{
            alert(JSON.stringify(params));
        }
    },
    loadComorbids : function(cmp, source) {
        let me = this;
        let noteId = cmp.get('v.theNote.patientNote.Id');
        let params = { admissionId: cmp.get('v.theNote.patientNote.Admission__c'), source:  cmp.get('v.source'), patientNoteId:  noteId};
        me.callApexMethod( cmp, "getComorbids",params,function(result){
            let comorbidDiagnoses = me.mapComorbids(result).map(item=>{
                item.className = `${item.Marked_for_Delete__c?'mark':''} line hover`
                return item
            });
            cmp.set('v.comorbidDiagnoses', comorbidDiagnoses);
        });
    },
    loadPrincipalsDeleted: function( cmp, source){
        let me = this;
        let params = { admissionId: cmp.get('v.theNote.patientNote.Admission__c'), source:  cmp.get('v.source') };
        me.callApexMethod( cmp, "getPrincipalsMarkedForDelete",params,function(result){
            let principalsToDelete = me.mapComorbids(result).map(item=>{
                item.className = `${item.Marked_for_Delete__c?'mark':''} line hover`
                return item
            });
            cmp.set('v.principalsToDelete', principalsToDelete);
        });
    },
    mapComorbids: function(comorbids){
        return ( comorbids || [] ).map(function(x){
            if( x.Clinical_Code__r ){
                x.Clinical_Code__Description__c = x.Clinical_Code__r.Description__c;
                x.Clinical_Code__Name = x.Clinical_Code__r.Name;
            }
            x.className = `${x.Marked_for_Delete__c?'mark':''} line hover`;            
            return x;
        });       
    },
    markForDelete : function(cmp, diagnosisId, markForDelete) {
        let me = this;
        let params = { diagnosisId, value:markForDelete };
        cmp.set('v.loading',true);
        me.callApexMethod( cmp, "MarkForDelete",params,function(result){
            if(result.errorMessage){
                me.showToast({
                    type:'error',
                    message:result.errorMessage
                });
            }else{
                me.loadComorbids(cmp);
            }
            cmp.set('v.loading',false);
        });
    }
})
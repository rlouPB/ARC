({
	apex:function(cmp,actionName,params){
        let me = this;
        return new Promise($A.getCallback(function(resolve,reject){            
            let action = cmp.get(actionName);
            if(params){
                action.setParams(params);
            }
            action.setCallback(me, function(resp){
                if (resp.getState() == 'SUCCESS'){
                    resolve(resp.getReturnValue());
                }else{                    
                    let msg = "Unhandled error occurred";
                    console.debug(msg + ' ====> ', resp.getError());
                    reject(msg);
                }
            });
            $A.enqueueAction(action);
        }));
    },
    
    reload: function (cmp){
        let me = this;
        return new Promise(function(resolve){
            let params = {
                record_id: cmp.get("v.recordId"), 
                fields: cmp.get("v.selectFields"), 
                with_sharing: cmp.get("v.withSharing") == true
            };
            me.apex(cmp,"c.GetRecordData",params).then(function(results){
                if(results.error){
                    cmp.set('v.error', results.error);                    
                }else{                
                    cmp.set('v.target', results.data);
                    resolve(results.data);
                }
            });
        });
    }
})
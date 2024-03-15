({
    doInit : function(cmp, event, h) {
        let source = cmp.get('v.source');        
        h.loadData(cmp, source);
    },
    loadComorbids: function(cmp, admissionId, source){

    },
    onMarkForRemoval: function(cmp,e,h){
        let comorbidId = e.getSource().get('v.name');
        h.markForDelete(cmp, comorbidId, true);
    },
    onUnmarkForRemoval: function(cmp,e,h){
        let comorbidId = e.getSource().get('v.name');
        h.markForDelete(cmp, comorbidId, false);
    },
    onSaveNoteDiagnosis:function(cmp,e,h){        
        let params = e.getParams();
        if( params.data ){
            h.loadComorbids(cmp);
            h.loadPrincipalsDeleted(cmp);
        }
    },
})
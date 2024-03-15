({
	onInitHandler : function(cmp, e, h) {
        h.reload(cmp);
	},
    onRefreshHandler: function(cmp, e, h){
        if(cmp.get('v.autoRefresh') == true){
            h.reload(cmp);
        }
    },
    getRecordHandler: function(cmp, e, h){
        return new Promise(function(resolve){            
			let args = e.getParam('arguments');
			
            if( args.reload ){
                h.reload(cmp).then(function(){
                   resolve( cmp.get('v.target') ); 
                });
            }else{
                resolve( cmp.get('v.target') ); 
            }
        });
    }
})
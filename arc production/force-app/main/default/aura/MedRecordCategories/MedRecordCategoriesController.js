({
    onCategorySelected : function(cmp,e,h) {
        let categoryId = e.getParams().categoryId;
        let flow = cmp.find('flow');        
        alert(JSON.stringify(e.getParams()));
        let flowName = cmp.get('v.flowName');
        let inputParams = cmp.get('v.inputParams') || [];
        if( flowName ){
            flow.startFlow(flowName, inputParams);
        }
    }
})